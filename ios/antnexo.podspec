#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint antnexo.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'antnexo'
  s.version          = '1.0.0'
  s.summary          = 'In-app feedback for Flutter apps: the AntNexo board in a native sheet.'
  s.description      = <<-DESC
In-app feedback for Flutter apps: the AntNexo board in a native sheet.
                       DESC
  s.homepage         = 'https://github.com/AntNexo/antnexo-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AntNexo' => 'hello@antnexo.com' }
  s.source           = { :path => '.' }
  # vendor/: the Swift SDK's sources at the tag in vendor.json (scripts/vendor.sh), compiled into this pod's module.
  s.source_files = 'antnexo/Sources/antnexo/**/*.swift'
  s.frameworks = 'WebKit', 'AuthenticationServices', 'SafariServices', 'CryptoKit'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '6.0'

  # The SDK reads UserDefaults (What's new read state): declared in the privacy manifest.
  s.resource_bundles = {'antnexo_privacy' => ['antnexo/Sources/antnexo/PrivacyInfo.xcprivacy']}
end
