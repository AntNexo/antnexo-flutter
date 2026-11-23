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
  s.swift_version = '5.9'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'antnexo_privacy' => ['antnexo/Sources/antnexo/PrivacyInfo.xcprivacy']}
end
