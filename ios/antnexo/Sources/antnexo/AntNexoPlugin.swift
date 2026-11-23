import Flutter
import UIKit

/// The plugin's iOS side: maps the channel's calls onto the vendored Swift SDK (vendor/, ADR 0080). Dart validated the
/// values already; anything unknown is left out here rather than thrown. Flutter calls the plugin on the main thread.
public final class AntNexoPlugin: NSObject, FlutterPlugin, AntNexoHostApi {
  /// Every attached engine's plugin: SDK events go to all of them (add-to-app can run several engines).
  @MainActor private static let attached = NSHashTable<AntNexoPlugin>.weakObjects()
  private var events: AntNexoEventsApi?
  @MainActor private var openings = Openings()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = AntNexoPlugin()
    plugin.events = AntNexoEventsApi(binaryMessenger: registrar.messenger())
    AntNexoHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
    registrar.publish(plugin)
    MainActor.assumeIsolated {
      attached.add(plugin)
      AntNexo.onEvent = { e in
        let event = nativeEvent(e)
        for p in attached.allObjects {
          Task { @MainActor in
            // Dart not listening (a hot restart in progress): the event is dropped
            try? await p.events?.onEvent(event: event)
          }
        }
      }
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    AntNexoHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    events = nil
    MainActor.assumeIsolated { _ = Self.attached.remove(self) }
  }

  func setWrapper(sdk: String) throws {
    MainActor.assumeIsolated {
      openings.reset()
      AntNexo.setWrapper(platform: .flutter, sdk: sdk)
    }
  }

  func configure(host: String, workspace: String, options: NativeOptions) throws {
    let o = feedbackOptions(options)
    try MainActor.assumeIsolated {
      do {
        guard let url = URL(string: host) else { throw AntNexoError.invalidHost }
        try AntNexo.configure(host: url, workspace: workspace, options: o)
      } catch {
        throw pigeonError(error)
      }
    }
  }

  /// Completes when the sheet is gone: closed, or it couldn't open. The token is for this opening only.
  /// Main-actor isolated, like logout: the generated handler starts both on the main actor, so they run in the order
  /// Dart sent them, and the SDK reads its generation before the first suspension.
  @MainActor
  func show(tab: String?, screenshot: Bool, token: String?, generation: Int64) async throws {
    if openings.isCancelled(generation) { return }
    if let token, !token.isEmpty {
      AntNexo.identify { token }
    } else {
      AntNexo.identify(nil)
    }
    let ended = Ended()
    await AntNexo.present(
      from: nil, tab: tab.flatMap(FeedbackTab.init(rawValue:)), screenshot: screenshot, onClose: { ended.fire() })
    // prepare() has read the token: drop it, so no later opening (native or a SwiftUI modifier) reuses it
    AntNexo.identify(nil)
    await ended.wait()
  }

  func close(cancelled: Int64) throws {
    MainActor.assumeIsolated {
      openings.cancel(upTo: cancelled)
      AntNexo.close()
    }
  }

  @MainActor
  func unreadCount() async throws -> Int64 {
    do {
      return Int64(try await AntNexo.unreadCount())
    } catch {
      throw pigeonError(error)
    }
  }

  @MainActor
  func logout(cancelled: Int64) async throws {
    openings.cancel(upTo: cancelled)
    AntNexo.identify(nil)
    await AntNexo.logout()
  }

  /// Debug builds only (the example's scripted checks): JS in the open sheet, the result as text.
  @MainActor
  func evaluateInSheet(js: String) async throws -> String? {
    #if DEBUG
      let result = try await AntNexo.evaluateInSheet(js)
      switch result {
      case nil: return nil
      case let s as String: return s
      default: return String(describing: result!)
      }
    #else
      return nil
    #endif
  }
}

/// The sheet's end, awaited once: `fire` may come before or after `wait` (an opening that never showed ends at once).
@MainActor
final class Ended {
  private var fired = false
  private var waiter: CheckedContinuation<Void, Never>?

  func fire() {
    guard !fired else { return }
    fired = true
    waiter?.resume()
    waiter = nil
  }

  func wait() async {
    if fired { return }
    await withCheckedContinuation { waiter = $0 }
  }
}

/// Dart's close/logout generations: an opening whose show native receives after the close or logout that cancelled
/// it completes without a sheet.
struct Openings {
  private var cancelledUpTo: Int64 = -1

  mutating func cancel(upTo: Int64) { cancelledUpTo = max(cancelledUpTo, upTo) }

  func isCancelled(_ generation: Int64) -> Bool { generation <= cancelledUpTo }

  /// A new Dart isolate (hot restart) counts from 0 again.
  mutating func reset() { cancelledUpTo = -1 }
}

func feedbackOptions(_ o: NativeOptions) -> FeedbackOptions {
  FeedbackOptions(
    tab: o.tab.flatMap(FeedbackTab.init(rawValue:)),
    tabs: o.tabs?.compactMap(FeedbackTab.init(rawValue:)),
    boards: o.boards,
    theme: o.theme.flatMap(FeedbackTheme.init(rawValue:)),
    color: o.color,
    prompts: o.prompts,
    whatsNew: o.whatsNew.flatMap(WhatsNewMode.init(rawValue:)),
    language: o.language)
}

func nativeEvent(_ e: AntNexoEvent) -> NativeEvent {
  switch e {
  case .posted(let id): return NativeEvent(type: "posted", id: id)
  case .closed: return NativeEvent(type: "closed")
  case .unread(let count): return NativeEvent(type: "unread", count: Int64(count))
  case .signedIn(let signedIn): return NativeEvent(type: "signed_in", signedIn: signedIn)
  case .identifyFailed(let code): return NativeEvent(type: "identify_failed", code: code)
  }
}

/// The error Dart gets: the code (AntNexoErrorCode) and, for http, the status. Never the arguments.
func pigeonError(_ error: Error) -> PigeonError {
  let (code, status): (String, Int?) =
    switch error as? AntNexoError {
    case .invalidHost: ("invalid_host", nil)
    case .invalidWorkspace: ("invalid_workspace", nil)
    case .notConfigured: ("not_configured", nil)
    case .http(let s): ("http", s)
    case .badResponse: ("bad_response", nil)
    case nil: ("network", nil)
    }
  return PigeonError(code: code, message: "AntNexo: \(code)", details: status.map { ["status": $0] })
}
