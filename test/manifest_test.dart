import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart';

void main() {
  test('Add to manifest', () {
    Manifest m = Manifest();
    m.add('foo', 'bar.1');
    expect(m.hashmap, {'foo': {'bar': '1'}});

    m.add('foo', 'baz.2');
    expect(m.hashmap, {'foo': {'bar': '1', 'baz': '2'}});

    // Overwrite bar with map
    m.add('foo/bar', 'baz.3');
    expect(m.hashmap, {'foo': {'bar': {'baz': '3'}, 'baz': '2'}});

    // Append to nested map
    m.add('foo/bar', 'buz.4');
    expect(m.hashmap, {'foo': {'bar': {'baz': '3', 'buz': '4'}, 'baz': '2'}});

    m.add('oof', 'rab.5');
    expect(m.hashmap, {'foo': {'bar': {'baz': '3', 'buz': '4'}, 'baz': '2'}, 'oof': {'rab': '5'}});
  });
}
