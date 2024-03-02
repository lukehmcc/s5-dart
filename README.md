# S5

This package makes it easy to use the S5 Network APIs in your Flutter and Dart apps.

## Features

- Runs a local S5 Node and connects to default nodes (can be configured)
- Provides all S5 APIs (file, registry, message) with full integrity verification
- Supports creating and restoring user identities and uploading to storage services

## Getting started

Install with `dart pub add s5`

## Example

```dart
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:s5/s5.dart';

void main(List<String> args) async {
  // Initialize the Hive data directory (not needed on web)
  Hive.init('data');

  // Create a S5 Node and API Client
  final s5 = await S5.create();

  // Download and deserialize a metadata CID
  final webAppMetadata = await s5.api.downloadMetadata(
    CID.decode(
      'z31rd7XSsfcDuuv716hjfbjitjCMRrfwPE24EWSuJntFKCdK',
    ),
  ) as WebAppMetadata;

  // Print all files of this web app with their CID and size
  for (final path in webAppMetadata.paths.entries) {
    print('${path.key} ${path.value.cid} (${path.value.cid.size} bytes)');
  }

  // Download one of the CSS files and print its contents
  final cssFileCID = webAppMetadata.paths['assets/css/default.min.css']!.cid;
  final bytes = await s5.api.downloadRawFile(cssFileCID.hash);
  print(utf8.decode(bytes));
}
```
