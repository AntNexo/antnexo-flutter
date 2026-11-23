import 'package:antnexo/antnexo.dart';
import 'package:antnexo/src/options.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher throwsCode(AntNexoErrorCode code) =>
    throwsA(isA<AntNexoException>().having((e) => e.code, 'code', code));

void main() {
  group('host', () {
    test('an http(s) origin, without the trailing slash', () {
      expect(
        validateConfig('https://splynx.antnexo.com', 'splynx').host,
        'https://splynx.antnexo.com',
      );
      expect(
        validateConfig('https://splynx.antnexo.com/', 'splynx').host,
        'https://splynx.antnexo.com',
      );
      expect(
        validateConfig('HTTP://acme.localhost:8090', 'acme').host,
        'http://acme.localhost:8090',
      );
    });

    test('anything else is invalidHost', () {
      for (final h in [
        'ftp://x.com',
        'https://x.com/path',
        'https://x.com?q=1',
        'https://x.com#f',
        'https://u:p@x.com',
        'https://:8090',
        '',
        'splynx.antnexo.com',
      ]) {
        expect(
          () => validateConfig(h, 'w'),
          throwsCode(AntNexoErrorCode.invalidHost),
          reason: h,
        );
      }
    });
  });

  test('workspace is trimmed and required', () {
    expect(validateConfig('https://x.com', ' splynx ').workspace, 'splynx');
    expect(
      () => validateConfig('https://x.com', '  '),
      throwsCode(AntNexoErrorCode.invalidWorkspace),
    );
  });

  test('options go to native as wire values, unset ones as null', () {
    final o = validateConfig(
      'https://x.com',
      'w',
      const FeedbackOptions(
        tab: FeedbackTab.newPost,
        tabs: [FeedbackTab.roadmap, FeedbackTab.changelog],
        boards: ['ideas'],
        theme: FeedbackTheme.dark,
        color: '#4f46e5',
        prompts: false,
        whatsNew: WhatsNewMode.popup,
        language: 'de',
      ),
    ).options;
    expect(o.tab, 'new');
    expect(o.tabs, ['roadmap', 'changelog']);
    expect(o.boards, ['ideas']);
    expect(o.theme, 'dark');
    expect(o.color, '#4f46e5');
    expect(o.prompts, false);
    expect(o.whatsNew, 'popup');
    expect(o.language, 'de');

    final none = validateConfig('https://x.com', 'w').options;
    expect([
      none.tab,
      none.tabs,
      none.boards,
      none.theme,
      none.color,
      none.prompts,
      none.whatsNew,
      none.language,
    ], everyElement(isNull));
  });

  test('empty lists and strings are invalidOptions', () {
    for (final o in const [
      FeedbackOptions(tabs: []),
      FeedbackOptions(boards: ['']),
      FeedbackOptions(color: ''),
      FeedbackOptions(language: ' '),
    ]) {
      expect(
        () => validateConfig('https://x.com', 'w', o),
        throwsCode(AntNexoErrorCode.invalidOptions),
      );
    }
  });
}
