import 'dart:async';

import 'package:antnexo/antnexo.dart';
import 'package:antnexo/src/messages.g.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

Matcher throwsCode(AntNexoErrorCode code) =>
    throwsA(isA<AntNexoException>().having((e) => e.code, 'code', code));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeApi api;
  late List<String> logs;

  setUp(() {
    api = FakeApi();
    AntNexo.debugReset(api: api);
    logs = [];
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
  });
  tearDown(() => debugPrint = debugPrintThrottled);

  Future<void> configure() => AntNexo.configure(
    host: 'https://splynx.antnexo.com',
    workspace: 'splynx',
  );

  test(
    'configure tells native the wrapper once, then the validated config',
    () async {
      await configure();
      await configure();
      expect(api.calls, [
        'setWrapper $sdkVersion',
        'configure https://splynx.antnexo.com splynx',
        'configure https://splynx.antnexo.com splynx',
      ]);
    },
  );

  test('native configure errors become AntNexoException', () async {
    api.configureError = PlatformException(
      code: 'invalid_host',
      message: 'bad host',
    );
    await expectLater(configure(), throwsCode(AntNexoErrorCode.invalidHost));
    await expectLater(
      AntNexo.show(),
      throwsCode(AntNexoErrorCode.notConfigured),
    );
  });

  test('a missing plugin is unavailable', () async {
    api.configureError = MissingPluginException();
    await expectLater(configure(), throwsCode(AntNexoErrorCode.unavailable));
  });

  test(
    'show before configure throws notConfigured and calls nothing',
    () async {
      await expectLater(
        AntNexo.show(),
        throwsCode(AntNexoErrorCode.notConfigured),
      );
      expect(api.calls, isNot(contains('show')));
    },
  );

  test(
    'show passes tab, screenshot and the provider token; completes when the sheet is gone',
    () async {
      await configure();
      AntNexo.identify(() async => 'jwt');
      var done = false;
      final f = AntNexo.show(
        tab: FeedbackTab.roadmap,
        screenshot: true,
      ).then((_) => done = true);
      await pumpEventQueue();
      expect(api.showArgs.single, (
        tab: 'roadmap',
        screenshot: true,
        token: 'jwt',
      ));
      expect(AntNexo.isShowing, isTrue);
      expect(done, isFalse);
      api.finishShow();
      await f;
      expect(AntNexo.isShowing, isFalse);
    },
  );

  test(
    'no token when the provider throws, gives nothing, or takes longer than 10 s',
    () {
      fakeAsync((async) {
        configure();
        async.flushMicrotasks();
        final providers = <TokenProvider>[
          () async => throw StateError('secret-token-in-error'),
          () async => '',
          () async => null,
          () => Completer<String?>().future,
        ];
        for (final p in providers) {
          AntNexo.identify(p);
          AntNexo.show();
          async.elapse(const Duration(seconds: 11));
          expect(api.showArgs.last.token, isNull);
          api.finishShow();
          async.flushMicrotasks();
        }
        expect(api.showArgs, hasLength(4));
        expect(logs.join('\n'), isNot(contains('secret-token-in-error')));
      });
    },
  );

  test('a second show while one is opening or up does nothing', () async {
    await configure();
    final slow = Completer<String?>();
    AntNexo.identify(() => slow.future);
    final first = AntNexo.show();
    await AntNexo.show(); // while the token is awaited
    slow.complete('jwt');
    await pumpEventQueue();
    await AntNexo.show(); // while the sheet is up
    expect(api.showArgs, hasLength(1));
    api.finishShow();
    await first;
    AntNexo.show();
    await pumpEventQueue();
    expect(api.showArgs, hasLength(2));
  });

  test(
    'close or logout while the token is awaited cancels that opening',
    () async {
      await configure();
      final slow = Completer<String?>();
      AntNexo.identify(() => slow.future);
      final f = AntNexo.show();
      AntNexo.close();
      slow.complete('jwt');
      await f;
      expect(api.calls, isNot(contains('show')));
      expect(AntNexo.isShowing, isFalse);

      final slow2 = Completer<String?>();
      AntNexo.identify(() => slow2.future);
      final g = AntNexo.show();
      await AntNexo.logout();
      slow2.complete('jwt-of-the-previous-person');
      await g;
      expect(api.calls.where((c) => c == 'show'), isEmpty);
      expect(api.calls, contains('logout'));
    },
  );

  test('a native show error clears isShowing and is mapped', () async {
    await configure();
    api.showError = PlatformException(code: 'network');
    await expectLater(AntNexo.show(), throwsCode(AntNexoErrorCode.network));
    expect(AntNexo.isShowing, isFalse);
  });

  test(
    'events: native maps become typed events; unknown or malformed ones are dropped',
    () async {
      final got = <AntNexoEvent>[];
      final sub = AntNexo.events.listen(got.add);
      final h = AntNexo.debugEventsApi;
      h.onEvent(NativeEvent(type: 'posted', id: 'p1'));
      h.onEvent(NativeEvent(type: 'closed'));
      h.onEvent(NativeEvent(type: 'unread', count: 3));
      h.onEvent(NativeEvent(type: 'signed_in', signedIn: true));
      h.onEvent(NativeEvent(type: 'identify_failed', code: 'expired'));
      h.onEvent(NativeEvent(type: 'unread')); // no count
      h.onEvent(NativeEvent(type: 'posted')); // no id
      h.onEvent(NativeEvent(type: 'later_type'));
      await pumpEventQueue();
      expect(got.map((e) => e.toString()), [
        'PostedEvent(p1)',
        'ClosedEvent()',
        'UnreadEvent(3)',
        'SignedInEvent(true)',
        'IdentifyFailedEvent(expired)',
      ]);
      await sub.cancel();
    },
  );

  test(
    'unreadCount passes the number and maps errors with the HTTP status',
    () async {
      await configure();
      api.unread = 4;
      expect(await AntNexo.unreadCount(), 4);
      api.unreadError = PlatformException(
        code: 'http',
        details: {'status': 503},
      );
      await expectLater(
        AntNexo.unreadCount(),
        throwsA(
          isA<AntNexoException>()
              .having((e) => e.code, 'code', AntNexoErrorCode.http)
              .having((e) => e.status, 'status', 503),
        ),
      );
      api.unreadError = PlatformException(code: 'something_new');
      await expectLater(
        AntNexo.unreadCount(),
        throwsCode(AntNexoErrorCode.network),
      );
    },
  );
}
