import 'package:pigeon/pigeon.dart';

// The channel between Dart and the native plugin classes. After editing, run
//   dart run pigeon --input pigeon/messages.dart
// and commit the generated files.

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'antnexo',
    dartOut: 'lib/src/messages.g.dart',
    kotlinOut: 'android/src/main/kotlin/com/antnexo/flutter/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.antnexo.flutter'),
    swiftOut: 'ios/antnexo/Sources/antnexo/Messages.g.swift',
  ),
)
@HostApi()
abstract class AntNexoHostApi {
  /// Tells the native SDK that posts come from this plugin: platform flutter, the plugin's version.
  void setWrapper(String sdk);
}
