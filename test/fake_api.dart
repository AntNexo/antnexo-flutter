import 'dart:async';

import 'package:antnexo/src/messages.g.dart';

/// The native side, faked (an external boundary): records calls; `show` completes when the test says so.
class FakeApi extends AntNexoHostApi {
  final calls = <String>[];
  final showArgs = <({String? tab, bool screenshot, String? token})>[];
  Completer<void>? showCompleter;
  Object? configureError;
  Object? showError;
  Object? unreadError;
  int unread = 0;

  @override
  Future<void> setWrapper(String sdk) async => calls.add('setWrapper $sdk');

  @override
  Future<void> configure(
    String host,
    String workspace,
    NativeOptions options,
  ) async {
    calls.add('configure $host $workspace');
    lastOptions = options;
    if (configureError != null) throw configureError!;
  }

  NativeOptions? lastOptions;

  @override
  Future<void> show(String? tab, bool screenshot, String? token) {
    calls.add('show');
    showArgs.add((tab: tab, screenshot: screenshot, token: token));
    if (showError != null) return Future.error(showError!);
    showCompleter = Completer<void>();
    return showCompleter!.future;
  }

  /// The sheet is gone.
  void finishShow() => showCompleter?.complete();

  @override
  Future<void> close() async {
    calls.add('close');
    finishShow();
  }

  @override
  Future<int> unreadCount() async {
    calls.add('unreadCount');
    if (unreadError != null) throw unreadError!;
    return unread;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    finishShow();
  }

  @override
  Future<String?> evaluateInSheet(String js) async => null;
}
