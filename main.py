"""Crop recommendation CLI.

Fetches current weather for a district from OpenWeatherMap, asks Gemini for
suitable crops, and (optionally) translates the result into an Indian language.

API keys are read from environment variables so they are never committed to
source control:

    export WEATHER_API_KEY=your_openweathermap_key
    export GEMINI_API_KEY=your_gemini_key

On Windows PowerShell:

    $env:WEATHER_API_KEY = "your_openweathermap_key"
    $env:GEMINI_API_KEY  = "your_gemini_key"

See .env.example for the full list of variables.
"""

import os
import sys

import requests
import google.generativeai as genai
from deep_translator import GoogleTranslator

# Language codes (ISO format for Indian languages)
LANGUAGE_MAP = {
    "hindi": "hi",
    "tamil": "ta",
    "telugu": "te",
    "kannada": "kn",
    "malayalam": "ml",
    "bengali": "bn",
    "marathi": "mr",
    "gujarati": "gu",
    "punjabi": "pa",
    "english": "en",
}

WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"


def get_config():
    """Read required API keys from the environment, exiting if any are missing."""
    weather_api_key = os.getenv("WEATHER_API_KEY")
    gemini_api_key = os.getenv("GEMINI_API_KEY")

    missing = [
        name
        for name, value in (
            ("WEATHER_API_KEY", weather_api_key),
            ("GEMINI_API_KEY", gemini_api_key),
        )
        if not value
    ]
    if missing:
        sys.exit(
            "Missing required environment variable(s): "
            + ", ".join(missing)
            + ".\nSee .env.example and set them before running."
        )
    return weather_api_key, gemini_api_key


def fetch_weather(district, weather_api_key):
    """Return (temp, humidity, rainfall) for a district, or raise on failure."""
    response = requests.get(
        WEATHER_URL,
        params={"q": f"{district},IN", "appid": weather_api_key, "units": "metric"},
        timeout=10,
    )
    response.raise_for_status()
    data = response.json()
    return (
        data["main"]["temp"],
        data["main"]["humidity"],
        data.get("rain", {}).get("1h", 0),
    )


def recommend_crops(temp, humidity, rainfall, gemini_api_key):
    """Ask Gemini for 3 suitable crops given the weather conditions."""
    genai.configure(api_key=gemini_api_key)
    model = genai.GenerativeModel("gemini-1.5-flash")
    prompt = (
        "Given the weather conditions:\n"
        f"- Temperature: {temp}°C\n"
        f"- Humidity: {humidity}%\n"
        f"- Rainfall: {rainfall} mm\n\n"
        "Recommend 3 suitable crops for cultivation in Indian conditions.\n"
        "Output format: Just the crop names separated by commas, no explanation."
    )
    return model.generate_content(prompt).text.strip()


def main():
    weather_api_key, gemini_api_key = get_config()

    district = input("Enter district name: ").strip()
    user_lang = input(
        "Enter preferred language "
        f"({', '.join(LANGUAGE_MAP)}): "
    ).strip().lower()

    if user_lang not in LANGUAGE_MAP:
        print("Language not supported, defaulting to English.")
        user_lang = "english"

    try:
        temp, humidity, rainfall = fetch_weather(district, weather_api_key)
    except requests.RequestException as exc:
        sys.exit(f"Unable to fetch weather data: {exc}")

    english_output = recommend_crops(temp, humidity, rainfall, gemini_api_key)
    print("\nRecommended Crops (English):\n", english_output)

    if user_lang != "english":
        translated = GoogleTranslator(
            source="auto", target=LANGUAGE_MAP[user_lang]
        ).translate(english_output)
        print(f"\nTranslated Output ({user_lang.capitalize()}):\n", translated)


if __name__ == "__main__":
    main()
