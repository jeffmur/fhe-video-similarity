import 'dart:io';
import 'package:crypto/crypto.dart';

Future<Digest> sha256ofFile(String path) =>
    File(path).openRead().transform(sha256).first;

Future<String> sha256ofFileAsString(String path, int chars) async {
  final hash = await sha256ofFile(path);
  return hash.toString().substring(0, chars);
}
