import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:lib5_crypto_implementation_dart/lib5_crypto_implementation_dart.dart';
import 'package:lib5/lib5.dart';
import 'package:lib5/node.dart';
import 'package:lib5/util.dart';

import 'hive_key_value_db.dart';

class S5 {
  final S5NodeBase node;
  S5NodeAPI api;

  CryptoImplementation get crypto => node.crypto;

  bool get hasIdentity => identity != null;
  S5UserIdentity? identity;
  late final Box<Uint8List> _authBox;

  S5.custom({
    required this.node,
    required this.api,
    required Box<Uint8List> authBox,
    this.identity,
  }) {
    _authBox = authBox;
  }

  static Future<S5> create({
    Uint8List? databaseEncryptionKey,
    List<String> initialPeers = const [
      'wss://z2Das8aEF7oNoxkcrfvzerZ1iBPWfm6D7gy3hVE4ALGSpVB@node.sfive.net/s5/p2p',
      'wss://z2DdbxV4xyoqWck5pXXJdVzRnwQC6Gbv6o7xDvyZvzKUfuj@s5.vup.dev/s5/p2p',
      'wss://z2DWuWNZcdSyZLpXFK2uCU3haaWMXrDAgxzv17sDEMHstZb@s5.garden/s5/p2p',
    ],
    bool autoConnectToNewNodes = false,
    Logger? logger,
  }) async {
    final crypto = DartCryptoImplementation();
    final node = S5NodeBase(
      config: {
        'name': 's5-dart',
        'keypair': {
          // TODO Maybe make the seed a bit more sticky
          'seed': base64UrlNoPaddingEncode(crypto.generateRandomBytes(32)),
        },
        'p2p': {
          'peers': {
            'initial': initialPeers,
            'autoConnectToNewNodes': autoConnectToNewNodes,
          }
        }
      },
      logger: logger ??
          SimpleLogger(
            prefix: '[S5] ',
            format: false,
          ),
      crypto: crypto,
    );

    await node.init(
      blobDB: await _openDB('blob'),
      registryDB: await _openDB('registry'),
      streamDB: await _openDB('stream'),
      nodesDB: await _openDB('nodes'),
    );
    final api = S5NodeAPI(
      node,
    );

    await api.init();

    final authBox = await Hive.openBox<Uint8List>(
      's5-auth',
      encryptionCipher: databaseEncryptionKey == null
          ? null
          : HiveAesCipher(databaseEncryptionKey),
    );

    if (authBox.containsKey('identity_main')) {
      final apiWithIdentity = S5NodeAPIWithIdentity(
        node,
        identity: S5UserIdentity.unpack(
          authBox.get('identity_main')!,
        ),
        authDB: HiveKeyValueDB(authBox),
      );
      await apiWithIdentity.initStorageServices();
      return S5.custom(
        node: node,
        api: apiWithIdentity,
        authBox: authBox,
        identity: apiWithIdentity.identity,
      );
    }
    return S5.custom(
      node: node,
      api: api,
      authBox: authBox,
    );
  }

  String generateSeedPhrase() {
    return S5UserIdentity.generateSeedPhrase(crypto: crypto);
  }

  Future<void> recoverIdentityFromSeedPhrase(String seedPhrase) async {
    final newIdentity = await S5UserIdentity.fromSeedPhrase(
      seedPhrase,
      crypto: crypto,
    );
    _authBox.put('identity_main', newIdentity.pack());
    final apiWithIdentity = S5NodeAPIWithIdentity(
      node,
      identity: newIdentity,
      authDB: HiveKeyValueDB(_authBox),
    );
    await apiWithIdentity.initStorageServices();
    api = apiWithIdentity;
    identity = newIdentity;
  }

  Future<void> registerOnNewStorageService(String url,
      {String? inviteCode}) async {
    await (api as S5NodeAPIWithIdentity).registerAccount(
      url,
      inviteCode: inviteCode,
    );
  }

  static Future<HiveKeyValueDB> _openDB(String key) async {
    return HiveKeyValueDB(await Hive.openBox('s5-node-$key'));
  }
}
