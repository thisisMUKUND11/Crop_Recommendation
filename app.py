from flask import Flask, request, jsonify, send_from_directory
import requests
import json

app = Flask(__name__)

# Load dataset
with open("dataset_adjusted.json") as f:
    crops_data = json.load(f)

# Your OpenWeatherMap API key
api_key = "8eb898d0791bcfbcdc92ef8aac59c52d"

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/<path:path>')
def static_files(path):
    return send_from_directory('.', path)

@app.route('/recommend', methods=['POST'])
def recommend():
    data = request.get_json()
    district = data.get('district')

    if not district:
        return jsonify({'error': 'District is required'}), 400

    # Get current weather data
    url = f"http://api.openweathermap.org/data/2.5/weather?q={district},IN&appid={api_key}&units=metric"
    response = requests.get(url)
    weather_data = response.json()

    if response.status_code == 200:
        temperature = weather_data['main']['temp']
        humidity = weather_data['main']['humidity']
        rainfall = weather_data.get('rain', {}).get('1h', 0)  # mm rainfall last 1 hour, default 0

        # Simple soil level logic based on rainfall
        if rainfall > 10:
            soil_level = "Wet"
        elif 3 < rainfall <= 10:
            soil_level = "Moist"
        elif 1 < rainfall <= 3:
            soil_level = "Moderate"
        else:
            soil_level = "Dry"

        # Filter crops based on dataset
        recommended = [
            crop["Crop"] for crop in crops_data
            if crop["Temp Min"] <= temperature <= crop["Temp Max"]
            and crop["Humid Min"] <= humidity <= crop["Humid Max"]
            and crop["Soil Level Needed"] == soil_level
        ]

        return jsonify({
            'weather': {
                'temperature': temperature,
                'humidity': humidity,
                'rainfall': rainfall,
                'soil_level': soil_level
            },
            'recommended_crops': recommended[:3]
        })
    else:
        return jsonify({'error': f"Error fetching weather data: {weather_data.get('message', 'Unknown error')}"}), 500

if __name__ == '__main__':
    app.run(debug=True)
