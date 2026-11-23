package com.antnexo.flutter

import com.antnexo.AntNexoEvent
import com.antnexo.core.AntNexoException
import com.antnexo.core.FeedbackOptions
import com.antnexo.core.FeedbackTab
import com.antnexo.core.FeedbackTheme
import com.antnexo.core.WhatsNewMode
import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MappingTest {
    @Test
    fun everyOption() {
        val o = feedbackOptions(
            NativeOptions(
                tab = "roadmap", tabs = listOf("new", "roadmap"), boards = listOf("ideas"), theme = "dark",
                color = "#4f46e5", prompts = false, whatsNew = "off", language = "de",
            )
        )
        assertEquals(
            FeedbackOptions(
                tab = FeedbackTab.ROADMAP, tabs = listOf(FeedbackTab.NEW, FeedbackTab.ROADMAP), boards = listOf("ideas"),
                theme = FeedbackTheme.DARK, color = "#4f46e5", prompts = false, whatsNew = WhatsNewMode.OFF, language = "de",
            ),
            o,
        )
        assertEquals(FeedbackOptions(), feedbackOptions(NativeOptions()))
    }

    @Test
    fun unknownValuesAreLeftOutNotThrown() {
        val o = feedbackOptions(NativeOptions(tab = "home", theme = "blue", tabs = listOf("new", "x")))
        assertNull(o.tab)
        assertNull(o.theme)
        assertEquals(listOf(FeedbackTab.NEW), o.tabs)
    }

    @Test
    fun tabs() {
        assertEquals(FeedbackTab.CHANGELOG, tabOf("changelog"))
        assertNull(tabOf(null))
        assertNull(tabOf("home"))
    }

    @Test
    fun events() {
        assertEquals(NativeEvent(type = "posted", id = "x"), nativeEvent(AntNexoEvent.Posted("x")))
        assertEquals(NativeEvent(type = "closed"), nativeEvent(AntNexoEvent.Closed))
        assertEquals(NativeEvent(type = "unread", count = 4), nativeEvent(AntNexoEvent.Unread(4)))
        assertEquals(NativeEvent(type = "signed_in", signedIn = true), nativeEvent(AntNexoEvent.SignedIn(true)))
        assertEquals(NativeEvent(type = "identify_failed", code = "expired"), nativeEvent(AntNexoEvent.IdentifyFailed("expired")))
    }

    @Test
    fun errorsKeepTheCodeAndStatusNeverTheArguments() {
        fun check(t: Throwable, code: String, details: Any?) {
            val e = flutterError(t)
            assertEquals(code, e.code)
            assertEquals(details, e.details)
            assertEquals("AntNexo: $code", e.message)
        }
        check(AntNexoException.Http(503), "http", mapOf("status" to 503))
        check(AntNexoException.InvalidHost(), "invalid_host", null)
        check(AntNexoException.InvalidWorkspace(), "invalid_workspace", null)
        check(AntNexoException.NotConfigured(), "not_configured", null)
        check(AntNexoException.BadResponse(), "bad_response", null)
        check(IOException("offline https://secret"), "network", null)
        check(IllegalStateException(), "network", null)
    }
}
