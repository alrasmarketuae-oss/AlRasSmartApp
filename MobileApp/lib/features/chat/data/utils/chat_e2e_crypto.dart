import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as digest;
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class ChatPassphraseRequiredException implements Exception {
  const ChatPassphraseRequiredException();
}

class ChatPassphraseInvalidException implements Exception {
  const ChatPassphraseInvalidException();
}

/// Hybrid E2E: AES-256-GCM content + RSA-OAEP-SHA256 session-key wrap (JWK keys).
class ChatE2eCrypto {
  ChatE2eCrypto._();

  static const envelopeVersion = 1;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String _privKey(String userId) =>
      'chat_e2e_private_jwk_${userId.toLowerCase()}';
  static String _pubKey(String userId) =>
      'chat_e2e_public_jwk_${userId.toLowerCase()}';

  /// Deterministic wrap secret: SHA-256(password) when password exists,
  /// otherwise SHA-256(email). Never prompts the user.
  static String? deriveWrapSecret({
    String? password,
    String? email,
    String? userId,
  }) {
    final pwd = password?.trim() ?? '';
    final mail = (email ?? '').trim().toLowerCase();
    final uid = (userId ?? '').trim().toLowerCase();
    final String raw;
    if (pwd.isNotEmpty) {
      raw = 'alras|chat-wrap|v1|pwd|$uid|$pwd';
    } else if (mail.isNotEmpty) {
      raw = 'alras|chat-wrap|v1|email|$uid|$mail';
    } else {
      return null;
    }
    return digest.sha256.convert(utf8.encode(raw)).toString();
  }

  static bool isEnvelope(String? content) {
    if (content == null || content.trim().isEmpty) return false;
    final t = content.trim();
    if (!t.startsWith('{')) return false;
    try {
      final map = jsonDecode(t);
      return map is Map &&
          map['e2e'] == true &&
          map['v'] == envelopeVersion &&
          map['ct'] is String &&
          map['iv'] is String &&
          map['ek'] is Map;
    } catch (_) {
      return false;
    }
  }

  static const wrapVersion = 1;
  static const wrapIterations = 120000;

  static bool isPasswordWrapped(String? value) {
    if (value == null || value.trim().isEmpty || !value.trim().startsWith('{')) {
      return false;
    }
    try {
      final map = jsonDecode(value.trim());
      return map is Map &&
          map['wrapped'] == true &&
          map['ct'] is String &&
          map['salt'] is String &&
          map['iv'] is String;
    } catch (_) {
      return false;
    }
  }

  static Future<String> wrapPrivateKeyWithPassword({
    required String privateKeyJwk,
    required String password,
  }) async {
    final salt = Uint8List(16);
    final random = Random.secure();
    for (var i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }

    final derived = await crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: wrapIterations,
      bits: 256,
    ).deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final aes = crypto.AesGcm.with256bits();
    final nonce = aes.newNonce();
    final box = await aes.encrypt(
      utf8.encode(privateKeyJwk),
      secretKey: derived,
      nonce: nonce,
    );

