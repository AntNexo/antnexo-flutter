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

struct OpeningsTests {
  @Test func aCancelledOpeningStaysCancelledWhicheverArrivesFirst() {
    var o = Openings()
    #expect(!o.isCancelled(0))
    o.cancel(upTo: 0)
    #expect(o.isCancelled(0))
    #expect(!o.isCancelled(1))
    o.cancel(upTo: 3)
    o.cancel(upTo: 1)
    #expect(o.isCancelled(3))
    #expect(!o.isCancelled(4))
    o.reset()
    #expect(!o.isCancelled(0))
  }

  @MainActor @Test func endedResumesOnceWhicheverComesFirst() async {
    let early = Ended()
    early.fire()
    await early.wait()  // fired before waiting: returns at once
    let late = Ended()
    Task { @MainActor in late.fire(); late.fire() }
    await late.wait()
  }
}
