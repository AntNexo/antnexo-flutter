import Flutter
import Testing
import UIKit

@testable import antnexo

// Unit tests of the plugin's Swift side (`xcodebuild test` on a simulator, from example/ios).
struct RunnerTests {
  @Test func everyOption() {
    let o = feedbackOptions(
      NativeOptions(
        tab: "roadmap", tabs: ["new", "roadmap"], boards: ["ideas"], theme: "dark", color: "#4f46e5",
        prompts: false, whatsNew: "off", language: "de"))
    #expect(
      o
        == FeedbackOptions(
          tab: .roadmap, tabs: [.new, .roadmap], boards: ["ideas"], theme: .dark, color: "#4f46e5", prompts: false,
          whatsNew: .off, language: "de"))
    #expect(feedbackOptions(NativeOptions()) == FeedbackOptions())
  }

  @Test func unknownValuesAreLeftOut() {
    let o = feedbackOptions(NativeOptions(tab: "home", tabs: ["new", "x"], theme: "blue"))
    #expect(o.tab == nil)
    #expect(o.theme == nil)
    #expect(o.tabs == [.new])
  }

  @Test func events() {
    #expect(nativeEvent(.posted(id: "x")) == NativeEvent(type: "posted", id: "x"))
    #expect(nativeEvent(.closed) == NativeEvent(type: "closed"))
    #expect(nativeEvent(.unread(count: 4)) == NativeEvent(type: "unread", count: 4))
    #expect(nativeEvent(.signedIn(true)) == NativeEvent(type: "signed_in", signedIn: true))
    #expect(nativeEvent(.identifyFailed(code: "expired")) == NativeEvent(type: "identify_failed", code: "expired"))
  }

  @Test func errorsKeepTheCodeAndStatus() {
    let http = pigeonError(AntNexoError.http(503))
    #expect(http.code == "http")
    #expect((http.details as? [String: Int]) == ["status": 503])
    #expect(pigeonError(AntNexoError.invalidHost).code == "invalid_host")
    #expect(pigeonError(AntNexoError.invalidWorkspace).code == "invalid_workspace")
    #expect(pigeonError(AntNexoError.notConfigured).code == "not_configured")
    #expect(pigeonError(AntNexoError.badResponse).code == "bad_response")
    let net = pigeonError(URLError(.notConnectedToInternet))
    #expect(net.code == "network")
    #expect(net.message == "AntNexo: network")
  }
}
