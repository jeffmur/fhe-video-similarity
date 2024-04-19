import 'uploader.dart';
import 'storage.dart';
import 'processor.dart';

/// Singleton class to manage all the media related operations
/// 
class Manager {
  static final Manager _instance = Manager._internal();

  /// Get the only instance of the manager
  factory Manager() {
    return _instance;
  }

  /// Initialize the manager
  Manager._internal();

  /// Select a video from the gallery
  // Future<Media> 
  
  
}
