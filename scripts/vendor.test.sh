#!/usr/bin/env bash
# Checks scripts/vendor.sh: the vendored tree is what the tags give, imports of AntNexoCore are gone, every file has
# its header, and --check catches a hand edit. Run from the repo root after scripts/vendor.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
fail() { echo "vendor.test.sh: $*" >&2; exit 1; }

[[ -f ios/antnexo/Sources/antnexo/vendor/AntNexo/AntNexo.swift && -f ios/antnexo/Sources/antnexo/vendor/AntNexoCore/Bridge.swift ]] || fail "Swift sources missing"
[[ -f android/src/main/vendor/kotlin/com/antnexo/AntNexo.kt ]] || fail "Kotlin sources missing"
[[ -f android/src/main/vendor/res/values/strings.xml ]] || fail "Android resources missing"
grep -q 'com.antnexo.FeedbackActivity' android/src/main/AndroidManifest.xml || fail "manifest has no FeedbackActivity"
if grep -rqE 'import[[:space:]]+AntNexoCore|AntNexoCore\.' ios/antnexo/Sources/antnexo/vendor; then fail "AntNexoCore still referenced"; fi
while IFS= read -r -d '' f; do
  grep -q 'by scripts/vendor.sh. Do not edit.' "$f" || fail "no header in $f"
done < <(find ios/antnexo/Sources/antnexo/vendor android/src/main/vendor -type f \( -name '*.swift' -o -name '*.kt' -o -name '*.xml' \) -print0)
python3 -c 'import json,re,sys; v=json.load(open("vendor.json")); sys.exit(0 if all(re.fullmatch("[0-9a-f]{40}", v[k]["commit"]) for k in ("swift","android")) else 1)' ||
  fail "vendor.json lacks commits"

grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' ios/antnexo/Sources/antnexo/PrivacyInfo.xcprivacy &&
  grep -q 'CA92.1' ios/antnexo/Sources/antnexo/PrivacyInfo.xcprivacy || fail "privacy manifest lacks UserDefaults (CA92.1)"
grep -qE '^[[:space:]]*s\.resource_bundles.*PrivacyInfo\.xcprivacy' ios/antnexo.podspec || fail "podspec doesn't bundle the privacy manifest"
grep -qE '^[[:space:]]*\.process\("PrivacyInfo\.xcprivacy"\)' ios/antnexo/Package.swift || fail "Package.swift doesn't bundle the privacy manifest"

scripts/vendor.sh --check || fail "--check fails on a clean tree"

# A hand edit (and a dependency version that differs from the SDK's catalog) must be reported as such: --check's
# stderr names it, so a clone failure can't pass for a caught edit. Files are restored even when interrupted.
f=android/src/main/vendor/kotlin/com/antnexo/AntNexo.kt
g=android/build.gradle.kts
bak="$(mktemp -d)"
cp "$f" "$bak/f"
cp "$g" "$bak/g"
trap 'cp "$bak/f" "$f"; cp "$bak/g" "$g"; rm -rf "$bak"' EXIT
echo "// hand edit" >>"$f"
if err="$(scripts/vendor.sh --check 2>&1)"; then fail "--check missed a hand edit"; fi
grep -q 'android/src/main/vendor differs' <<<"$err" || fail "--check failed for another reason: $err"
cp "$bak/f" "$f"
sed -i.tmp 's/androidx.webkit:webkit:[0-9.]*/androidx.webkit:webkit:0.0.1/' "$g" && rm -f "$g.tmp"
if err="$(scripts/vendor.sh --check 2>&1)"; then fail "--check missed a dependency version"; fi
grep -q 'androidx.webkit:webkit' <<<"$err" || fail "--check failed for another reason: $err"
cp "$bak/g" "$g"
scripts/vendor.sh --check || fail "--check fails after restoring"
echo "vendor.test.sh: ok"
