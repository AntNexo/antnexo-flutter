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
/// configure's options, validated in Dart; wire values ('new', 'dark', 'badge', …), null = the SDK's default.
class NativeOptions {
  String? tab;
  List<String>? tabs;
  List<String>? boards;
  String? theme;
  String? color;
  bool? prompts;
  String? whatsNew;
  String? language;
}

/// An SDK event: type posted (id), closed, unread (count), signed_in (signedIn), identify_failed (code).
class NativeEvent {
  NativeEvent({required this.type});
  String type;
  String? id;
  int? count;
  bool? signedIn;
  String? code;
}

@HostApi()
abstract class AntNexoHostApi {
  /// Posts come from this plugin: platform flutter, the plugin's version.
  void setWrapper(String sdk);

  /// Errors: invalid_host, invalid_workspace.
  void configure(String host, String workspace, NativeOptions options);

  /// Shows the sheet with this opening's identify token (null: without). Completes when the sheet is gone (closed,
  /// or it couldn't open).
  @async
  void show(String? tab, bool screenshot, String? token);

  /// Closes the sheet as Done does.
  void close();

  /// What's new unread count. Errors: not_configured, http (details: status), bad_response, network.
  @async
  int unreadCount();

  /// Signs the person out, closing an open sheet.
  @async
  void logout();

  /// Debug builds only (the example's scripted checks): evaluates JavaScript in the open sheet, the result as a string.
  @async
  String? evaluateInSheet(String js);
}

@FlutterApi()
abstract class AntNexoEventsApi {
  void onEvent(NativeEvent event);
}
