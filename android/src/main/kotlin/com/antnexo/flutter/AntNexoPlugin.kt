package com.antnexo.flutter

import com.antnexo.AntNexo
import com.antnexo.AntNexoWrapperApi
import com.antnexo.core.BridgePlatform
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** The plugin's Android side: maps the channel's calls onto the vendored Android SDK (src/main/vendor, ADR 0080). */
class AntNexoPlugin : FlutterPlugin, AntNexoHostApi {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AntNexoHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AntNexoHostApi.setUp(binding.binaryMessenger, null)
    }

    @OptIn(AntNexoWrapperApi::class)
    override fun setWrapper(sdk: String) {
        AntNexo.setWrapper(BridgePlatform.FLUTTER, sdk)
    }
}
