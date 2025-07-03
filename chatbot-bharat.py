import os
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_google_genai import ChatGoogleGenerativeAI


os.environ["GOOGLE_API_KEY"] = "xxxxx"


eco_prompt = ChatPromptTemplate.from_messages([
    ("system", "You are EcoBot, a helpful assistant for Indian environmental and constitutional law queries."),
    ("human", "{input}")
])


llm = ChatGoogleGenerativeAI(
    model="models/gemini-1.5-flash",
    google_api_key="xxxxx"
)


chain = eco_prompt | llm | StrOutputParser()


def get_answer(query):
    try:
        result = chain.invoke({"input": query}) 
        return result
    except Exception as e:
        print("❌ Error:", e)
        return "Sorry, I couldn’t find a valid answer."

print(get_answer("What is Article 48A of the Indian Constitution?"))
print(get_answer("Is it related to forest protection?"))
