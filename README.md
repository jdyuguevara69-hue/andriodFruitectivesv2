# andriodfruitectivesv2

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Fruit scanning (on-device AI)

**Take Photo** / **Choose from Gallery** now run the AI **locally on the phone** — no internet and no API key needed.
- Model: `assets/models/fruit_yolo26n.onnx` = `AI Training/runs/detect/train-3/weights/best.onnx`
  (Ultralytics YOLO26n, 416×416, 22 classes from dataset v6). To update it, re-export and replace that file
  (if the class list changes, update `fruitModelLabels` in `lib/local_detector.dart`).
- Code: `lib/local_detector.dart` (`LocalFruitDetector.instance.detectFreshness`) using the `onnxruntime` plugin:
  letterbox to 416, run the model, confidence ≥ 0.25, class-agnostic NMS (IoU 0.5).
  It returns the same `FreshnessResult` the Roboflow client used, so the result page is unchanged.
- The model loads in the background at app start; a scan takes ~0.1 s after that (measured on an arm64 emulator).
- Android ABIs: arm64-v8a and armeabi-v7a only (x86/x86_64 emulators are not supported by the plugin).
- `android/build.gradle.kts` raises the onnxruntime plugin's compileSdk to 36 (it ships with 33).
- Tests: `flutter test test/local_detector_test.dart` (post-processing).

## Cloud scanning (Roboflow AI, no longer used by the Scan tab)

The previous cloud client is kept in `lib/roboflow_client.dart`. It used to:
**Take Photo** / **Choose from Gallery** on the Scan tab open the phone's camera or photo library
(`image_picker`), shrink the photo to 1280 px, and send it to the Roboflow Workflow
**Fruit Freshness vfruit-freshness-4f8dm-3-rfdetr-small-t1 Logic**
(`jeffrey-daniel-yu-guevara-s-workspace/fruit-freshness-vfruit-freshness-4f8dm-3-rfdetr-small-t1-logic`).
The result page shows the photo with the detected boxes, the fruit, and ripeness/freshness.
The "Try a demo" chips still give simulated results and are not saved to history.

- Client code: `lib/roboflow_client.dart` (`FruitFreshnessClient.detectFreshness`, 30 s timeout, 2 retries with backoff, typed `RoboflowException`s).
- Workflow output used: `predictions` → `{image: {width, height}, predictions: [{class, confidence, x, y, width, height}]}`.
- Model classes: `Fresh/Rotten Apple|Banana|Mango|Orange`, `fresh/rotten pear`, `Peach`, and ripeness labels
  `Mentah` (unripe), `Setengah Matang` (half ripe), `Matang`/`matang` (ripe), `busuk` (rotten). Mapping to the
  app's scores is in `scanFromDetection()` in `lib/main.dart`.

### Setup: API key
1. Get your private API key at https://app.roboflow.com/settings/api.
2. Create `roboflow.env.json` in the project root (it is gitignored, never commit it):
   ```json
   { "ROBOFLOW_API_KEY": "your_key_here" }
   ```
3. Run with the key:
   ```
   flutter pub get
   flutter run --dart-define-from-file=roboflow.env.json
   ```
   (Android Studio: add `--dart-define-from-file=roboflow.env.json` to the run configuration's "Additional run args".)

Without the key the app still runs, but scanning shows "AI not configured".
Note: a key compiled into an app can be extracted from the APK, so use a key you can roll, and don't ship it publicly.

### Tests
```
flutter test test/roboflow_client_test.dart                                   # offline tests
ROBOFLOW_API_KEY=your_key flutter test test/roboflow_client_test.dart         # + live smoke test
```
