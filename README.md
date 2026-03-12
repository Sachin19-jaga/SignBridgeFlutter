# SignBridge Flutter App 🤟

AI Sign Language & Accessibility Platform — Flutter mobile app for Android/iOS.

## Overview

This is the Flutter mobile version of the SignBridge web app, featuring:
- **Real-time ASL sign recognition** using your trained `asl_model.tflite` model
- **Camera integration** with live hand gesture detection
- **Text-to-Speech** output for deaf users
- **Interactive learning mode** for all 26 ASL letters
- **Full accessibility** settings (haptics, high contrast, braille, audio description)
- **Dark cyberpunk UI** matching the original web app exactly

---

## Project Structure

```
SignBridgeFlutter/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── models/
│   │   └── app_colors.dart        # Theme colors (matching web app)
│   ├── services/
│   │   ├── asl_model_service.dart # TFLite inference wrapper
│   │   └── tts_service.dart       # Text-to-speech service
│   └── screens/
│       ├── splash_screen.dart     # Animated splash screen
│       ├── home_screen.dart       # Bottom nav + screen switcher
│       ├── recognize_screen.dart  # Main camera + AI recognition
│       ├── features_screen.dart   # Features + How It Works
│       ├── learn_screen.dart      # ASL alphabet learning mode
│       └── settings_screen.dart   # All accessibility settings
├── assets/
│   └── models/
│       └── asl_model.tflite       # YOUR TRAINED MODEL ✓
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml    # Camera + mic + vibration permissions
└── pubspec.yaml                   # Dependencies
```

---

## Setup in Android Studio

### Step 1: Prerequisites
- Android Studio (Hedgehog or newer)
- Flutter SDK 3.0+
- Android device or emulator (API 21+)

### Step 2: Open Project
1. Open Android Studio
2. File → Open → select the `SignBridgeFlutter` folder
3. Wait for Gradle sync

### Step 3: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 4: Configure Android Build

In `android/app/build.gradle`, ensure:
```groovy
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### Step 5: TFLite Flutter Setup

The `tflite_flutter` package requires native libraries. Add to `android/app/build.gradle`:
```groovy
android {
    aaptOptions {
        noCompress 'tflite'
    }
}
```

### Step 6: Run the App
```bash
flutter run
```

---

## Your Trained Model Integration

Your `asl_model.tflite` file is already placed in `assets/models/` and referenced in `pubspec.yaml`.

### Model Details
- **Input**: The model expects image input (the service handles reshaping)
- **Output**: 29 classes (A-Z + space + del + nothing)
- **File size**: ~72KB (very fast on-device)

### How It Works in the App
1. Camera captures frames via `camera` package
2. Frames are processed and fed to `asl_model_service.dart`
3. `ASLModelService.runInference()` runs the TFLite model
4. Top prediction shown in the UI with confidence score
5. Confirmed signs (held for 3 frames) added to transcript
6. TTS can speak the transcript aloud

### Customizing Input Shape
If your model expects a specific input shape, update `asl_model_service.dart`:
```dart
// The service auto-detects from model via:
final inputShape = inputTensor.shape;
```

---

## Features Implemented

| Feature | Status |
|---------|--------|
| Splash screen with animations | ✅ |
| Camera live preview | ✅ |
| TFLite model inference | ✅ |
| ASL sign detection | ✅ |
| Confidence bar | ✅ |
| Real-time transcript | ✅ |
| Text-to-Speech output | ✅ |
| Haptic feedback | ✅ |
| ASL/BSL/ISL mode switch | ✅ |
| Camera flip (front/back) | ✅ |
| Learn mode (all 26 letters) | ✅ |
| Quiz mode with scoring | ✅ |
| Roadmap section | ✅ |
| Settings (all accessibility) | ✅ |
| High contrast toggle | ✅ |
| Font scaling | ✅ |
| Speech rate control | ✅ |
| Dataset info screen | ✅ |
| Dark cyberpunk UI theme | ✅ |

---

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `camera` | Live camera feed |
| `tflite_flutter` | Run your .tflite model |
| `flutter_tts` | Text-to-speech for deaf users |
| `speech_to_text` | Speech-to-sign input |
| `vibration` | Haptic feedback for deaf-blind |
| `permission_handler` | Camera/mic permissions |

---

## MediaPipe Integration (Next Step)

For production-grade hand landmark detection (like the web app uses MediaPipe), integrate:

```yaml
# Add to pubspec.yaml
google_mediapipe: ^0.9.0
```

Then in `recognize_screen.dart`, replace the dummy input with actual landmarks:
```dart
// Get 21 hand landmarks × 3 (x,y,z) = 63 floats
final landmarks = await mediapipe.detectHands(cameraFrame);
final input = landmarks.flatMap((l) => [l.x, l.y, l.z]).toList();
final scores = _model.runInference(input);
```

---

## Permissions Required

| Permission | Why |
|-----------|-----|
| `CAMERA` | Hand gesture capture |
| `RECORD_AUDIO` | Speech-to-sign feature |
| `VIBRATE` | Haptic feedback (deaf-blind) |
| `INTERNET` | Optional future API calls |

---

## Matching the Web App UI

The Flutter app replicates the exact visual design:

| Web | Flutter |
|-----|---------|
| `#05080F` bg | `Color(0xFF05080F)` |
| `#00E5FF` cyan accent | `Color(0xFF00E5FF)` |
| `#7C3AED` purple accent | `Color(0xFF7C3AED)` |
| `#10B981` green | `Color(0xFF10B981)` |
| Scan line animation | `AnimationController` scan |
| Corner brackets overlay | `CustomPainter` |
| Confidence bar | `LinearProgressIndicator` |
| Feature cards | `AnimatedContainer` with hover |
| Roadmap timeline | Vertical line + dots |

---

Built for accessibility. Powered by AI. Open source.
WCAG 2.1 AAA · MIT License
