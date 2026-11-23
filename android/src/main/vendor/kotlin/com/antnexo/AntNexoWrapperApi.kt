// Vendored from AntNexo/antnexo-android v1.2.0 (11775bce31a1bae1865a46aa790392c28576d3bd) by scripts/vendor.sh. Do not edit.
package com.antnexo

/** Marks API for wrappers of this library (the React Native SDK), not for apps. */
@RequiresOptIn(message = "For wrappers of the AntNexo SDK (React Native), not for apps.", level = RequiresOptIn.Level.ERROR)
@Retention(AnnotationRetention.BINARY)
@Target(AnnotationTarget.FUNCTION)
annotation class AntNexoWrapperApi
