import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fhe_video_similarity/media/processor.dart';

void main() {
  test('Sum must equal 1', () {
    final bytes = [
      [5, 10, 20, 5, 10],
    ];
    final flat = flatten(bytes).toList();
    final actual = normalizeSumOfElements(flat);
    expect(actual, [0.1, 0.2, 0.4, 0.1, 0.2,]);

    final actualSum = actual.reduce((value, element) => value + element);
    expect(actualSum, 1);
  });

}
