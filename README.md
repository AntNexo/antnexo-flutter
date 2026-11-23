# AntNexo for Flutter

In-app feedback for Flutter apps: the [AntNexo](https://antnexo.com) board (ideas, roadmap, changelog) in a native
sheet, on iOS and Android.

> Work in progress: the Dart API and the docs land with 1.0.0.

The plugin wraps the [Swift](https://github.com/AntNexo/antnexo-swift) and
[Android](https://github.com/AntNexo/antnexo-android) SDKs: their sources are vendored by `scripts/vendor.sh` at the
tags in `vendor.json`. Don't add `antnexo-swift` or `antnexo-android` to an app that uses this plugin.

## Requirements

Flutter 3.35+, iOS 15+, Android API 24+. On iOS the plugin works with CocoaPods and with Swift Package Manager; with
Swift Package Manager it needs Flutter 3.44+ (the first to generate the `FlutterFramework` package plugins depend on).

## Working on the plugin

`scripts/vendor.sh` updates the vendored SDKs to the tags in `vendor.json` (`--check` compares). Clone the repo into a
directory not named `antnexo-…` (e.g. `antnexo_flutter`): Flutter's Swift Package Manager integration can't resolve
the in-repo example from such a directory. Apps that depend on the plugin aren't affected.

MIT licence.
