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

  test('the podspec and the Android library have the same version', () {
    final podspec = File('ios/antnexo.podspec').readAsStringSync();
    expect(
      RegExp(r"s\.version\s*=\s*'([^']+)'").firstMatch(podspec)?.group(1),
      sdkVersion,
    );
    final gradle = File('android/build.gradle.kts').readAsStringSync();
    expect(
      RegExp(
        r'^version = "([^"]+)"',
        multiLine: true,
      ).firstMatch(gradle)?.group(1),
      sdkVersion,
    );
  });
}
