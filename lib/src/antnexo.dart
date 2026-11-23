import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'messages.g.dart';
import 'options.dart';
import 'types.dart';
import 'version.dart';

/// How long the app's token provider may take before the sheet opens without identify.
const _identifyTimeout = Duration(seconds: 10);

/// The AntNexo board in a native sheet: configure once, then show.
abstract final class AntNexo {
  static AntNexoHostApi _api = AntNexoHostApi();
  static bool _setUp = false;
  static bool _configured = false;
  static bool _presenting = false;
  static TokenProvider? _tokenProvider;

  /// Bumped by close() and logout(): an opening still waiting for its token never happens, and native drops an opening
  /// whose show it receives after the close or logout that cancelled it.
  static int _generation = 0;
  static StreamController<AntNexoEvent> _events = StreamController.broadcast();
  static final _EventsHandler _handler = _EventsHandler();

  /// Once, at launch. [host] is the board host: `https://<slug>.antnexo.com` (recommended: it works on every plan and
  /// never changes with a custom domain) or the workspace's custom domain.
  static Future<void> configure({
    required String host,
    required String workspace,
    FeedbackOptions options = const FeedbackOptions(),
  }) async {
    final c = validateConfig(host, workspace, options);
    await _call(() async {
      if (!_setUp) {
        AntNexoEventsApi.setUp(_handler);
        await _api.setWrapper(sdkVersion);
        _setUp = true;
      }
      await _api.configure(c.host, c.workspace, c.options);
    });
    _configured = true;
  }

  /// When your app has its own accounts: a provider of a fresh identify token signed by your backend with the
  /// workspace's identify secret (never put the secret in the app). Called each time the sheet opens. null stops.
  /// On an account switch also call [logout]: it clears the session and cancels an opening still waiting for the old
  /// token.
  static void identify(TokenProvider? provider) => _tokenProvider = provider;

  /// Shows the sheet. Completes when it is gone again (closed, or it could not open). One at a time: while a sheet is
  /// up or opening, another call completes at once.
  static Future<void> show({FeedbackTab? tab, bool screenshot = false}) async {
    if (!_configured) {
      throw const AntNexoException(
        AntNexoErrorCode.notConfigured,
        'AntNexo.show() before AntNexo.configure()',
      );
    }
    if (_presenting) return;
    _presenting = true;
    final gen = _generation;
    try {
      final token = await _identifyToken();
      // closed or logged out meanwhile: the token may be the previous person's
      if (gen != _generation) return;
      await _call(() => _api.show(tab?.wire, screenshot, token, gen));
    } finally {
      _presenting = false;
    }
  }

  /// Closes the sheet, as Done does.
  static void close() {
    final cancelled = _generation++;
    unawaited(_call(() => _api.close(cancelled)).catchError((_) {}));
  }

  /// Whether a sheet is up or opening.
  static bool get isShowing => _presenting;

  /// What's new: how many entries the person hasn't seen (for a badge on your own button).
  static Future<int> unreadCount() => _call(_api.unreadCount);

  /// Signs the person out of the sheet (closing it if open). Call it on every account switch in your app.
  static Future<void> logout() {
    final cancelled = _generation++;
    return _call(() => _api.logout(cancelled));
  }

  /// Posts, the What's new count, sign-in, closing.
  static Stream<AntNexoEvent> get events => _events.stream;

  /// Tests: a fresh state over a fake native side.
  @visibleForTesting
  static void debugReset({required AntNexoHostApi api}) {
    _api = api;
    _setUp = false;
    _configured = false;
    _presenting = false;
    _tokenProvider = null;
    _generation = 0;
    _events = StreamController.broadcast();
  }

  /// Tests: the receiver of native events.
  @visibleForTesting
  static AntNexoEventsApi get debugEventsApi => _handler;

  /// The app's token, or null when there is no provider, it fails, gives nothing, or takes longer than the timeout.
  static Future<String?> _identifyToken() async {
    final provider = _tokenProvider;
    if (provider == null) return null;
    try {
      final token = await provider().timeout(_identifyTimeout);
      return token == null || token.isEmpty ? null : token;
    } on TimeoutException {
      debugPrint(
        'AntNexo: the identify token provider took longer than 10 s; opening without identify',
      );
      return null;
    } catch (_) {
      // never log the error itself: it may carry the token
      debugPrint(
        'AntNexo: the identify token provider failed; opening without identify',
      );
      return null;
    }
  }

  /// A native call with its errors as AntNexoException.
  static Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on MissingPluginException {
      throw const AntNexoException(
        AntNexoErrorCode.unavailable,
        "AntNexo: the plugin isn't in this build (web, a test without a fake, or a rebuild is missing)",
      );
    } on PlatformException catch (e) {
      final code =
          AntNexoErrorCode.values.where((c) => c.wire == e.code).firstOrNull ??
          AntNexoErrorCode.network;
      final details = e.details;
      final status = details is Map && details['status'] is int
          ? details['status'] as int
          : null;
      throw AntNexoException(
        code,
        e.message ?? 'AntNexo: ${code.wire}',
        status: status,
      );
    }
  }

  static void _emit(AntNexoEvent e) => _events.add(e);
}

class _EventsHandler implements AntNexoEventsApi {
  @override
  void onEvent(NativeEvent e) {
    final event = switch (e.type) {
      'posted' when e.id != null => PostedEvent(e.id!),
      'closed' => const ClosedEvent(),
      'unread' when e.count != null => UnreadEvent(e.count!),
      'signed_in' when e.signedIn != null => SignedInEvent(e.signedIn!),
      'identify_failed' when e.code != null => IdentifyFailedEvent(e.code!),
      _ => null,
    };
    if (event != null) AntNexo._emit(event);
  }
}
