import 'dart:math';
import 'package:fhel/seal.dart';
export 'package:fhel/seal.dart';

import 'package:fhel/afhe.dart';
export 'package:fhel/afhe.dart';

enum EncryptionScheme { ckks } // Floating-point number encryption

const Map<EncryptionScheme, String> _encryptionSchemeMap = {
  EncryptionScheme.ckks: 'ckks',
};

String encryptionTypeToString(EncryptionScheme type) {
  return _encryptionSchemeMap[type] ??
      (throw UnsupportedError('Unsupported encryption type'));
}

EncryptionScheme encryptionTypeFromString(String type) {
  return _encryptionSchemeMap.keys.firstWhere(
    (key) => _encryptionSchemeMap[key] == type,
    orElse: () => throw UnsupportedError('Unsupported encryption type'),
  );
}

class Session {
  EncryptionScheme type = EncryptionScheme.ckks;
  late final Seal seal;
  late Context context;

  Session({this.type = EncryptionScheme.ckks}) {
    seal = Seal(encryptionTypeToString(type));
    context = Context(seal);
    genKeys();
  }

  Session.fromContext(this.context) {
    seal = context.seal;
    type = encryptionTypeFromString(seal.scheme.name);
    genKeys();
  }

  Session.fromContextMap(EncryptionScheme type, Map ctx) {
    seal = Seal(encryptionTypeToString(type));
    context = Context.fromMap(seal, ctx);
    genKeys();
  }

  void genKeys() {
    seal.genKeys();
    seal.genRelinKeys();
  }

  /// Retrieve the scheme name
  String get scheme => seal.scheme.name;

  /// Retrieve the public key
  String get publicKey => seal.publicKey.hexData.join(' ');

  /// Retrieve the secret key
  String get secretKey => seal.secretKey.hexData.join(' ');

  /// Retrieve the relin keys
  String get relinKeys => seal.relinKeys.hexData.join(' ');

  Plaintext encodeVecDouble(List<double> data) {
    return seal.encodeVecDouble(data);
  }

  /// Encrypt a list of double values
  ///
  /// Intuitive to iterate over a list of CipherTexts than to
  /// assume a single Ciphertext is encoded with doubles.
  ///
  List<Ciphertext> encryptVecDouble(List<double> data) {
    return data.map((e) => seal.encrypt(seal.encodeDouble(e))).toList();
  }

  /// Summation of a list of [Ciphertext] doubles.
  ///
  double decryptedSumOfDoubles(List<Ciphertext> encrypted) {
    return encrypted
        .map((e) => seal.decrypt(e)) // List<Ciphertext> -> List<Plaintext>
        .map((e) =>
            seal.decodeVecDouble(e, 1).first) // List<Plaintext> -> List<double>
        .reduce((a, b) => a + b); // Sum of List<double>
  }
}

final defaultCKKS = {
  'polyModDegree': 4096,
  'encodeScalar': pow(2, 40),
  'qSizes': [60, 40, 40, 60]
};

class Context {
  Seal seal;
  late num polyModulusDegree;
  late num encodeScalar;
  late List<num> qSizes;
  late String status;
  // ptMod
  // ptModBit
  // secLevel

  Context(this.seal,
      {num? polyModulusDegree, num? encodeScalar, List<num>? qSizes}) {
    this.polyModulusDegree =
        polyModulusDegree ?? defaultCKKS['polyModDegree'] as int;
    this.encodeScalar = encodeScalar ?? defaultCKKS['encodeScalar'] as int;
    this.qSizes = qSizes ?? defaultCKKS['qSizes'] as List<int>;
    generate();
  }

  Context.fromMap(this.seal, json) {
    polyModulusDegree = json['polyModDegree']! as int;
    encodeScalar = json['encodeScalar']! as int;
    qSizes = json['qSizes']! as List<int>;
    generate();
  }

  Map toMap() {
    return {
      'polyModDegree': polyModulusDegree,
      'encodeScalar': encodeScalar,
      'qSizes': qSizes
    };
  }

  /// Generate the context, automatically called by constructors.
  /// May be called again to regenerate the context
  ///
  /// Throws an exception if the context is invalid
  ///
  String generate() {
    status = seal.genContext(toMap());
    if (status != 'success: valid') {
      throw Exception(status);
    }
    return 'success: valid'; // status
  }
}
