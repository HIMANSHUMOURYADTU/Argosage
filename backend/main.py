import os
import io
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from datetime import datetime
from PIL import Image

# --- IMPORTS FOR ALL AI FEATURES ---
import torch
from transformers import BlipProcessor, BlipForConditionalGeneration
import google.generativeai as genai
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.schema.runnable import RunnableMap, RunnablePassthrough

# --- LOAD ENVIRONMENT & CONFIGURE ---
load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
if not API_KEY:
    raise ValueError("Google API Key not found. Please set it in the .env file.")
genai.configure(api_key=API_KEY)
app = FastAPI()

# --- CORS MIDDLEWARE ---
origins = ["*"]
app.add_middleware(CORSMiddleware, allow_origins=origins, allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

# --- IN-MEMORY DATABASE ---
fake_db = {
    "plots": {"plot_a": {"name": "North Field", "crop": "Tomatoes", "logs": []}, "plot_b": {"name": "West Patch", "crop": "Corn", "logs": []}},
    "missions": [{"id": "m1", "title": "Start a Compost Pile", "reward": 20, "completed": False}, {"id": "m2", "title": "Apply Neem Oil", "reward": 30, "completed": False}, {"id": "m3", "title": "Install Drip Irrigation", "reward": 50, "completed": False}, {"id": "m4", "title": "Crop Rotation Plan", "reward": 25, "completed": True}],
    "carbon_ledger": [{"timestamp": "2024-03-10T10:00:00Z", "activity": "Completed Mission: Crop Rotation Plan", "credits": 25}],
    "sustainability_score": 35,
    "weather_forecast": {"condition": "High Humidity", "temperature_celsius": 28, "chance_of_rain_percent": 80}
}


# ==============================================================================
# --- AI MODEL INITIALIZATION (Happens once on startup) ---
# ==============================================================================
print("Loading all AI models... This may take a moment on the first run.")

# --- Models for AgroSage Features (Pest Scan, EcoBot) ---
llm_chat = ChatGoogleGenerativeAI(model="gemini-1.5-flash", google_api_key=API_KEY)
llm_vision_pest = genai.GenerativeModel('gemini-1.5-flash')

eco_prompt_chat = ChatPromptTemplate.from_messages([
    ("system", "You are EcoBot, a helpful assistant for Indian sustainable farming. Provide concise, actionable advice."),
    ("human", "{input}")
])
chatbot_chain = eco_prompt_chat | llm_chat | StrOutputParser()


# --- Models for Waste Classification Feature ---
# This will download the model from Hugging Face the first time you run the server.
caption_processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
caption_model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")

# LangChain setup for waste classification
prompt_classify_waste = ChatPromptTemplate.from_template("Analyze: '{caption}'. Classify the waste type (Biodegradable, Non-biodegradable, Recyclable, Medical, Electronic). Respond with only the lowercase waste type.")
prompt_bin = ChatPromptTemplate.from_template("Item: '{caption}'. Based on Indian norms, what dustbin color? (green, blue, red, yellow, black, or special sanitary rule). Respond with only the color/rule.")
prompt_explain = ChatPromptTemplate.from_template("Explain in one line why an item described as '{caption}' should go into its designated bin color (Green: Wet, Blue: Dry, Red/Yellow: Medical, Black: E-waste).")

chain_classify_waste = prompt_classify_waste | llm_chat | StrOutputParser()
chain_bin = prompt_bin | llm_chat | StrOutputParser()
chain_explain = prompt_explain | llm_chat | StrOutputParser()
print("All AI models loaded successfully.")
# ==============================================================================


# --- PYDANTIC MODELS (Data Structure Definitions) ---
class ChatQuery(BaseModel): query: str
class PlotLog(BaseModel): plot_id: str; soil_moisture: float; pest_sighting: str | None = None
class WasteClassificationResponse(BaseModel): caption: str; category: str; bin_color: str; explanation: str


# ==============================================================================
# --- API ENDPOINTS ---
# ==============================================================================

@app.get("/")
def read_root(): return {"message": "AgroSage Super-App API is Live"}

# --- NEW ENDPOINT for Waste Scanner ---
@app.post("/classify-waste", response_model=WasteClassificationResponse)
async def classify_waste(file: UploadFile = File(...)):
    """Takes an image, generates a caption, and classifies the waste."""
    try:
        contents = await file.read()
        # Use a copy of the bytes for the image to avoid issues with file pointers
        image = Image.open(io.BytesIO(contents)).convert("RGB")

        # 1. Generate Caption using local BLIP model
        inputs = caption_processor(image, return_tensors="pt")
        out = caption_model.generate(**inputs, max_new_tokens=50)
        caption = caption_processor.decode(out[0], skip_special_tokens=True).strip()

        # 2. Use LangChain and Gemini to get structured data
        category = chain_classify_waste.invoke({"caption": caption}).strip()
        bin_color = chain_bin.invoke({"caption": caption}).strip()
        explanation = chain_explain.invoke({"caption": caption}).strip()

        return WasteClassificationResponse(
            caption=caption,
            category=category,
            bin_color=bin_color,
            explanation=explanation
        )
    except Exception as e:
        print(f"Error during waste classification: {e}")
        raise HTTPException(status_code=500, detail=f"Error during waste classification: {e}")

# --- Existing AgroSage Endpoints ---
@app.post("/scan-pest")
async def scan_pest(file: UploadFile = File(...)):
    contents = await file.read()
    image = Image.open(io.BytesIO(contents)).convert("RGB")
    prompt = "Analyze this plant leaf. 1. Identify pest/disease. If healthy, say so. 2. Provide a brief, organic solution. Format: 'Diagnosis: [Your Diagnosis].\nSolution: [Your Solution].'"
    try:
        response = llm_vision_pest.generate_content([prompt, image])
        return {"result": response.text}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/dashboard-data")
def get_dashboard_data():
    return {
        "sustainability_score": fake_db["sustainability_score"],
        "active_missions": len([m for m in fake_db["missions"] if not m["completed"]]),
        "carbon_credits": sum(entry['credits'] for entry in fake_db['carbon_ledger']),
        "recommendations": generate_recommendations()
    }

@app.get("/missions")
def get_missions(): return fake_db["missions"]

@app.post("/ask-ecobot")
async def ask_bot(request: ChatQuery):
    try:
        answer = chatbot_chain.invoke({"input": request.query})
        return {"response": answer}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing query: {e}")

@app.post("/complete-mission/{mission_id}")
def complete_mission(mission_id: str):
    mission = next((m for m in fake_db["missions"] if m["id"] == mission_id), None)
    if not mission or mission["completed"]:
        raise HTTPException(status_code=404, detail="Mission not found or already completed")
    mission["completed"] = True
    entry = {"timestamp": datetime.now().isoformat(), "activity": f"Completed Mission: {mission['title']}", "credits": mission['reward']}
    fake_db["carbon_ledger"].append(entry)
    fake_db["sustainability_score"] += mission['reward']
    return {"message": "Mission completed!", "entry": entry}

@app.post("/log-plot-data")
async def log_plot_data(log: PlotLog):
    if log.plot_id not in fake_db["plots"]:
        raise HTTPException(status_code=404, detail="Plot not found")
    timestamped_log = log.model_dump()
    timestamped_log["timestamp"] = datetime.now().isoformat()
    fake_db["plots"][log.plot_id]["logs"].append(timestamped_log)
    return {"message": "Log received successfully, AI will now generate new recommendations."}


# ==============================================================================
# --- AI RECOMMENDATION ENGINE (for AgroSage Dashboard) ---
# ==============================================================================
def generate_recommendations():
    recommendations = []
    weather = fake_db["weather_forecast"]
    if weather["chance_of_rain_percent"] > 70:
        recommendations.append({"id": "weather_rain_alert", "title": "Heavy Rain Forecasted", "details": "Consider delaying irrigation to conserve water."})
    elif weather["condition"] == "High Humidity":
        recommendations.append({"id": "weather_humidity_alert", "title": "High Humidity Alert", "details": "Risk of fungal diseases. Ensure good air circulation."})
    for plot_id, plot_data in fake_db["plots"].items():
        if plot_data["crop"] == "Tomatoes" and weather["condition"] == "High Humidity":
            recommendations.append({"id": f"{plot_id}_tomato_blight_risk", "title": f"Blight Risk for Tomatoes", "details": f"The high humidity puts your Tomatoes in {plot_data['name']} at high risk for Early Blight."})
    unique_recs = {rec['title']: rec for rec in recommendations}.values()
    return list(unique_recs)[:4]