# FitCheck AI

Outfit suggestions from the clothes you already own.

**This is a placeholder template.** Screens and navigation exist, but the
features do not. Controls that are not built show a "Not built yet" message
naming the requirement, and all clothing, weather, and outfit data is sample
text.

## Run it

```bash
flutter pub get
flutter run
```

```bash
flutter analyze
flutter test
```

## Who owns what

Stay in your own folders to keep merge conflicts low.

| Member | Segment | Folders |
| --- | --- | --- |
| Member 1: Kameron | Closet | `lib/features/closet/`, `test/features/closet/` |
| Member 2: Hope | Outfits | `lib/features/outfits/`, `test/features/outfits/` |
| Member 3: Marcus | Database and AI | `lib/core/data/`, `lib/core/ai/`, `lib/core/weather/`, `firestore.rules` |
| Member 4: Keith | Platform and Fit Check | `lib/app/`, `lib/core/widgets/`, `lib/core/images/`, `lib/features/fit_check/`, `lib/features/settings/`, `.github/`, `pubspec.yaml`, `android/`, `ios/` |
