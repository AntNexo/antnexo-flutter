import 'package:antnexo/antnexo.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api.dart';

class Host extends StatefulWidget {
  const Host({super.key, required this.onDismiss});
  final VoidCallback onDismiss;
  @override
  State<Host> createState() => HostState();
}

class HostState extends State<Host> {
  bool visible = false;
  bool mountedSheet = true;
  void set({bool? visible, bool? mountedSheet}) => setState(() {
    this.visible = visible ?? this.visible;
    this.mountedSheet = mountedSheet ?? this.mountedSheet;
  });

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: mountedSheet
        ? AntNexoSheet(
            visible: visible,
            onDismiss: widget.onDismiss,
            tab: FeedbackTab.changelog,
            screenshot: true,
            child: const Text('app'),
          )
        : const SizedBox(),
  );
}

void main() {
  late FakeApi api;
  setUp(() async {
    api = FakeApi();
    AntNexo.debugReset(api: api);
    await AntNexo.configure(host: 'https://x.com', workspace: 'w');
  });

  testWidgets(
    'visible opens the sheet with tab and screenshot; the sheet going away calls onDismiss once',
    (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(Host(onDismiss: () => dismissed++));
      expect(find.text('app'), findsOneWidget);
      expect(api.showArgs, isEmpty);
      tester.state<HostState>(find.byType(Host)).set(visible: true);
      await tester.pumpAndSettle();
      expect(api.showArgs.single, (
        tab: 'changelog',
        screenshot: true,
        token: null,
      ));
      api.finishShow();
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    },
  );

  testWidgets('visible false while open closes it', (tester) async {
    await tester.pumpWidget(Host(onDismiss: () {}));
    final host = tester.state<HostState>(find.byType(Host));
    host.set(visible: true);
    await tester.pumpAndSettle();
    host.set(visible: false);
    await tester.pumpAndSettle();
    expect(api.calls, contains('close'));
  });

  testWidgets('removed while open closes it and does not call onDismiss', (
    tester,
  ) async {
    var dismissed = 0;
    await tester.pumpWidget(Host(onDismiss: () => dismissed++));
    final host = tester.state<HostState>(find.byType(Host));
    host.set(visible: true);
    await tester.pumpAndSettle();
    host.set(mountedSheet: false);
    await tester.pumpAndSettle();
    expect(api.calls, contains('close'));
    expect(dismissed, 0);
  });

  testWidgets(
    'visible true, false, true quickly ends with the sheet open, not dismissed',
    (tester) async {
      var dismissed = 0;
      await tester.pumpWidget(Host(onDismiss: () => dismissed++));
      final host = tester.state<HostState>(find.byType(Host));
      host.set(visible: true);
      await tester.pump();
      // hide and show again before the first sheet has finished closing
      api.closeCompletesShow = false;
      host.set(visible: false);
      await tester.pump();
      host.set(visible: true);
      await tester.pump();
      api.finishShow(); // the first sheet is gone now
      await tester.pumpAndSettle();
      expect(dismissed, 0);
      expect(api.showArgs, hasLength(2));
      expect(AntNexo.isShowing, isTrue);
    },
  );
}
