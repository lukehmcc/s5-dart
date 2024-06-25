import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:lib5/lib5.dart';

/// A class built on the lib5 KV abstract. This defintion allows for simple change of KV DB in the
/// future if needed. Currently it is built on hive.
class HiveKeyValueDB extends KeyValueDB {
  /// The Hive box used for KV entry and retrieval.
  final Box<Uint8List> box;

  HiveKeyValueDB(this.box);

  /// Checks if box contains value @ key.
  @override
  bool contains(Uint8List key) => box.containsKey(String.fromCharCodes(key));

  /// Gets contents of key.
  @override
  Uint8List? get(Uint8List key) => box.get(String.fromCharCodes(key));

  /// Sets key to passed Uint8List data.
  @override
  void set(Uint8List key, Uint8List value) => box.put(
        String.fromCharCodes(key),
        value,
      );

  /// Deletes contents @ key.
  @override
  void delete(Uint8List key) {
    box.delete(String.fromCharCodes(key));
  }
}
