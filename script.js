document.addEventListener('DOMContentLoaded', () => {
    const getRecommendationBtn = document.getElementById('get-recommendation');
    const districtInput = document.getElementById('district');
    const languageSelect = document.getElementById('language');
    const resultDiv = document.getElementById('result');
    const recommendationPara = document.getElementById('recommendation');

    // Keys come from config.js (gitignored). See config.example.js.
    const config = window.APP_CONFIG || {};
    const weatherApiKey = config.WEATHER_API_KEY;
    const geminiApiKey = config.GEMINI_API_KEY;

    if (!weatherApiKey || !geminiApiKey) {
        alert('Missing API keys. Copy config.example.js to config.js and add your keys.');
        return;
    }

    getRecommendationBtn.addEventListener('click', async () => {
        const district = districtInput.value.trim();
        const lang = languageSelect.value;

        if (!district) {
            alert('Please enter a district name.');
            return;
        }

        try {
            // 1. Get Weather Data
            const weatherUrl = `https://api.openweathermap.org/data/2.5/weather?q=${district},IN&appid=${weatherApiKey}&units=metric`;
            const weatherResponse = await fetch(weatherUrl);
            if (!weatherResponse.ok) {
                throw new Error('Could not fetch weather data. Check the district name.');
            }
            const weatherData = await weatherResponse.json();
            const temp = weatherData.main.temp;
            const humidity = weatherData.main.humidity;
            const rainfall = weatherData.rain ? weatherData.rain['1h'] || 0 : 0;

            // 2. Get Crop Recommendation from Gemini
            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;
            const prompt = `
            Given the weather conditions:
            - Temperature: ${temp}°C
            - Humidity: ${humidity}%
            - Rainfall: ${rainfall} mm

            Recommend 3 suitable crops for cultivation in Indian conditions.
            Output format: Just the crop names separated by commas, no explanation.
            `;

            const geminiResponse = await fetch(geminiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
            });

            if (!geminiResponse.ok) {
                throw new Error('Could not fetch crop recommendations.');
            }

            const geminiData = await geminiResponse.json();
            const englishOutput = geminiData.candidates[0].content.parts[0].text.trim();

            // 3. Translate if necessary
            let translatedOutput = englishOutput;
            if (lang !== 'en') {
                // Note: This is a simplified translation approach. 
                // A robust solution would use a dedicated translation API on a backend.
                const translationUrl = `https://api.mymemory.translated.net/get?q=${encodeURIComponent(englishOutput)}&langpair=en|${lang}`;
                const translationResponse = await fetch(translationUrl);
                const translationData = await translationResponse.json();
                translatedOutput = translationData.responseData.translatedText;
            }

            // 4. Display Result
            recommendationPara.textContent = translatedOutput;
            resultDiv.style.display = 'block';

        } catch (error) {
            alert(`An error occurred: ${error.message}`);
        }
    });
});
