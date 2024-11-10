import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' as m;
import 'package:flutter_fhe_video_similarity/seal.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/validator.dart';
import 'dart:math';

// Create a Form widget.
class EncryptionSettings extends StatefulWidget {
  final SessionChanges session;

  const EncryptionSettings({
    super.key,
    required this.session,
  });

  @override
  EncryptionSettingsState createState() => EncryptionSettingsState();
}

class EncryptionSettingsState extends State<EncryptionSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Encryption')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(100, 0, 100, 0),
        children: [
          const Text('Parameters'),
          ContextForm(session: widget.session),
          const Text('Keys'),
          KeyDerivation(session: widget.session)
        ],
      ),
    );
  }
}

class SessionChanges extends ChangeNotifier {
  List<String> _log = [];
  List<String> get logs => _log;

  Session _session = m.Manager().session; // default session
  Session get session => _session;
  String get scheme => _session.scheme;
  Map get context => _session.context.toMap();
  String get status => _session.context.status;

  String get publicKey => _session.publicKey;
  String get secretKey => _session.secretKey;
  String get relinKeys => _session.relinKeys;

  void validate(String scheme, Map context) {
    try {
      _session =
          Session.fromContextMap(encryptionTypeFromString(scheme), context);
      notifyListeners();
    } catch (e) {
      Logging().error('Failed to validate session: $e');
      // _log.add(e.toString());
    }
  }

  void log(String log) {
    _log.add(log);
    notifyListeners();
  }

  void clearLogs() {
    _log.clear();
    notifyListeners();
  }

  void logSession() {
    _log.add('Scheme: $scheme');
    _log.add('Context: $context');
    _log.add('Public Key: $publicKey');
    _log.add('Secret Key: $secretKey');
    _log.add('Relin Keys: $relinKeys');
    notifyListeners();
  }
}

// Create a Form widget.
class ContextForm extends StatefulWidget {
  final SessionChanges session;

  const ContextForm({
    super.key,
    required this.session,
  });

  @override
  ParameterForm createState() => ParameterForm();
}

// Create a corresponding State class.
// This class holds data related to the form.
class ParameterForm extends State<ContextForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  Map _context = {};
  String _scheme = 'ckks';
  bool isDefaultParams = true; // Toggle to use default parameters
  bool isBatchingEnabled = false; // BFV or BGV only

  @override
  void initState() {
    super.initState();
    _context = widget.session.context;
    _scheme = widget.session.scheme;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Expanded(
        flex: 1, // take minimum space
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CheckboxListTile(
              title: const Text('Use Default'),
              value: isDefaultParams,
              onChanged: (_) {
                setState(() {
                  isDefaultParams = !isDefaultParams;
                });
              },
            ),
            DropdownButtonFormField(
              value: _scheme,
              items: const [
                DropdownMenuItem(
                  value: 'ckks',
                  child: Text('CKKS'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _scheme = value.toString();
                  isDefaultParams = false;
                });
              },
            ),
            Visibility(
              visible: _scheme == 'ckks',
              child: TextFormField(
                enabled: !isDefaultParams,
                decoration: const InputDecoration(
                    hintText: 'Encoder Scalar', prefixText: '2^'),
                validator: (value) {
                  return isDefaultParams
                      ? _context['encodeScalar']
                      : validateUnsafeInt(value!);
                },
                onSaved: (newValue) =>
                    _context['encodeScalar'] = pow(2, int.parse(newValue!)),
              ),
            ),
            Visibility(
              visible: _scheme == 'ckks',
              child: TextFormField(
                enabled: !isDefaultParams,
                decoration:
                    const InputDecoration(hintText: 'Coeff Mod Bit Sizes'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  return isDefaultParams
                      ? _context['qSizes']
                      : validateUnsafeListInt(value!);
                },
                onSaved: (value) => _context['qSizes'] =
                    value!.split(',').map(int.parse).toList(),
              ),
            ),
            Visibility(
              visible: _scheme == 'bfv' || _scheme == 'bgv',
              child: TextFormField(
                enabled: !isDefaultParams,
                decoration: InputDecoration(
                  hintText: isBatchingEnabled == true
                      ? "Plain Modulus Bit Size"
                      : "Plain Modulus Size",
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  return isDefaultParams
                      ? isBatchingEnabled
                          ? _context['ptModBit']
                          : _context['ptMod']
                      : validateUnsafeInt(value!);
                },
                onSaved: (value) {
                  if (isBatchingEnabled) {
                    _context['ptModBit'] = int.parse(value!);
                  } else {
                    _context['ptMod'] = int.parse(value!);
                  }
                },
              ),
            ),
            Visibility(
              visible: _scheme == 'bfv' || _scheme == 'bgv',
              child: TextFormField(
                enabled: !isDefaultParams,
                decoration: const InputDecoration(
                  hintText: 'Security Level',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  return isDefaultParams
                      ? _context['secLevel']
                      : validateUnsafeInt(value!);
                },
                onSaved: (value) => _context['secLevel'] = int.parse(value!),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    widget.session.validate(_scheme, _context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(widget.session.status),
                          backgroundColor:
                              widget.session.status != 'success: valid'
                                  ? const Color.fromARGB(255, 148, 0, 0)
                                  : const Color.fromARGB(255, 0, 84, 35)),
                    );
                  }
                },
                child: const Text('Validate'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create a Form widget.
class KeyDerivation extends StatefulWidget {
  final SessionChanges session;
  const KeyDerivation({
    super.key,
    required this.session,
  });

  @override
  KeyDerivationState createState() {
    return KeyDerivationState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class KeyDerivationState extends State<KeyDerivation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('Public Key'),
              subtitle: Text(widget.session.publicKey),
            ),
            ListTile(
              title: const Text('Secret Key'),
              subtitle: Text(widget.session.secretKey),
            ),
            ListTile(
              title: const Text('Relin Keys'),
              subtitle: Text(widget.session.relinKeys),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              widget.session._session.genKeys();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Keys generated')),
            );
          },
          child: const Text('Generate Keys'),
        ),
      ],
    );
  }
}
