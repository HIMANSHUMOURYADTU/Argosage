import streamlit as st
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime
from geopy.geocoders import Nominatim

st.set_page_config(layout="wide", page_title="Smart Indian Farmer Carbon Calculator")
st.title("🇮🇳 Smart Carbon Footprint Calculator for Indian Farmers")

crop_emission_factors = {
    "Rice": 2.7,
    "Wheat": 1.4,
    "Sugarcane": 1.6,
    "Maize": 1.2,
    "Pulses": 0.8,
    "Cotton": 1.9,
    "Oilseeds": 1.1,
    "Vegetables": 0.9,
    "Fruits": 0.7,
    "Other": 1.0
}

fertilizer_factors = {
    "Urea": 1.59,
    "DAP": 1.5,
    "Potash": 0.5,
    "Organic Compost": 0.2
}

pesticide_factors = {
    "Chemical": 5.0,
    "Organic": 1.5
}

tractor_factor = 2.5  # kg CO2/hour
irrigation_factors = {
    "Rainfed": 0,
    "Electric Pump": 0.5,
    "Diesel Pump": 1.5,
    "Solar Pump": 0.1
}

st.subheader("🧮 Enter your farming details")

col1, col2 = st.columns(2)

with col1:
    crop_type = st.selectbox("🌾 Select Crop Type", list(crop_emission_factors.keys()))
    area = st.number_input("📏 Area under cultivation (hectares)", 0.0, 500.0)
    soil_type = st.selectbox("🧱 Soil Type", ["Sandy", "Loamy", "Clay", "Black Soil", "Laterite"])
    crop_yield = st.number_input("🌾 Average Yield (tonnes/hectare)", 0.0, 20.0)
    fertilizer_type = st.selectbox("🧪 Fertilizer Type", list(fertilizer_factors.keys()))
    fertilizer_kg = st.number_input("🧪 Fertilizer used (kg/year)", 0.0, 5000.0)
    pesticide_type = st.selectbox("🐞 Pesticide/Insecticide Type", list(pesticide_factors.keys()))
    pesticide_l = st.number_input("🐞 Pesticide/Insecticide used (litres/year)", 0.0, 500.0)

with col2:
    irrigation_type = st.selectbox("💧 Irrigation Source", list(irrigation_factors.keys()))
    irrigation_hours = st.slider("💧 Irrigation hours per year", 0, 2000)
    tractor_hours = st.slider("🚜 Tractor usage per year (hours)", 0, 1000)
    number_of_crops = st.number_input("🌿 Number of crop cycles per year", 1, 4)
    renewable_energy = st.radio("🔋 Are you using solar/wind power on your farm?", ["Yes", "No"])
    cover_crop = st.radio("🌱 Do you use cover cropping/green manure?", ["Yes", "No"])

# Geolocation
with st.expander("📍 Detect Your Location (for scheme suggestions)"):
    state = st.text_input("Enter your village/town/city")
    if st.button("Detect State"):
        try:
            geolocator = Nominatim(user_agent="geoapi")
            location = geolocator.geocode(state)
            if location:
                st.success(f"Detected Location: {location.address}")
            else:
                st.error("Could not detect location.")
        except:
            st.error("Geolocation service error.")

crop_emission = crop_emission_factors[crop_type] * area * number_of_crops
fertilizer_emission = (fertilizer_kg * fertilizer_factors[fertilizer_type]) / 1000
pesticide_emission = (pesticide_l * pesticide_factors[pesticide_type]) / 1000
tractor_emission = (tractor_hours * tractor_factor) / 1000
irrigation_emission = (irrigation_factors[irrigation_type] * irrigation_hours * area) / 1000

renewable_reduction = 0.1 if renewable_energy == "Yes" else 0.0
cover_crop_reduction = 0.05 if cover_crop == "Yes" else 0.0

adjusted_crop_emission = crop_emission * (1 - cover_crop_reduction)
adjusted_irrigation_emission = irrigation_emission * (1 - renewable_reduction)


category_emissions = {
    "Crop Cultivation": round(adjusted_crop_emission, 2),
    "Fertilizers": round(fertilizer_emission, 2),
    "Pesticides": round(pesticide_emission, 2),
    "Machinery Use": round(tractor_emission, 2),
    "Irrigation": round(adjusted_irrigation_emission, 2)
}

