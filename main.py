import requests
import json

# Load dataset
with open("dataset_adjusted.json") as f:
    crops_data = json.load(f)

# Your OpenWeatherMap API key
api_key = "8eb898d0791bcfbcdc92ef8aac59c52d"  

# district name
district = input("Enter district name: ")

# current weather data
url = f"http://api.openweathermap.org/data/2.5/weather?q={district},IN&appid={api_key}&units=metric"
response = requests.get(url)
data = response.json()

if response.status_code == 200:
    temperature = data['main']['temp']
    humidity = data['main']['humidity']
    rainfall = data.get('rain', {}).get('1h', 0)  # mm rainfall last 1 hour, default 0

    # Simple soil level logic based on rainfall
    if rainfall > 10:
        soil_level = "Wet"
    elif 3 < rainfall <= 10:
        soil_level = "Moist"
    elif 1 < rainfall <= 3:
        soil_level = "Moderate"
    else:
        soil_level = "Dry"

    # Filter crops
    recommended = [
        crop["Crop"] for crop in crops_data
        if crop["Temp Min"] <= temperature <= crop["Temp Max"]
        and crop["Humid Min"] <= humidity <= crop["Humid Max"]
        and crop["Soil Level Needed"] == soil_level
    ]

    print(f"\nWeather in {district}:")
    print(f"Temperature: {temperature}°C")
    print(f"Humidity: {humidity}%")
    print(f"Rainfall: {rainfall} mm")
    print(f"Soil Level: {soil_level}")

    if recommended:
        print("\nRecommended Crops:", ", ".join(recommended[:3]))
    else:
        print("\nNo crops match the current conditions.")
else:
    print("Error fetching weather data:", data.get("message", "Unknown error"))
