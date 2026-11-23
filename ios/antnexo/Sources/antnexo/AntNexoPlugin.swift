import Flutter
import UIKit

/// The plugin's iOS side: maps the channel's calls onto the vendored Swift SDK (vendor/, ADR 0080). Dart validated the
/// values already; anything unknown is left out here rather than thrown. Flutter calls the plugin on the main thread.
public final class AntNexoPlugin: NSObject, FlutterPlugin, AntNexoHostApi {
  /// The plugin events go to: the newest engine's.
  @MainActor private static weak var current: AntNexoPlugin?
  private var events: AntNexoEventsApi?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = AntNexoPlugin()
    plugin.events = AntNexoEventsApi(binaryMessenger: registrar.messenger())
    AntNexoHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: plugin)
    registrar.publish(plugin)
    MainActor.assumeIsolated {
      current = plugin
      AntNexo.onEvent = { e in
        Task { @MainActor in
          // Dart not listening (a hot restart in progress): the event is dropped
          try? await current?.events?.onEvent(event: nativeEvent(e))
        }
      }
    }
  }

  public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    AntNexoHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: nil)
    events = nil
  }

  func setWrapper(sdk: String) throws {
    MainActor.assumeIsolated { AntNexo.setWrapper(platform: .flutter, sdk: sdk) }
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
  func show(tab: String?, screenshot: Bool, token: String?) async throws {
    let feedbackTab = tab.flatMap(FeedbackTab.init(rawValue:))
    await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
      Task { @MainActor in
        if let token, !token.isEmpty {
          AntNexo.identify { token }
        } else {
          AntNexo.identify(nil)
        }
        var resumed = false
        await AntNexo.present(from: nil, tab: feedbackTab, screenshot: screenshot, onClose: {
          if !resumed {
            resumed = true
            cont.resume()
          }
        })
        // prepare() has read the token: drop it, so no later opening (native or a SwiftUI modifier) reuses it
        AntNexo.identify(nil)
      }
    }
  }

  func close() throws {
    MainActor.assumeIsolated { AntNexo.close() }
  }

  func unreadCount() async throws -> Int64 {
    do {
      return Int64(try await AntNexo.unreadCount())
    } catch {
      throw pigeonError(error)
    }
  }

  func logout() async throws {
    await MainActor.run { AntNexo.identify(nil) }
    await AntNexo.logout()
  }

  /// Debug builds only (the example's scripted checks): JS in the open sheet, the result as text.
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
