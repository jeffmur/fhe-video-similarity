import 'dart:ffi';
import 'seal.dart';
import 'dart:convert';

String stringFromUint8(Pointer<Uint8> data, int size) {
  return utf8.decode(data.asTypedList(size), allowMalformed: true);
}

class CiphertextVideo {
  final List<Ciphertext> frames;
  final DateTime startTime;
  final DateTime endTime;
  final String hash;

  CiphertextVideo(this.frames, this.startTime, this.endTime, this.hash);

  Map get asMap => {
      'ciphertext': frames.map((e) => stringFromUint8(e.save(), e.saveSize)).toList(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'hash': hash,
    };

  CiphertextVideo.fromJson(Map<String, dynamic> json)
      : frames = (json['ciphertext'] as List).map((e) => e as Ciphertext).toList(), // TODO: load??
        startTime = json['startTime'],
        endTime = json['endTime'],
        hash = json['hash'];

  String base64String() {
    return base64Encode(utf8.encode(jsonEncode(asMap)));
  }

  CiphertextVideo.fromBase64String(String base64String)
      : this.fromJson(jsonDecode(utf8.decode(base64Decode(base64String))));
}
