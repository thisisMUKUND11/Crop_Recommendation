import requests
import google.generativeai as genai
from deep_translator import GoogleTranslator

# ========== CONFIG ==========
weather_api_key = "8eb898d0791bcfbcdc92ef8aac59c52d"   # Replace with your OpenWeatherMap API key
gemini_api_key = "AIzaSyCvGuEhPTOrNT7vrx5uvNGWGH0AJgaTjg0"     # Replace with your Gemini API key
genai.configure(api_key=gemini_api_key)

# Language codes (ISO format for Indian languages)
language_map = {
    "hindi": "hi",
    "tamil": "ta",
    "telugu": "te",
    "kannada": "kn",
    "malayalam": "ml",
    "bengali": "bn",
    "marathi": "mr",
    "gujarati": "gu",
    "punjabi": "pa",
    "english": "en"
}

# ========== USER INPUT ==========
district = input("Enter district name: ")
user_lang = input("Enter preferred language (hindi, tamil, telugu, kannada, malayalam, bengali, marathi, gujarati, punjabi, english): ").lower()

if user_lang not in language_map:
    print("❌ Language not supported, defaulting to English.")
    user_lang = "english"

# ========== WEATHER API CALL ==========
url = f"http://api.openweathermap.org/data/2.5/weather?q={district},IN&appid={weather_api_key}&units=metric"
response = requests.get(url)

if response.status_code == 200:
    weather_data = response.json()
    temp = weather_data['main']['temp']
    humidity = weather_data['main']['humidity']
    rainfall = weather_data.get('rain', {}).get('1h', 0)

    # ========== GEMINI API CALL ==========
    model = genai.GenerativeModel("gemini-1.5-flash")

    prompt = f"""
    Given the weather conditions:
    - Temperature: {temp}°C
    - Humidity: {humidity}%
    - Rainfall: {rainfall} mm

    Recommend 3 suitable crops for cultivation in Indian conditions.
    Output format: Just the crop names separated by commas, no explanation.
    """
    gemini_response = model.generate_content(prompt)
    english_output = gemini_response.text.strip()

    print("\n🌱 Recommended Crops (English):\n", english_output)

    # ========== TRANSLATE OUTPUT ==========
    translated = GoogleTranslator(source='auto', target=language_map[user_lang]).translate(english_output)

    print(f"\n🌐 Translated Output ({user_lang.capitalize()}):\n", translated)

else:
    print(f"❌ Error {response.status_code}: Unable to fetch weather data. Check district name or API key.")
