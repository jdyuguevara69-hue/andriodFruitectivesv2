// On-device fruit freshness detection (no internet, no API key).
//
// Model: assets/models/fruit_yolo26n.onnx — Ultralytics YOLO26n trained in "AI Training"
//   (runs/detect/train-3/weights/best.onnx, Roboflow dataset fruit-freshness-4f8dm v6).
//   input : images  float32 [1, 3, 416, 416]  RGB, 0..1, letterboxed (pad 114)
//   output: output0 float32 [1, 26, 3549]     rows 0-3 = cx, cy, w, h (input pixels),
//                                              rows 4-25 = per-class scores (already sigmoid)
//   The export has no NMS built in, so it is done here.
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import 'roboflow_client.dart' show FreshnessResult, FruitDetection;

const _modelAsset = 'assets/models/fruit_yolo26n.onnx';
const _inputSize = 416;

/// Class names in model order (from the model's metadata / dataset data.yaml).
const fruitModelLabels = [
  'Fresh Apple', 'Fresh Banana', 'Fresh Mango', 'Fresh Orange', 'Matang', 'Mentah', 'Peach',
  'Rotten Apple', 'Rotten Banana', 'Rotten Mango', 'Rotten Orange', 'Setengah Matang', 'busuk',
  'fresh apple', 'fresh banana', 'fresh orange', 'fresh pear', 'matang', 'rotten apple',
  'rotten banana', 'rotten orange', 'rotten pear',
];

class LocalDetectorException implements Exception {
  final String message;
  const LocalDetectorException(this.message);
  @override
  String toString() => 'LocalDetectorException: $message';
}

/// Letterboxed model input plus what's needed to map boxes back to the photo.
class _Prepared {
  final Float32List input;
  final int width, height; // photo size after EXIF rotation
  final double scale, padX, padY;
  const _Prepared(this.input, this.width, this.height, this.scale, this.padX, this.padY);
}

/// Decodes JPEG/PNG bytes and builds the [1,3,416,416] input. Runs in a background isolate.
_Prepared _prepare(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const LocalDetectorException('Could not read this photo.');
  final photo = img.bakeOrientation(decoded); // match what Image.memory shows
  final w = photo.width, h = photo.height;
  final scale = min(_inputSize / w, _inputSize / h);
  final nw = (w * scale).round(), nh = (h * scale).round();
  final resized = img.copyResize(photo, width: nw, height: nh, interpolation: img.Interpolation.linear);
  final padX = (_inputSize - nw) / 2, padY = (_inputSize - nh) / 2;
  final left = padX.floor(), top = padY.floor();

  const plane = _inputSize * _inputSize;
  final input = Float32List(3 * plane)..fillRange(0, 3 * plane, 114 / 255);
  for (final p in resized) {
    final i = (p.y + top) * _inputSize + (p.x + left);
    input[i] = p.rNormalized.toDouble();
    input[plane + i] = p.gNormalized.toDouble();
    input[2 * plane + i] = p.bNormalized.toDouble();
  }
  return _Prepared(input, w, h, scale, left.toDouble(), top.toDouble());
}

