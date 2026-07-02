# HARVEST-IQ

An AI-powered crop recommendation system. Given a district's live weather
conditions, it recommends suitable crops using Google Gemini and presents them
in the user's preferred Indian language.

The repository contains three parts:

| Path | What it is | Status |
| --- | --- | --- |
| `crop_recommendation/` | **HARVEST-IQ Flutter app** (Android/iOS/web/desktop) | Primary, actively developed |
| `main.py`, `test.py` | Python CLI prototypes for weather + recommendation | Reference / prototype |
| `index.html`, `script.js`, `login.*`, `register.*` | Static web prototype | Reference / prototype |

## Features (Flutter app)

- 🌦️ Crop recommendations from live weather (OpenWeatherMap) + Gemini AI
- 🌍 Multilingual UI (English, Tamil) with additional translation support
- 🔐 Local authentication with profiles and PIN entry
- ⭐ Favorites, search history, and "what-if" scenario analysis
- 🗓️ Crop planner and market-price insights
- 🎮 Gamification: quizzes and a leaderboard
- 🔊 Text-to-speech and speech-to-text
- 📍 Geolocation, offline recommendations, and local notifications

## Configuration

This project needs two API keys. **They are never committed to source control.**

- `WEATHER_API_KEY` — [OpenWeatherMap](https://openweathermap.org/api)
- `GEMINI_API_KEY` — [Google Gemini](https://aistudio.google.com/app/apikey)

### Flutter app

Keys are injected at build time with `--dart-define` (see `lib/home_screen.dart`):

```bash
cd crop_recommendation
flutter pub get
flutter run \
  --dart-define=WEATHER_API_KEY=your_openweathermap_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

Build a release APK the same way:

```bash
flutter build apk --release \
  --dart-define=WEATHER_API_KEY=your_openweathermap_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

> Tip: create a `--dart-define-from-file` JSON to avoid retyping keys.

### Python CLI

```bash
pip install requests google-generativeai deep-translator
cp .env.example .env        # then fill in your keys
export WEATHER_API_KEY=...  # or load .env via your shell / python-dotenv
export GEMINI_API_KEY=...
python main.py
```

### Web prototype

```bash
cp config.example.js config.js   # then fill in your keys (config.js is gitignored)
# serve the folder, e.g.:
python -m http.server 8000
```

## Development

```bash
cd crop_recommendation
flutter pub get
flutter analyze          # static analysis
dart fix --dry-run       # preview automated lint fixes (const, deprecations, ...)
dart fix --apply         # apply them
flutter test             # run unit/widget tests
```

## Security

⚠️ **If you previously committed real API keys, rotate them now.** Keys that
have ever been committed must be considered compromised even after removal —
history and any clone still contains them. Regenerate the OpenWeatherMap and
Gemini keys, then supply the new ones via the mechanisms above.

`.gitignore` excludes secrets (`.env`, `config.js`), build artifacts, and
`node_modules/`.

## License

This project is currently unlicensed / private (`publish_to: none`).
