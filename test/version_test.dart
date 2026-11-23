import 'dart:io';

import 'package:antnexo/antnexo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sdkVersion is the package version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(sdkVersion, version);
  });
}
