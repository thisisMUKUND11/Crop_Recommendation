# HARVEST-IQ (Flutter app)

The HARVEST-IQ mobile/web/desktop client. It recommends crops from a district's
live weather using Google Gemini, with a multilingual UI and a range of farmer
tools (favorites, history, what-if analysis, crop planner, market prices,
quizzes, and more).

> Full project overview, prototypes, and security notes live in the
> [repository README](../README.md).

## Getting started

```bash
flutter pub get
flutter run \
  --dart-define=WEATHER_API_KEY=your_openweathermap_key \
  --dart-define=GEMINI_API_KEY=your_gemini_key
```

API keys are injected at build time via `--dart-define` and are never committed
to source. See [Configuration](../README.md#configuration) for details.

## Common commands

```bash
flutter analyze     # static analysis
dart fix --apply    # apply automated lint fixes
flutter test        # run tests
flutter build apk --release --dart-define=WEATHER_API_KEY=... --dart-define=GEMINI_API_KEY=...
```