total_emissions = round(sum(category_emissions.values()), 2)

if st.button("Calculate Emissions"):
    col3, col4 = st.columns(2)

    with col3:
        st.subheader("📊 Emission Breakdown (tonnes CO2/year)")
        for k, v in category_emissions.items():
            st.info(f"{k}: {v} tonnes")

    with col4:
        st.subheader("🌍 Total Farm Carbon Footprint")
        st.success(f"Your total emissions: {total_emissions} tonnes CO2/year")

        st.subheader("🧠 Smart Recommendations")
        if soil_type == "Black Soil" and crop_type == "Sugarcane":
            st.info("Since you are using Black Soil for Sugarcane, switching to organic compost can reduce emissions by ~30%.")
        if adjusted_crop_emission > 2:
            st.warning("🌾 Rotate with nitrogen-fixing crops like pulses or apply cover cropping.")
        if fertilizer_emission > 0.5:
            st.warning("🧪 Use precision farming or switch to bio-fertilizers.")
        if irrigation_emission > 0.5:
            st.warning("💧 Switch to drip/micro irrigation and solar pumping.")
        if pesticide_emission > 0.3:
            st.warning("🐞 Use biopesticides or integrated pest management (IPM).")

        
        if total_emissions / area > 4:
            st.error("⚠️ High emitter: Immediate action recommended.")
        elif total_emissions / area > 2:
            st.warning("⚠️ Medium emitter: Optimize practices.")
        else:
            st.success("✅ Low emitter: Keep up the good practices!")

        
        st.subheader("🎯 Suggested Government Schemes")
        st.markdown("- **PM-KUSUM**: Solar pump subsidy")
        st.markdown("- **Soil Health Card Yojana**: Free soil testing")
        st.markdown("- **Paramparagat Krishi Vikas Yojana**: Organic farming support")

        
        st.metric("📉 National Avg (India)", "2.2 tCO2/ha/year")
        st.metric("📈 Your Rate", f"{total_emissions / area:.2f} tCO2/ha/year")

    
    st.subheader("📉 Emissions Distribution")
    fig, ax = plt.subplots(figsize=(7,7))
    ax.pie(category_emissions.values(), labels=category_emissions.keys(), autopct='%1.1f%%', startangle=90)
    ax.axis('equal')
    st.pyplot(fig)
    st.subheader("📉 Emissions Distribution")
    fig, ax = plt.subplots()
    wedges, texts, autotexts = ax.pie(
        category_emissions.values(),
        labels=category_emissions.keys(),
        autopct='%1.1f%%',
        startangle=140,
        pctdistance=0.85
    )
    centre_circle = plt.Circle((0,0),0.70,fc='white')
    fig.gca().add_artist(centre_circle)
    ax.axis('equal')
    plt.tight_layout()
    st.pyplot(fig)

    st.subheader("📈 Emissions Bar Chart")
    bar_df = pd.DataFrame(category_emissions.items(), columns=["Category", "Emissions"])
    fig_bar, ax_bar = plt.subplots()
    sns.barplot(data=bar_df, x="Emissions", y="Category", palette="YlGnBu", ax=ax_bar)
    ax_bar.set_xlabel("Tonnes CO2/year")
    ax_bar.set_title("Category-wise Carbon Emissions")
    st.pyplot(fig_bar)


    df_out = pd.DataFrame(list(category_emissions.items()), columns=["Category", "Emissions (tonnes)"])
    st.download_button("📥 Download Report as CSV", df_out.to_csv(index=False), "farmer_emissions.csv", "text/csv")

    st.subheader("🏆 Your Rank in Sustainable Farming")
    st.success("You are in the top 20% low-carbon farmers in your district!")
    st.caption("(based on mock data; real ranking requires verified carbon registry)")

    current_month = datetime.now().month
    if current_month in [6, 7, 8]:
        st.info("🌧️ Kharif Season: High emissions likely due to rice cultivation. Consider alternate wetting/drying irrigation.")
    elif current_month in [10, 11, 12]:
        st.info("🍂 Rabi Season: Emissions lower; good time to introduce legumes for nitrogen fixation.")
    else:
        st.info("🌱 Zaid Season: Opportunity to grow cover crops and rejuvenate soil.")
