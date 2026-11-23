package com.antnexo.flutter

import com.antnexo.AntNexoEvent
import com.antnexo.core.AntNexoException
import com.antnexo.core.FeedbackOptions
import com.antnexo.core.FeedbackTab
import com.antnexo.core.FeedbackTheme
import com.antnexo.core.WhatsNewMode

// Dart validated the values already; anything unknown is left out here rather than thrown.

internal fun tabOf(s: String?): FeedbackTab? = FeedbackTab.entries.firstOrNull { it.value == s }

internal fun feedbackOptions(o: NativeOptions): FeedbackOptions = FeedbackOptions(
    tab = tabOf(o.tab),
    tabs = o.tabs?.mapNotNull(::tabOf),
    boards = o.boards,
    theme = FeedbackTheme.entries.firstOrNull { it.value == o.theme },
    color = o.color,
    prompts = o.prompts,
    whatsNew = WhatsNewMode.entries.firstOrNull { it.value == o.whatsNew },
    language = o.language,
)

internal fun nativeEvent(e: AntNexoEvent): NativeEvent = when (e) {
    is AntNexoEvent.Posted -> NativeEvent(type = "posted", id = e.id)
    AntNexoEvent.Closed -> NativeEvent(type = "closed")
    is AntNexoEvent.Unread -> NativeEvent(type = "unread", count = e.count.toLong())
    is AntNexoEvent.SignedIn -> NativeEvent(type = "signed_in", signedIn = e.signedIn)
    is AntNexoEvent.IdentifyFailed -> NativeEvent(type = "identify_failed", code = e.code)
}

/** The error Dart gets: the code (AntNexoErrorCode) and, for http, the status. Never the arguments or a cause's text. */
internal fun flutterError(t: Throwable): FlutterError {
    val (code, status) = when (t) {
        is AntNexoException.InvalidHost -> "invalid_host" to null
        is AntNexoException.InvalidWorkspace -> "invalid_workspace" to null
        is AntNexoException.NotConfigured -> "not_configured" to null
        is AntNexoException.Http -> "http" to t.status
        is AntNexoException.BadResponse -> "bad_response" to null
        else -> "network" to null
    }
    return FlutterError(code, "AntNexo: $code", status?.let { mapOf("status" to it) })
}
