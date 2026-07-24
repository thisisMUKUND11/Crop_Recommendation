# QA Checklist for HARVEST-IQ

## 1. Functional QA
- Verify login and registration flows work with valid and invalid input.
- Check crop recommendation flow using different locations/weather conditions.
- Confirm saved favorites, history, and profile screens behave correctly.
- Validate multilingual switching and language persistence.

## 2. UI/UX QA
- Test responsive layouts on phone and tablet sizes.
- Confirm buttons, navigation, and forms are accessible and readable.
- Check dark/light theme switching and visual consistency.

## 3. Performance QA
- Verify app launches within an acceptable time.
- Check for crashes during repeated navigation and rapid interactions.
- Confirm images and data load without visible delays.

## 4. Device QA
- Test on Android emulator and a physical Android device if possible.
- Validate permissions for camera, location, and notifications.
- Confirm offline/poor-network behavior is graceful.

## 5. Regression QA
- Run the automated test suite after every merge.
- Re-test critical user journeys after each release candidate.
- Review logs and crash reports for new issues.

## 6. Release QA Sign-off
- CI workflow passes on main branch.
- Release APK builds successfully.
- No critical or high-severity bugs remain open.
