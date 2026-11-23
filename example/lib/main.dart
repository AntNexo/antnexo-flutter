import 'dart:async';

import 'package:antnexo/antnexo.dart';
// The example's scripted checks only: the plugin's hidden channel (debug builds), not part of the public API.
// ignore: implementation_imports
import 'package:antnexo/src/messages.g.dart' show AntNexoHostApi;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

// Launch options for scripted checks: flutter run --dart-define=HOST=http://… --dart-define=SCENARIO=show …
const _host = String.fromEnvironment(
  'HOST',
  defaultValue: 'https://splynx.antnexo.com',
);
const _workspace = String.fromEnvironment('WORKSPACE', defaultValue: 'splynx');
const _identify = String.fromEnvironment('IDENTIFY');
const _scenario = String.fromEnvironment(
  'SCENARIO',
); // show | roadmap | screenshot | sheet

/// JavaScript run in the open sheet a few seconds after a scenario opens it, separated by `;;` (iOS debug builds);
/// each result is printed as `[probe] …`. Every step must end in a value: the board's CSP forbids eval.
const _probe = String.fromEnvironment('PROBE');

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AntNexo example',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF4F46E5)),
    darkTheme: ThemeData(
      colorSchemeSeed: const Color(0xFF4F46E5),
      brightness: Brightness.dark,
    ),
    home: const ExamplePage(),
  );
}

class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  FeedbackTheme _theme = FeedbackTheme.auto;
  final _token = TextEditingController(text: _identify);
  int? _badge;
  bool _sheet = false;
  bool _ready = false;
  final _log = <String>[];
  StreamSubscription<AntNexoEvent>? _events;

  void _note(String line) {
    debugPrint('[example] $line');
    if (mounted) setState(() => _log.insert(0, line));
  }

  @override
  void initState() {
    super.initState();
    _events = AntNexo.events.listen((e) {
      _note('event $e');
      if (e is UnreadEvent) setState(() => _badge = e.count);
      if (e is ClosedEvent) _refreshBadge();
    });
    _identifyFromField();
    _token.addListener(_identifyFromField);
    _configure().then((_) => _runScenario());
  }

  @override
  void dispose() {
    _events?.cancel();
    _token.dispose();
    super.dispose();
  }

  // The pasted identify token (the example has no backend; never put the identify secret in an app).
  void _identifyFromField() {
    final t = _token.text.trim();
    AntNexo.identify(t.isEmpty ? null : () async => t);
  }

  Future<void> _configure() async {
    try {
      await AntNexo.configure(
        host: _host,
        workspace: _workspace,
        options: FeedbackOptions(theme: _theme),
      );
      setState(() => _ready = true);
      _refreshBadge();
    } on AntNexoException catch (e) {
      _note('configure: ${e.code.wire}');
    }
  }

  void _refreshBadge() {
    AntNexo.unreadCount()
        .then((n) {
          if (mounted) setState(() => _badge = n);
        })
        .catchError((Object e) {
          _note('unreadCount: ${e is AntNexoException ? e.code.wire : e}');
        });
  }

  Future<void> _show({FeedbackTab? tab, bool screenshot = false}) async {
    try {
      await AntNexo.show(tab: tab, screenshot: screenshot);
      _note('show completed');
    } on AntNexoException catch (e) {
      _note('show: ${e.code.wire}');
    }
  }

  void _runScenario() {
    if (!_ready || _scenario.isEmpty) return;
    _note('scenario $_scenario');
    switch (_scenario) {
      case 'show':
        _show();
      case 'roadmap':
        _show(tab: FeedbackTab.roadmap);
      case 'screenshot':
        _show(screenshot: true);
      case 'sheet':
        setState(() => _sheet = true);
    }
    if (_probe.isNotEmpty && kDebugMode) _runProbe();
  }

  Future<void> _runProbe() async {
    await Future<void>.delayed(const Duration(seconds: 6));
    final api = AntNexoHostApi();
    for (final js in _probe.split(';;')) {
      try {
        debugPrint('[probe] ${await api.evaluateInSheet(js)}');
      } catch (e) {
        debugPrint('[probe] error $e');
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AntNexo example')),
      body: AntNexoSheet(
        visible: _sheet,
        onDismiss: () {
          _note('AntNexoSheet dismissed');
          setState(() => _sheet = false);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '$_host · $_workspace · antnexo $sdkVersion',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _show, child: const Text('Send feedback')),
            OutlinedButton(
              onPressed: () => _show(tab: FeedbackTab.roadmap),
              child: const Text('Roadmap'),
            ),
            OutlinedButton(
              onPressed: () => _show(screenshot: true),
              child: const Text('Feedback with screenshot'),
            ),
            OutlinedButton(
              onPressed: () => _show(tab: FeedbackTab.changelog),
              child: Text("What's new${(_badge ?? 0) > 0 ? ' ($_badge)' : ''}"),
            ),
            SwitchListTile(
              title: const Text('AntNexoSheet'),
              value: _sheet,
              onChanged: (v) => setState(() => _sheet = v),
            ),
            SegmentedButton<FeedbackTheme>(
              segments: [
                for (final t in FeedbackTheme.values)
                  ButtonSegment(value: t, label: Text(t.name)),
              ],
              selected: {_theme},
              onSelectionChanged: (s) {
                setState(() => _theme = s.first);
                _configure();
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _token,
              decoration: const InputDecoration(
                labelText: 'Identify token (paste one signed by your backend)',
              ),
              autocorrect: false,
            ),
            OutlinedButton(
              onPressed: () async {
                _token.clear();
                AntNexo.identify(null);
                try {
                  await AntNexo.logout();
                  _note('logged out');
                } on AntNexoException catch (e) {
                  _note('logout: ${e.code.wire}');
                }
              },
              child: const Text('Log out'),
            ),
            const SizedBox(height: 8),
            Text('Events', style: Theme.of(context).textTheme.labelMedium),
            for (final l in _log)
              Text(
                l,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}
