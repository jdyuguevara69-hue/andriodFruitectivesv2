// Roboflow Workflow client for fruit freshness detection.
//
// Workflow: "Fruit Freshness vfruit-freshness-4f8dm-6-rfdetr-nas-pecoret-t1--7893da Logic"
//   wraps the inner workflow "fruit-freshness-4f8dm" with model
//   fruit-freshness-4f8dm-6-rfdetr-nas-pecoret-t1--7893da (dataset v6, RF-DETR NAS, object detection).
//   input : image (InferenceImage)
//   output: predictions  -> { image: {width, height}, predictions: [ {class, confidence, x, y, width, height, ...} ] }
//
// The API key is read at build time from --dart-define ROBOFLOW_API_KEY (see README).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

const roboflowApiKey = String.fromEnvironment('ROBOFLOW_API_KEY');

const _apiUrl = 'https://serverless.roboflow.com';
const _workspace = 'jeffrey-daniel-yu-guevara-s-workspace';
const _workflowId = 'fruit-freshness-vfruit-freshness-4f8dm-6-rfdetr-nas-pecoret-t1-7893da-logic';

// ───────────── errors ─────────────
sealed class RoboflowException implements Exception {
  final String message;
  const RoboflowException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

class RoboflowConfigException extends RoboflowException {
  const RoboflowConfigException(super.message);
}

class RoboflowAuthException extends RoboflowException {
  const RoboflowAuthException(super.message);
}

/// HTTP 402: the Roboflow workspace has used up its inference credits (or hit its credit cap).
class RoboflowQuotaException extends RoboflowException {
  const RoboflowQuotaException(super.message);
}

class RoboflowNetworkException extends RoboflowException {
  const RoboflowNetworkException(super.message);
}

class RoboflowHttpException extends RoboflowException {
  final int statusCode;
  const RoboflowHttpException(this.statusCode, String message) : super(message);
}

class RoboflowResponseException extends RoboflowException {
  const RoboflowResponseException(super.message);
}

// ───────────── result types ─────────────
class FruitDetection {
  final String label; // raw class name from the model, e.g. "Rotten Banana", "matang"
  final double confidence; // 0..1
  final double x, y, width, height; // box centre + size, in image pixels

  const FruitDetection({required this.label, required this.confidence,
      required this.x, required this.y, required this.width, required this.height});

  static FruitDetection? tryParse(Object? j) {
    if (j is! Map) return null;
    final label = j['class'];
    final conf = j['confidence'];
    if (label is! String || conf is! num) return null;
    double n(Object? v) => v is num ? v.toDouble() : 0;
    return FruitDetection(label: label, confidence: conf.toDouble(),
        x: n(j['x']), y: n(j['y']), width: n(j['width']), height: n(j['height']));
  }
}

class FreshnessResult {
  final int imageWidth, imageHeight;
  final List<FruitDetection> detections; // sorted, most confident first

  const FreshnessResult({required this.imageWidth, required this.imageHeight, required this.detections});

  FruitDetection? get best => detections.isEmpty ? null : detections.first;

  /// Parses the body returned by the workflow endpoint.
  /// Accepts the REST shape `{"outputs": [ {...} ]}` and the bare list `[ {...} ]`.
  factory FreshnessResult.fromWorkflowResponse(Object? body) {
    final Object? outputs = body is Map ? body['outputs'] : body;
    if (outputs is! List || outputs.isEmpty || outputs.first is! Map) {
      throw const RoboflowResponseException('Workflow returned no outputs.');
    }
    final preds = (outputs.first as Map)['predictions'];
    if (preds is! Map) {
      throw const RoboflowResponseException('Workflow output "predictions" is missing.');
    }
    final img = preds['image'];
    int dim(String k) => img is Map && img[k] is num ? (img[k] as num).toInt() : 0;
    final list = preds['predictions'];
    final dets = (list is List ? list : const [])
        .map(FruitDetection.tryParse)
        .whereType<FruitDetection>()
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    return FreshnessResult(imageWidth: dim('width'), imageHeight: dim('height'), detections: dets);
  }
}

// ───────────── client ─────────────
class FruitFreshnessClient {
  final String apiKey;
  final http.Client _http;
  final Duration timeout;
  final int retries;

  FruitFreshnessClient({String? apiKey, http.Client? httpClient,
      this.timeout = const Duration(seconds: 30), this.retries = 2})
      : apiKey = apiKey ?? roboflowApiKey,
        _http = httpClient ?? http.Client();

  bool get isConfigured => apiKey.isNotEmpty;

  /// Runs the fruit freshness workflow on JPEG/PNG [imageBytes].
  /// Retries timeouts, network errors, 429 and 5xx with exponential backoff.
  Future<FreshnessResult> detectFreshness(Uint8List imageBytes) async {
    if (!isConfigured) {
      throw const RoboflowConfigException(
          'Roboflow API key missing. Run with --dart-define-from-file=roboflow.env.json');
    }
    final uri = Uri.parse('$_apiUrl/$_workspace/workflows/$_workflowId');
    final body = jsonEncode({
      'inputs': {'image': {'type': 'base64', 'value': base64Encode(imageBytes)}},
    });

    RoboflowException? last;
    for (var attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(milliseconds: 600 * (1 << (attempt - 1))));
      try {
        final res = await _http
            .post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'}, body: body)
            .timeout(timeout);
        if (res.statusCode == 401 || res.statusCode == 403) {
          throw RoboflowAuthException('Roboflow rejected the API key (HTTP ${res.statusCode}).');
        }
        if (res.statusCode == 402) {
          throw const RoboflowQuotaException(
              'The Roboflow workspace is out of inference credits. Check billing / credit cap at app.roboflow.com/settings/plan.');
        }
        if (res.statusCode == 429 || res.statusCode >= 500) {
          last = RoboflowHttpException(res.statusCode, 'Roboflow is busy (HTTP ${res.statusCode}).');
          continue;
        }
        if (res.statusCode != 200) {
          throw RoboflowHttpException(res.statusCode, 'Workflow request failed (HTTP ${res.statusCode}).');
        }
        try {
          return FreshnessResult.fromWorkflowResponse(jsonDecode(res.body));
        } on FormatException {
          throw const RoboflowResponseException('Workflow returned invalid JSON.');
        }
      } on TimeoutException {
        last = const RoboflowNetworkException('The analysis took too long. Check your connection.');
      } on SocketException {
        last = const RoboflowNetworkException('No internet connection.');
      } on http.ClientException catch (e) {
        last = RoboflowNetworkException('Network error: ${e.message}');
      }
    }
    throw last ?? const RoboflowNetworkException('Request failed.');
  }

  void close() => _http.close();
}
