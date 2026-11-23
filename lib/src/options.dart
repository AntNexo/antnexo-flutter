import 'messages.g.dart';
import 'types.dart';

AntNexoException _bad(String what) => AntNexoException(
  AntNexoErrorCode.invalidOptions,
  'AntNexo: invalid option $what',
);

/// The board host as a bare http(s) origin (a trailing slash allowed), or invalidHost.
String _origin(String host) {
  final m = RegExp(
    r'^(https?)://([^/?#@\s]+)/?$',
    caseSensitive: false,
  ).firstMatch(host.trim());
  if (m == null || m.group(2)!.startsWith(':')) {
    throw const AntNexoException(
      AntNexoErrorCode.invalidHost,
      'AntNexo: host must be an http(s) origin like https://acme.antnexo.com',
    );
  }
  return '${m.group(1)!.toLowerCase()}://${m.group(2)}';
}

String? _nonEmpty(String name, String? v) {
  if (v != null && v.trim().isEmpty) {
    throw _bad(name);
  }
  return v;
}

/// Checks configure's arguments; the native SDKs check host and workspace again.
({String host, String workspace, NativeOptions options}) validateConfig(
  String host,
  String workspace, [
  FeedbackOptions o = const FeedbackOptions(),
]) {
  final h = _origin(host);
  final w = workspace.trim();
  if (w.isEmpty) {
    throw const AntNexoException(
      AntNexoErrorCode.invalidWorkspace,
      'AntNexo: workspace is empty',
    );
  }
  if (o.tabs != null && o.tabs!.isEmpty) {
    throw _bad('tabs');
  }
  if (o.boards != null && o.boards!.any((b) => b.trim().isEmpty)) {
    throw _bad('boards');
  }
  return (
    host: h,
    workspace: w,
    options: NativeOptions(
      tab: o.tab?.wire,
      tabs: o.tabs?.map((t) => t.wire).toList(),
      boards: o.boards == null ? null : List.of(o.boards!),
      theme: o.theme?.name,
      color: _nonEmpty('color', o.color),
      prompts: o.prompts,
      whatsNew: o.whatsNew?.name,
      language: _nonEmpty('language', o.language),
    ),
  );
}
