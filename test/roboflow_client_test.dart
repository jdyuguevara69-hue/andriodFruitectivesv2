import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fruitectives_frontend/main.dart' show scanFromDetection;
import 'package:fruitectives_frontend/roboflow_client.dart';

// Response captured from this project's workflow (REST endpoint wraps it in "outputs").
// The v6 workflow keeps the same output ("predictions", object detection), so the shape is unchanged.
const _realResponse = '''
{"outputs":[{"predictions":{"image":{"width":2771,"height":2542},"predictions":[
 {"width":2751,"height":1145,"x":1395.5,"y":1329.5,"confidence":0.9521309733390808,"class_id":8,
  "class":"Rotten Banana","detection_id":"4c941a71-c28b-447c-addc-4787a44433bd","parent_id":"image"}]}}]}
''';

// One of the project's own images (a rotten banana).
const _sampleImageUrl = 'https://source.roboflow.com/EgYSLPChK2RoEwPsjwDmZa2K9Rt1/fTmPm05j7xEGNeYHsyRw/original.jpg';

void main() {
  group('parsing', () {
    test('parses the real workflow response', () {
      final r = FreshnessResult.fromWorkflowResponse(jsonDecode(_realResponse));
      expect(r.imageWidth, 2771);
      expect(r.imageHeight, 2542);
      expect(r.detections, hasLength(1));
      expect(r.best!.label, 'Rotten Banana');
      expect(r.best!.confidence, closeTo(0.952, 0.001));
    });

    test('empty predictions means no fruit', () {
      final r = FreshnessResult.fromWorkflowResponse(
          {'outputs': [{'predictions': {'image': {'width': 10, 'height': 10}, 'predictions': []}}]});
      expect(r.best, isNull);
    });

    test('missing outputs is a typed error', () {
      expect(() => FreshnessResult.fromWorkflowResponse({'outputs': []}),
          throwsA(isA<RoboflowResponseException>()));
    });

    test('maps model classes to scans', () {
      final rotten = scanFromDetection(const FruitDetection(label: 'Rotten Banana', confidence: .95, x: 0, y: 0, width: 1, height: 1));
      expect(rotten.fruit, 'Banana');
      expect(rotten.isRotten, isTrue);
      expect(rotten.freshnessLabel, 'Rotten');

      final fresh = scanFromDetection(const FruitDetection(label: 'Fresh Mango', confidence: .9, x: 0, y: 0, width: 1, height: 1));
      expect(fresh.fruit, 'Mango');
      expect(fresh.isFresh, isTrue);

      final half = scanFromDetection(const FruitDetection(label: 'Setengah Matang', confidence: .8, x: 0, y: 0, width: 1, height: 1));
      expect(half.ripenessLabel, 'Half ripe');
      expect(scanFromDetection(const FruitDetection(label: 'Mentah', confidence: .8, x: 0, y: 0, width: 1, height: 1)).ripenessLabel, 'Unripe');
      expect(scanFromDetection(const FruitDetection(label: 'busuk', confidence: .8, x: 0, y: 0, width: 1, height: 1)).isRotten, isTrue);
    });
  });

  group('client', () {
    test('sends bearer auth + base64 image, retries a 5xx', () async {
      var calls = 0;
      final mock = MockClient((req) async {
        calls++;
        expect(req.url.toString(), contains('/workflows/fruit-freshness-vfruit-freshness-4f8dm-6-rfdetr-nas-pecoret-t1-7893da-logic'));
        expect(req.headers['Authorization'], 'Bearer test-key');
        final body = jsonDecode(req.body) as Map;
        expect(body['inputs']['image']['type'], 'base64');
        expect(body.containsKey('api_key'), isFalse);
        return calls == 1 ? http.Response('busy', 503) : http.Response(_realResponse, 200);
      });
      final client = FruitFreshnessClient(apiKey: 'test-key', httpClient: mock);
      final r = await client.detectFreshness(Uint8List.fromList([1, 2, 3]));
      expect(calls, 2);
      expect(r.best!.label, 'Rotten Banana');
    });

    test('401 is an auth error (no retry)', () async {
      var calls = 0;
      final client = FruitFreshnessClient(apiKey: 'bad', httpClient: MockClient((_) async { calls++; return http.Response('no', 401); }));
      await expectLater(client.detectFreshness(Uint8List(1)), throwsA(isA<RoboflowAuthException>()));
      expect(calls, 1);
    });

    test('402 (credits exhausted) is a quota error (no retry)', () async {
      var calls = 0;
      final client = FruitFreshnessClient(apiKey: 'k', httpClient: MockClient((_) async { calls++; return http.Response('{"reason":"credit_cap_exceeded"}', 402); }));
      await expectLater(client.detectFreshness(Uint8List(1)), throwsA(isA<RoboflowQuotaException>()));
      expect(calls, 1);
    });

    test('missing key is a config error', () async {
      await expectLater(FruitFreshnessClient(apiKey: '').detectFreshness(Uint8List(1)),
          throwsA(isA<RoboflowConfigException>()));
    });
  });

  // Live smoke test: ROBOFLOW_API_KEY=... flutter test test/roboflow_client_test.dart
  final liveKey = Platform.environment['ROBOFLOW_API_KEY'] ?? '';
  test('smoke: real workflow returns predictions for a sample image', () async {
    final img = await http.get(Uri.parse(_sampleImageUrl));
    expect(img.statusCode, 200);
    final client = FruitFreshnessClient(apiKey: liveKey);
    final r = await client.detectFreshness(img.bodyBytes);
    client.close();
    // Expected output keys: predictions.image.{width,height} and predictions.predictions[].{class,confidence}
    expect(r.imageWidth, greaterThan(0));
    expect(r.detections, isNotEmpty);
    expect(r.best!.label, isNotEmpty);
    expect(r.best!.confidence, inInclusiveRange(0, 1));
  }, skip: liveKey.isEmpty ? 'set ROBOFLOW_API_KEY to run the live smoke test' : false,
     timeout: const Timeout(Duration(minutes: 2)));
}
