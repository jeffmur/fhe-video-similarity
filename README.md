# flutter_fhe_video_similarity

Compute and Compare the similarity between two videos using Flutter and FHE (Fully Homomorphic Encryption).

## Getting Started

Setup dependencies:

* [opencv_dart](https://pub.dev/packages/opencv_dart)
* [fhel](https://pub.dev/packages/fhel)

```bash
flutter pub get
dart run opencv_dart:setup $PLATFORM --arch $ARCH
dart run fhel:setup $PLATFORM --arch $ARCH
```

### Linux

#### Dependencies

- [Zenity](https://help.gnome.org/users/zenity/stable) for Dialog Box Popup

From the root of this project, run the application:

```bash
flutter pub get
dart run opencv_dart:setup linux --arch x64
dart run fhel:setup linux --arch x64
flutter run -d linux
```

### Android

This platform is automatically supported by the plugin. No additional setup is required.
