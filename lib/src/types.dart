/// The tab the sheet opens on.
enum FeedbackTab {
  newPost('new'),
  popular('popular'),
  roadmap('roadmap'),
  changelog('changelog');

  const FeedbackTab(this.wire);

  /// The name the widget uses.
  final String wire;
}

enum FeedbackTheme { light, dark, auto }

/// What's new: a badge on the Changelog tab, a popup with the latest entry, or nothing.
enum WhatsNewMode { badge, popup, off }

/// How the widget looks and what it shows; null fields keep the widget's defaults.
class FeedbackOptions {
  const FeedbackOptions({
    this.tab,
    this.tabs,
    this.boards,
    this.theme,
    this.color,
    this.prompts,
    this.whatsNew,
    this.language,
  });

  /// The tab it opens on.
  final FeedbackTab? tab;

  /// Which tabs, in that order.
  final List<FeedbackTab>? tabs;

  /// Which boards (their slugs).
  final List<String>? boards;

  final FeedbackTheme? theme;

  /// The accent color, like `#4f46e5`.
  final String? color;

  /// false: never ask the team's prompt questions.
  final bool? prompts;

  final WhatsNewMode? whatsNew;

  /// The widget's language (BCP 47); by default it follows the app's.
  final String? language;
}

/// What happens in the sheet.
sealed class AntNexoEvent {
  const AntNexoEvent();
}

/// The person posted (the post's id).
final class PostedEvent extends AntNexoEvent {
  const PostedEvent(this.id);
  final String id;
  @override
  String toString() => 'PostedEvent($id)';
}

/// The sheet closed.
final class ClosedEvent extends AntNexoEvent {
  const ClosedEvent();
  @override
  String toString() => 'ClosedEvent()';
}

/// What's new: how many entries the person hasn't seen.
final class UnreadEvent extends AntNexoEvent {
  const UnreadEvent(this.count);
  final int count;
  @override
  String toString() => 'UnreadEvent($count)';
}

/// The person signed in to the board, or out.
final class SignedInEvent extends AntNexoEvent {
  const SignedInEvent(this.signedIn);
  final bool signedIn;
  @override
  String toString() => 'SignedInEvent($signedIn)';
}

/// The identify token was refused (code: expired, invalid, …); the sheet works signed out.
final class IdentifyFailedEvent extends AntNexoEvent {
  const IdentifyFailedEvent(this.code);
  final String code;
  @override
  String toString() => 'IdentifyFailedEvent($code)';
}

/// Fetches a fresh identify token from the app's backend (null: open without identify).
typedef TokenProvider = Future<String?> Function();

enum AntNexoErrorCode {
  invalidHost('invalid_host'),
  invalidWorkspace('invalid_workspace'),
  invalidOptions('invalid_options'),
  notConfigured('not_configured'),
  http('http'),
  badResponse('bad_response'),
  network('network'),
  unavailable('unavailable');

  const AntNexoErrorCode(this.wire);
  final String wire;
}

class AntNexoException implements Exception {
  const AntNexoException(this.code, this.message, {this.status});

  final AntNexoErrorCode code;
  final String message;

  /// The HTTP status, for [AntNexoErrorCode.http].
  final int? status;

  @override
  String toString() =>
      'AntNexoException(${code.wire}${status != null ? ' $status' : ''}): $message';
}
