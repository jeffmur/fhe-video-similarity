// Retrieve stored artifacts from the cache

import 'dart:convert';

import 'package:flutter_fhe_video_similarity/media/storage.dart';

/// Recursively add media to the manifest
/// 
/// Add the media to the manifest by recursively adding the media to the leaf node of the manifest.
///
Map<String, dynamic> newLeaf(Map<String, dynamic> node, List<String> paths, String key, String val) {
  // Add the leaf node
  if (paths.isEmpty) {
    node[key] = val;
    return node;
  }

  final path = paths.removeAt(0);

  // Recurse into the nested map
  if (node[path] is Map) {
      return {
      ...node,
      path: newLeaf(node[path], paths, key, val)
    };
  }

  // Default case: Add empty branch
  return {
    ...node,
    path: newLeaf({}, paths, key, val)
  };
}

class Manifest {
  static final Manifest _instance = Manifest._internal();

  factory Manifest() {
    return _instance;
  }

  Manifest._internal();

  /// List of cached media files
  Map<String, dynamic> _media = {};

  Map<String, dynamic> get map => _media;

  /// Retrieve all paths in the manifest
  ///
  List<String> get paths {
    List<String> paths = [];
    void traverse(Map node, String path) {
      node.forEach((key, val) {
        if (val is Map) {
          traverse(val, '$path/$key');
        } else {
          paths.add('$path/$key.$val');
        }
      });
    }
    traverse(_media, '');
    return paths;
  }

  /// Read the manifest from the cache
  ///
  Future<void> initAsync() async {
    try {
      XFile manifest = await read('', 'manifest.json');
      final ctx = await manifest.readAsString();
      _media = jsonDecode(ctx);
    }
    catch (e) {
      print('Manifest not found');
      return;
    }
  }

  void init() {
    initAsync().then(
      (_) => print('Manifest initialized: $_media')
    );
  }

  /// Add a media file to the manifest
  /// 
  void add(String pwd, String filename) {
    // Path to working directory (pwd) may contain nested paths
    final paths = pwd.split('/');

    // Extract the file extension
    final file = filename.split('.').first;
    final ext = filename.split('.').last;
    
    // Insert filename:ext as a leaf node into the manifest
    Map<String, dynamic> tmp = _media;
    _media = newLeaf(tmp, paths, file, ext);

    print('Added to manifest: $_media');
    
  }

  /// Read the [XFile] from the cache
  /// 
  Future<XFile> read(String pwd, String filename) async {
    final cache = ApplicationStorage(pwd);
    final path = await cache.path;
    return XFile("$path/$filename");
  }

  /// Write the media [bytes] to the cache
  ///
  /// [filename] must include appropriate extension
  Future<XFileStorage> write(List<int> bytes, String pwd, String filename) async {
    // Store the media in the cache
    XFileStorage storage = XFileStorage.fromBytes(pwd, filename, bytes);
    await storage.write();

    // Add the media to the manifest
    add(pwd, filename);

    // save the manifest
    
    XFileStorage manifest = XFileStorage.fromBytes('', 'manifest.json', utf8.encode(jsonEncode(_media)));
    await manifest.write();

    return storage;
  }

}

// Manifest instance
final Manifest manifest = Manifest();
