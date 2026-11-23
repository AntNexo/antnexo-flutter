import Flutter
import Testing
import UIKit

@testable import antnexo

// Unit tests of the plugin's Swift side (run from Xcode or `xcodebuild test` on a simulator).
@MainActor
struct RunnerTests {
  @Test func setWrapperAcceptsTheSdkVersion() throws {
    try AntNexoPlugin().setWrapper(sdk: "1.0.0")
  }
}