/// Turns raw [26][3549] output into detections in photo pixels (confidence filter + NMS).
/// Class-agnostic NMS: the dataset has near-duplicate classes ("Fresh Apple" / "fresh apple")
/// that would otherwise stack boxes on the same fruit.
List<FruitDetection> decodeYoloOutput(List<List<double>> out, {required double scale, required double padX,
    required double padY, required int imageWidth, required int imageHeight,
    double confThreshold = 0.25, double iouThreshold = 0.5, int maxDetections = 20}) {
  final anchors = out[0].length;
  final numClasses = out.length - 4;
  final candidates = <(FruitDetection, Rect4)>[];
  for (var a = 0; a < anchors; a++) {
    var best = 0, bestScore = 0.0;
    for (var c = 0; c < numClasses; c++) {
      final s = out[4 + c][a];
      if (s > bestScore) { bestScore = s; best = c; }
    }
    if (bestScore < confThreshold) continue;
    // Undo letterbox, clamp to the photo.
    final cx = (out[0][a] - padX) / scale, cy = (out[1][a] - padY) / scale;
    final bw = out[2][a] / scale, bh = out[3][a] / scale;
    final r = Rect4((cx - bw / 2).clamp(0, imageWidth.toDouble()), (cy - bh / 2).clamp(0, imageHeight.toDouble()),
        (cx + bw / 2).clamp(0, imageWidth.toDouble()), (cy + bh / 2).clamp(0, imageHeight.toDouble()));
    if (r.area <= 0) continue;
    final label = best < fruitModelLabels.length ? fruitModelLabels[best] : 'class $best';
    candidates.add((FruitDetection(label: label, confidence: bestScore, x: (r.l + r.r) / 2, y: (r.t + r.b) / 2,
        width: r.r - r.l, height: r.b - r.t), r));
  }
  candidates.sort((a, b) => b.$1.confidence.compareTo(a.$1.confidence));
  final kept = <(FruitDetection, Rect4)>[];
  for (final c in candidates) {
    if (kept.every((k) => k.$2.iou(c.$2) < iouThreshold)) kept.add(c);
    if (kept.length >= maxDetections) break;
  }
  return [for (final k in kept) k.$1];
}

class Rect4 {
  final double l, t, r, b;
  const Rect4(this.l, this.t, this.r, this.b);
  double get area => max(0, r - l) * max(0, b - t);
  double iou(Rect4 o) {
    final inter = Rect4(max(l, o.l), max(t, o.t), min(r, o.r), min(b, o.b)).area;
    return inter == 0 ? 0 : inter / (area + o.area - inter);
  }
}

/// Runs the trained YOLO model on the phone. Create once and reuse; the model loads on first use.
class LocalFruitDetector {
  LocalFruitDetector._();
  static final instance = LocalFruitDetector._();

  OrtSession? _session;
  Future<OrtSession>? _loading;

  Future<OrtSession> _load() => _loading ??= () async {
    try {
      return _session = await OnnxRuntime().createSessionFromAsset(_modelAsset,
          options: OrtSessionOptions(intraOpNumThreads: 4));
    } catch (e) {
      _loading = null; // allow a retry
      throw LocalDetectorException('Could not load the on-device AI model: $e');
    }
  }();

  /// Loads the model in the background so the first scan is faster.
  Future<void> warmUp() => _load().then((_) {}, onError: (_) {});

  /// Detects fruit in JPEG/PNG [imageBytes], most confident first.
  Future<FreshnessResult> detectFreshness(Uint8List imageBytes) async {
    final session = await _load();
    final prep = await Isolate.run(() => _prepare(imageBytes));

    final input = await OrtValue.fromList(prep.input, [1, 3, _inputSize, _inputSize]);
    Map<String, OrtValue>? outputs;
    try {
      outputs = await session.run({session.inputNames.first: input});
      final out = outputs[session.outputNames.first];
      final shape = out?.shape ?? const [];
      if (out == null || shape.length != 3 || shape[1] < 5) {
        throw LocalDetectorException('The AI model returned an unexpected output $shape.');
      }
      final flat = await out.asFlattenedList(); // [1, rows, anchors] row-major
      final numRows = shape[1], anchors = shape[2];
      final rows = [for (var r = 0; r < numRows; r++)
          [for (var a = 0; a < anchors; a++) (flat[r * anchors + a] as num).toDouble()]];
      final dets = decodeYoloOutput(rows, scale: prep.scale, padX: prep.padX, padY: prep.padY,
          imageWidth: prep.width, imageHeight: prep.height);
      return FreshnessResult(imageWidth: prep.width, imageHeight: prep.height, detections: dets);
    } finally {
      await input.dispose();
      for (final o in outputs?.values ?? const <OrtValue>[]) { await o.dispose(); }
    }
  }

  Future<void> close() async {
    await _session?.close();
    _session = null;
    _loading = null;
  }
}