    return jsonEncode({
      'v': wrapVersion,
      'wrapped': true,
      'kdf': 'PBKDF2-SHA256',
      'iter': wrapIterations,
      'salt': base64Encode(salt),
      'iv': base64Encode(nonce),
      'ct': base64Encode([...box.cipherText, ...box.mac.bytes]),
    });
  }

  static Future<String> unwrapPrivateKeyWithPassword({
    required String wrappedJson,
    required String password,
  }) async {
    if (!isPasswordWrapped(wrappedJson)) return wrappedJson;
    final map = jsonDecode(wrappedJson.trim()) as Map<String, dynamic>;
    final iterations = (map['iter'] as num?)?.toInt() ?? wrapIterations;
    final salt = base64Decode(map['salt'] as String);
    final iv = base64Decode(map['iv'] as String);
    final packed = base64Decode(map['ct'] as String);
    if (packed.length < 16) {
      throw const ChatPassphraseInvalidException();
    }

    final derived = await crypto.Pbkdf2(
      macAlgorithm: crypto.Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(
      secretKey: crypto.SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    try {
      final clear = await crypto.AesGcm.with256bits().decrypt(
        crypto.SecretBox(
          packed.sublist(0, packed.length - 16),
          nonce: iv,
          mac: crypto.Mac(packed.sublist(packed.length - 16)),
        ),
        secretKey: derived,
      );
      return utf8.decode(clear);
    } catch (_) {
      throw const ChatPassphraseInvalidException();
    }
  }

  /// Ensures a local keypair, syncing with the server so the same account
  /// can decrypt on any device. Private keys leave the device only after
  /// being wrapped with a derived secret (password hash or email hash).
  static Future<String> ensurePublicKeyJwk({
    required String userId,
    required List<String> wrapSecrets,
    required Future<({String publicKeyJwk, String privateKeyJwk})?> Function()
        downloadKeyPair,
    required Future<void> Function({
      required String publicKeyJwk,
      required String privateKeyJwk,
    }) uploadKeyPair,
  }) async {
    final secrets = wrapSecrets
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (secrets.isEmpty) {
      throw const ChatPassphraseRequiredException();
    }
    final primary = secrets.first;

    Future<String> wrapForUpload(String privateClear) async {
      return wrapPrivateKeyWithPassword(
        privateKeyJwk: privateClear,
        password: primary,
      );
    }

    Future<String> resolvePrivate(String remotePrivate) async {
      if (!isPasswordWrapped(remotePrivate)) {
        return remotePrivate;
      }
      ChatPassphraseInvalidException? lastError;
      for (final secret in secrets) {
        try {
          return await unwrapPrivateKeyWithPassword(
            wrappedJson: remotePrivate,
            password: secret,
          );
        } on ChatPassphraseInvalidException catch (e) {
          lastError = e;
        }
      }
      throw lastError ?? const ChatPassphraseInvalidException();
    }

    // 1) Server is source of truth for multi-device.
    final remote = await downloadKeyPair();
    if (remote != null &&
        remote.publicKeyJwk.isNotEmpty &&
        remote.privateKeyJwk.isNotEmpty) {
      final clearPrivate = await resolvePrivate(remote.privateKeyJwk);
      await _storage.write(key: _pubKey(userId), value: remote.publicKeyJwk);
      await _storage.write(key: _privKey(userId), value: clearPrivate);

      // Migrate legacy plaintext private keys to wrapped form.
      if (!isPasswordWrapped(remote.privateKeyJwk)) {
        await uploadKeyPair(
          publicKeyJwk: remote.publicKeyJwk,
          privateKeyJwk: await wrapForUpload(clearPrivate),
        );
      }
      return remote.publicKeyJwk;
    }

    // 2) Reuse local pair and push wrapped private to server.
    final existingPub = await _storage.read(key: _pubKey(userId));
    final existingPriv = await _storage.read(key: _privKey(userId));
    if (existingPub != null &&
        existingPub.isNotEmpty &&
        existingPriv != null &&
        existingPriv.isNotEmpty) {
      final clearPriv = isPasswordWrapped(existingPriv)
          ? await resolvePrivate(existingPriv)
          : existingPriv;
      await uploadKeyPair(
        publicKeyJwk: existingPub,
        privateKeyJwk: await wrapForUpload(clearPriv),
      );
      final afterUpload = await downloadKeyPair();
      if (afterUpload != null &&
          afterUpload.publicKeyJwk.isNotEmpty &&
          afterUpload.privateKeyJwk.isNotEmpty) {
        final clearAfter = await resolvePrivate(afterUpload.privateKeyJwk);
        await _storage.write(
          key: _pubKey(userId),
          value: afterUpload.publicKeyJwk,
        );
        await _storage.write(key: _privKey(userId), value: clearAfter);
        return afterUpload.publicKeyJwk;
      }
      await _storage.write(key: _privKey(userId), value: clearPriv);
      return existingPub;
    }

    // 3) First device: generate, keep clear locally, upload wrapped.
    final pair = _generateRsaKeyPair();
    final publicJwk = jsonEncode(_publicJwk(pair.publicKey as RSAPublicKey));
    final privateJwk = jsonEncode(_privateJwk(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    ));

    await _storage.write(key: _pubKey(userId), value: publicJwk);
    await _storage.write(key: _privKey(userId), value: privateJwk);
    await uploadKeyPair(
      publicKeyJwk: publicJwk,
      privateKeyJwk: await wrapForUpload(privateJwk),
    );
    return publicJwk;
  }

  static Future<String?> readLocalPublicKey(String userId) =>
      _storage.read(key: _pubKey(userId));

  static Future<String> encryptPlaintext({
    required String plaintext,
    required String myUserId,
    required String peerUserId,
    required String myPublicKeyJwk,
    required String peerPublicKeyJwk,
  }) async {
    final aes = crypto.AesGcm.with256bits();
    final secretKey = await aes.newSecretKey();
    final secretBytes = Uint8List.fromList(await secretKey.extractBytes());
    final nonce = aes.newNonce();
    final box = await aes.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );

    final ct = base64Encode([...box.cipherText, ...box.mac.bytes]);
    final iv = base64Encode(nonce);

    final ek = <String, String>{
      peerUserId.toLowerCase(): base64Encode(
        _rsaOaepEncrypt(_parsePublicJwk(peerPublicKeyJwk), secretBytes),
      ),
      myUserId.toLowerCase(): base64Encode(
        _rsaOaepEncrypt(_parsePublicJwk(myPublicKeyJwk), secretBytes),
      ),
    };

    return jsonEncode({
      'v': envelopeVersion,
      'e2e': true,
      'alg': 'AES-256-GCM+RSA-OAEP-256',
      'iv': iv,
      'ct': ct,
      'ek': ek,
    });
  }

  static Future<String> decryptEnvelope({
    required String envelopeJson,
    required String myUserId,
  }) async {
    if (!isEnvelope(envelopeJson)) return envelopeJson;

    final map = jsonDecode(envelopeJson) as Map<String, dynamic>;
    final ekMap = Map<String, dynamic>.from(map['ek'] as Map);
    final wrapped = ekMap[myUserId.toLowerCase()]?.toString();
    if (wrapped == null || wrapped.isEmpty) {
      throw StateError('No session key for this user.');
    }

    final privateJwk = await _storage.read(key: _privKey(myUserId));
    if (privateJwk == null || privateJwk.isEmpty) {
      throw StateError('Missing local private key.');
    }

    final sessionKey = _rsaOaepDecrypt(
      _parsePrivateJwk(privateJwk),
      base64Decode(wrapped),
    );

    final iv = base64Decode(map['iv'] as String);
    final packed = base64Decode(map['ct'] as String);
    if (packed.length < 16) {
      throw StateError('Invalid ciphertext.');
    }
    final mac = packed.sublist(packed.length - 16);
    final cipherText = packed.sublist(0, packed.length - 16);

    final aes = crypto.AesGcm.with256bits();
    final clear = await aes.decrypt(
      crypto.SecretBox(cipherText, nonce: iv, mac: crypto.Mac(mac)),
      secretKey: crypto.SecretKey(sessionKey),
    );
    return utf8.decode(clear);
  }

  static AsymmetricKeyPair<PublicKey, PrivateKey> _generateRsaKeyPair() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List(32);
    final random = Random.secure();
    for (var i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }
    secureRandom.seed(KeyParameter(seed));

    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
          secureRandom,
        ),
      );
    return keyGen.generateKeyPair();
  }

  static Map<String, dynamic> _publicJwk(RSAPublicKey key) => {
        'kty': 'RSA',
        'alg': 'RSA-OAEP-256',
        'ext': true,
        'key_ops': ['encrypt'],
        'n': _b64Url(_bigIntToBytes(key.modulus!)),
        'e': _b64Url(_bigIntToBytes(key.exponent!)),
      };

  static Map<String, dynamic> _privateJwk(
    RSAPublicKey pub,
    RSAPrivateKey priv,
  ) =>
      {
        ..._publicJwk(pub),
        'key_ops': ['decrypt'],
        'd': _b64Url(_bigIntToBytes(priv.privateExponent!)),
        'p': _b64Url(_bigIntToBytes(priv.p!)),
        'q': _b64Url(_bigIntToBytes(priv.q!)),
      };

  static RSAPublicKey _parsePublicJwk(String jsonStr) {
    final j = jsonDecode(jsonStr) as Map<String, dynamic>;
    return RSAPublicKey(_b64UrlToBigInt(j['n'] as String), _b64UrlToBigInt(j['e'] as String));
  }

  static RSAPrivateKey _parsePrivateJwk(String jsonStr) {
    final j = jsonDecode(jsonStr) as Map<String, dynamic>;
    final n = _b64UrlToBigInt(j['n'] as String);
    final d = _b64UrlToBigInt(j['d'] as String);
    final p = _b64UrlToBigInt(j['p'] as String);
    final q = _b64UrlToBigInt(j['q'] as String);
    return RSAPrivateKey(n, d, p, q);
  }

  static Uint8List _rsaOaepEncrypt(RSAPublicKey publicKey, Uint8List data) {
    final encryptor = OAEPEncoding.withCustomDigest(
      () => SHA256Digest(),
      RSAEngine(),
    )..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return _processInBlocks(encryptor, data);
  }

  static Uint8List _rsaOaepDecrypt(RSAPrivateKey privateKey, Uint8List data) {
    final decryptor = OAEPEncoding.withCustomDigest(
      () => SHA256Digest(),
      RSAEngine(),
    )..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return _processInBlocks(decryptor, data);
  }

  static Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
    final out = <int>[];
    var offset = 0;
    while (offset < input.length) {
      final chunkLen = min(engine.inputBlockSize, input.length - offset);
      out.addAll(engine.process(input.sublist(offset, offset + chunkLen)));
      offset += chunkLen;
    }
    return Uint8List.fromList(out);
  }

  static Uint8List _bigIntToBytes(BigInt number) {
    var hexStr = number.toRadixString(16);
    if (hexStr.length.isOdd) hexStr = '0$hexStr';
    return Uint8List.fromList(hex.decode(hexStr));
  }

  static String _b64Url(Uint8List bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');

  static BigInt _b64UrlToBigInt(String value) {
    var s = value.replaceAll('-', '+').replaceAll('_', '/');
    switch (s.length % 4) {
      case 2:
        s += '==';
        break;
      case 3:
        s += '=';
        break;
    }
    return BigInt.parse(hex.encode(base64Decode(s)), radix: 16);
  }
}
