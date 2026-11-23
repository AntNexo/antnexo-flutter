import 'dart:async';

import 'package:flutter/widgets.dart';

import 'antnexo.dart';
import 'types.dart';

/// Shows the sheet while [visible] is true; [onDismiss] is called when it goes away (Done, a swipe, [AntNexo.close]),
/// so set [visible] back to false there. Renders [child] unchanged.
class AntNexoSheet extends StatefulWidget {
  const AntNexoSheet({
    super.key,
    required this.visible,
    required this.onDismiss,
    this.tab,
    this.screenshot = false,
    this.child,
  });

  final bool visible;
  final VoidCallback onDismiss;
  final FeedbackTab? tab;

  /// Offer a screenshot of the app with the post (opt-in).
  final bool screenshot;
  final Widget? child;

  @override
  State<AntNexoSheet> createState() => _AntNexoSheetState();
}

class _AntNexoSheetState extends State<AntNexoSheet> {
  bool _open = false;

  /// Shown again while the previous sheet was still closing: open a new one once it's gone.
  bool _reopen = false;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _show();
  }

  @override
  void didUpdateWidget(AntNexoSheet old) {
    super.didUpdateWidget(old);
    if (!old.visible && widget.visible) {
      _show();
    } else if (old.visible && !widget.visible && _open) {
      _reopen = false;
      AntNexo.close();
    }
  }

  @override
  void dispose() {
    if (_open) AntNexo.close();
    super.dispose();
  }

  void _show() {
    if (_open) {
      _reopen = true;
      return;
    }
    _open = true;
    unawaited(
      AntNexo.show(tab: widget.tab, screenshot: widget.screenshot)
          .catchError((Object e) {
            debugPrint('AntNexoSheet: $e');
          })
          .whenComplete(() {
            _open = false;
            if (_reopen && mounted && widget.visible) {
              _reopen = false;
              _show();
              return;
            }
            _reopen = false;
            if (mounted) widget.onDismiss();
          }),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}
