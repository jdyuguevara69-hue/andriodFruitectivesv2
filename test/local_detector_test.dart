import 'package:flutter_test/flutter_test.dart';

import 'package:fruitectives_frontend/local_detector.dart';

/// Builds a fake [26][anchors] model output.
List<List<double>> _out(List<(double, double, double, double, int, double)> boxes) {
  final rows = List.generate(4 + fruitModelLabels.length, (_) => List<double>.filled(boxes.length, 0));
  for (var a = 0; a < boxes.length; a++) {
    final (cx, cy, w, h, cls, score) = boxes[a];
    rows[0][a] = cx; rows[1][a] = cy; rows[2][a] = w; rows[3][a] = h; rows[4 + cls][a] = score;
  }
  return rows;
}

void main() {
  test('undoes the letterbox and keeps the best of overlapping boxes', () {
    // 1280x720 photo -> scale 0.325, padded 91 px top/bottom (as in the Python check of best.onnx).
    final dets = decodeYoloOutput(_out([
      (267.8, 211.2, 227.4, 222.3, 5, 0.73), // Mentah
      (267.7, 211.1, 230.2, 222.2, 4, 0.40), // same fruit, other class -> suppressed
      (50, 300, 40, 40, 8, 0.10), // below threshold
      (60, 120, 50, 50, 8, 0.60), // separate fruit: Rotten Banana
    ]), scale: 0.325, padX: 0, padY: 91, imageWidth: 1280, imageHeight: 720);

    expect(dets.map((d) => d.label), ['Mentah', 'Rotten Banana']);
    expect(dets.first.confidence, closeTo(0.73, 1e-9));
    expect(dets.first.x, closeTo(267.8 / 0.325, 0.01));
    expect(dets.first.y, closeTo((211.2 - 91) / 0.325, 0.01));
    expect(dets.first.width, closeTo(227.4 / 0.325, 0.01));
  });

  test('no boxes above threshold -> empty', () {
    expect(decodeYoloOutput(_out([(100, 100, 20, 20, 0, 0.1)]), scale: 1, padX: 0, padY: 0,
        imageWidth: 416, imageHeight: 416), isEmpty);
  });
}
