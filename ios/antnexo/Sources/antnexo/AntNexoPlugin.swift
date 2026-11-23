import Flutter
import UIKit

/// The plugin's iOS side: maps the channel's calls onto the vendored Swift SDK (vendor/, ADR 0080).
public final class AntNexoPlugin: NSObject, FlutterPlugin, AntNexoHostApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    AntNexoHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: AntNexoPlugin())
  }

  // Flutter calls the plugin on the main thread; the SDK is main-actor isolated.
  func setWrapper(sdk: String) throws {
    MainActor.assumeIsolated { AntNexo.setWrapper(platform: .flutter, sdk: sdk) }
  }
}
