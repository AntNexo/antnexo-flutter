package com.antnexo.flutter

import android.app.Activity
import android.util.Log
import com.antnexo.AntNexo
import com.antnexo.AntNexoEvent
import com.antnexo.AntNexoWrapperApi
import com.antnexo.TokenProvider
import com.antnexo.core.BridgePlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/** The plugin's Android side: maps the channel's calls onto the vendored Android SDK (src/main/vendor, ADR 0080). */
class AntNexoPlugin : FlutterPlugin, ActivityAware, AntNexoHostApi {
    private var binding: FlutterPlugin.FlutterPluginBinding? = null
    private var activity: Activity? = null
    private var events: AntNexoEventsApi? = null
    private var scope: CoroutineScope? = null
    private val openings = Openings()

    /** SDK events to Dart while this engine is attached (main thread, like the SDK's listener list). */
    private val listener: (AntNexoEvent) -> Unit = { e ->
        val api = events
        val s = scope
        if (api != null && s != null) {
            s.launch {
                try {
                    api.onEvent(nativeEvent(e))
                } catch (_: Throwable) {
                    // Dart isn't listening (hot restart in progress): the event is dropped
                }
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        this.binding = binding
        scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        events = AntNexoEventsApi(binding.binaryMessenger)
        AntNexoHostApi.setUp(binding.binaryMessenger, this)
        AntNexo.addEventListener(listener)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AntNexo.removeEventListener(listener)
        AntNexoHostApi.setUp(binding.binaryMessenger, null)
        events = null
        scope?.cancel()
        scope = null
        this.binding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    @OptIn(AntNexoWrapperApi::class)
    override fun setWrapper(sdk: String) {
        openings.reset()
        AntNexo.setWrapper(BridgePlatform.FLUTTER, sdk)
    }

    override fun configure(host: String, workspace: String, options: NativeOptions) {
        val context = binding?.applicationContext ?: throw FlutterError("unavailable", "AntNexo: unavailable", null)
        try {
            AntNexo.configure(context, host, workspace, feedbackOptions(options))
        } catch (t: Throwable) {
            throw flutterError(t)
        }
    }

    /** Completes when the sheet is gone: closed, or it couldn't open. The token is for this opening only. */
    override suspend fun show(tab: String?, screenshot: Boolean, token: String?, generation: Long) {
        if (openings.isCancelled(generation)) return
        val a = activity
        if (a == null) {
            // e.g. between activities during a rotation: Dart gets an error, not a silent "closed"
            Log.w(TAG, "AntNexo.show(): no activity")
            throw FlutterError("unavailable", "AntNexo: unavailable", null)
        }
        // Kept until the sheet ends: only the SDK's prepare reads it, and a second prepare can't start while this
        // opening is presenting; onClosed below drops it right after the SDK clears presenting.
        AntNexo.identify(token?.takeIf { it.isNotEmpty() }?.let { t -> TokenProvider { t } })
        suspendCancellableCoroutine { cont ->
            AntNexo.show(a, tabOf(tab), screenshot, onClosed = {
                // the token goes with the sheet, so no later opening (native or Compose) reuses it
                AntNexo.identify(null)
                if (cont.isActive) cont.resume(Unit)
            })
        }
    }

    override fun close(cancelled: Long) {
        openings.cancel(cancelled)
        AntNexo.close()
    }

    override suspend fun unreadCount(): Long = try {
        AntNexo.unreadCount().toLong()
    } catch (t: Throwable) {
        throw flutterError(t)
    }

    override suspend fun logout(cancelled: Long) {
        openings.cancel(cancelled)
        AntNexo.identify(null)
        try {
            AntNexo.logout()
        } catch (t: Throwable) {
            throw flutterError(t)
        }
    }

    /** iOS only (the example's scripted checks); Android checks go over the WebView's DevTools. */
    override suspend fun evaluateInSheet(js: String): String? = null

    private companion object {
        const val TAG = "AntNexo"
    }
}
