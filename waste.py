import os
from PIL import Image
import torch
from dotenv import load_dotenv
from transformers import BlipProcessor, BlipForConditionalGeneration
from langchain_core.prompts import PromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.schema.runnable import RunnableMap, RunnablePassthrough
from getpass import getpass

import json

load_dotenv()
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")



llm = ChatGoogleGenerativeAI(model="models/gemini-1.5-flash", google_api_key=GOOGLE_API_KEY, temperature=0)

def generate_caption(image_path):
    processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
    model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")
    image = Image.open(image_path).convert("RGB")
    inputs = processor(image, return_tensors="pt")
    out = model.generate(**inputs)
    caption = processor.decode(out[0], skip_special_tokens=True)
    return caption


prompt_classify = PromptTemplate.from_template("""
You are an intelligent waste classification assistant.

Your task is to analyze the following description of an item: "{caption}"

Based on this description, determine the correct **type of waste** the item belongs to. Choose exactly one of the following categories:

- Biodegradable: Naturally decomposes (e.g., food waste, plant material)
- Non-biodegradable: Does not decompose easily (e.g., plastic wrappers, glass)
- Recyclable: Can be processed and reused (e.g., clean plastic bottles, cardboard, metal cans)
- Medical: Related to healthcare or personal hygiene (e.g., syringes, bandages, sanitary pads)
- Electronic: Devices or components using electricity or batteries (e.g., phones, chargers, batteries)

Respond only with the **waste type** name in lowercase.
Example responses:
- biodegradable
- recyclable
- electronic

Now classify this item.
""")



prompt_explain=PromptTemplate.from_template(

    """
    You are an intelligent waste classification assistant.

Your task is to tell why this waste should go in this category of dustbin color: "{caption}"
. Dustbin Color (based on Indian norms):
   - Green: Wet waste (biodegradable like food, leaves)
   - Blue: Dry waste (recyclable like plastic, paper, metal)
   - Red: BioMedical Waste like plastic having blood or infectious things
   - Yellow: Biomedical waste like syringed gloves etc
   - Black: E-waste

   If it is a sanitary waste like sanitary napkins, tampons, diapers (both adult and baby), and condoms.
   then  Red bin (preferred) or Blue bin (if red not available,must be securely wrapped before disposal)

   You just need to give 1 liner explaintion to why this waste should go in this color of dustbin


    """
)


prompt_bin = PromptTemplate.from_template(
    """
You are an intelligent waste classification assistant.

Given this item description: "{caption}", respond with **only** the appropriate dustbin color based on Indian waste management norms.

Allowed outputs:
- green
- blue
- red
- yellow
- black
- For sanitary waste (sanitary napkins, tampons, diapers, condoms): return exactly this → red (preferred), or blue if red is not available (must be securely wrapped)

Do not include any explanation or extra words. Only respond with the correct option from above.
"""
)


chain_classify = (
    RunnableMap({"caption": RunnablePassthrough()})
    | prompt_classify
    | llm
    | StrOutputParser()
)

chain_bin = (
    RunnableMap({"caption": RunnablePassthrough()})
    | prompt_bin
    | llm
    | StrOutputParser()
)

chain_explain = (
    RunnableMap({"caption": RunnablePassthrough()})
    | prompt_explain
    | llm
    | StrOutputParser()
)
def classify_image(image_path):

    caption = generate_caption(image_path)





    return(caption)

def classify_waste(image_path):

    caption = generate_caption(image_path)



    result=chain_classify.invoke(caption)

    return(result)

def classify_bin(image_path):

    caption = generate_caption(image_path)



    result = chain_classify.invoke(caption)

    return(result)

def classify_explain(image_path):

    caption = generate_caption(image_path)



    result = chain_classify.invoke(caption)

    return(result)







def answer_dict(image_path):
    caption = generate_caption(image_path)


    category = chain_classify.invoke(caption).strip()
    bin_color = chain_bin.invoke(caption).strip()
    explanation = chain_explain.invoke(caption).strip()

    return {
        "caption": caption,
        "category": category,
        "bin": bin_color,
        "explain": explanation
    }

def answer_json(image_path):
    result = answer_dict(image_path)
    return json.dumps(result, indent=4)

#######
####BELOW ARE EXAMPLES#####3
img="dropped-iphone-pretty-hard-v0-lhdszpzslq2d1.jpeg.webp"
print(answer_dict(img))
#########