import 'dart:async';

import 'package:antnexo/src/messages.g.dart';

/// The native side, faked (an external boundary): records calls; `show` completes when the test says so.
class FakeApi extends AntNexoHostApi {
  final calls = <String>[];
  final showArgs = <({String? tab, bool screenshot, String? token})>[];
  final showGenerations = <int>[];
  final cancelled = <int>[];
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
  Future<void> show(
    String? tab,
    bool screenshot,
    String? token,
    int generation,
  ) {
    calls.add('show');
    showGenerations.add(generation);
    showArgs.add((tab: tab, screenshot: screenshot, token: token));
    if (showError != null) return Future.error(showError!);
    showCompleter = Completer<void>();
    return showCompleter!.future;
  }

  /// The sheet is gone.
  void finishShow() => showCompleter?.complete();

  @override
  Future<void> close(int cancelled) async {
    calls.add('close');
    this.cancelled.add(cancelled);
    if (closeCompletesShow) finishShow();
  }

  /// false: close() leaves the sheet closing until finishShow() (a slow dismiss animation).
  bool closeCompletesShow = true;

  @override
  Future<int> unreadCount() async {
    calls.add('unreadCount');
    if (unreadError != null) throw unreadError!;
    return unread;
  }

  @override
  Future<void> logout(int cancelled) async {
    calls.add('logout');
    this.cancelled.add(cancelled);
    finishShow();
  }

  @override
  Future<String?> evaluateInSheet(String js) async => null;
}
