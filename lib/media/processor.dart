import 'dart:io';
import 'package:crypto/crypto.dart';

Future<Digest> sha256ofFile(String path) =>
    File(path).openRead().transform(sha256).first;
