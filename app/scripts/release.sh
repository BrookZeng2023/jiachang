#!/usr/bin/env bash
# Archive the app and upload it to TestFlight with Xcode's own tools.
#
# One-time setup:
#   1. Create the app record in App Store Connect (bundle id io.github.BrookZeng2023.jiachang).
#   2. Sign into Xcode with the owning team, or configure an API key with signing access.
#   3. Copy scripts/release.env.example to release.local.env next to project.yml and fill it in.
#   4. In TestFlight, give the internal group automatic distribution.
#
# Usage: scripts/release.sh [--skip-tests]
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="/opt/homebrew/bin:$PATH"

skip_tests=false
case "${1:-}" in
  "") ;;
  --skip-tests) skip_tests=true ;;
  *) echo "Usage: scripts/release.sh [--skip-tests]" >&2; exit 1 ;;
esac
[[ $# -le 1 ]] || { echo "Too many arguments" >&2; exit 1; }
command -v xcodegen >/dev/null || { echo "xcodegen is required" >&2; exit 1; }

[[ -f release.local.env ]] || {
  echo "release.local.env is missing; copy scripts/release.env.example and fill it in" >&2
  exit 1
}
# shellcheck disable=SC1091
source release.local.env
[[ -n "${DEVELOPMENT_TEAM:-}" ]] || { echo "DEVELOPMENT_TEAM is not set" >&2; exit 1; }
auth_args=(-allowProvisioningUpdates)
case "${RELEASE_AUTH:-xcode}" in
  xcode) ;; # Uses the account already signed into Xcode; no API key needed.
  api)
    for name in ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH; do
      [[ -n "${!name:-}" ]] || { echo "$name is not set in release.local.env" >&2; exit 1; }
    done
    [[ -f "$ASC_KEY_PATH" ]] || { echo "API key not found at $ASC_KEY_PATH" >&2; exit 1; }
    auth_args+=(-authenticationKeyPath "$ASC_KEY_PATH"
      -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
    ;;
  *) echo "RELEASE_AUTH must be xcode or api" >&2; exit 1 ;;
esac

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes; commit first so the build number maps to a commit" >&2
  exit 1
fi

if ! $skip_tests; then
  scripts/check.sh
fi

xcodegen generate >/dev/null
build_number=${RELEASE_BUILD_NUMBER:-$(git rev-list --count HEAD)}
[[ "$build_number" =~ ^[1-9][0-9]{0,3}$ ]] || {
  echo "RELEASE_BUILD_NUMBER must be an integer from 1 to 9999" >&2; exit 1;
}
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' jiachang/Info.plist)
output="${RELEASE_OUTPUT_DIR:-$HOME/Brook/Local/jiachang/releases}/$version-$build_number"
mkdir -p "$(dirname "$output")"
mkdir "$output" || { echo "Release directory already exists; use a new build number" >&2; exit 1; }
echo "Releasing $version ($build_number) -> $output"
git rev-parse HEAD > "$output/commit.txt"
archive="$output/jiachang.xcarchive"
if ! xcodebuild archive \
  -project jiachang.xcodeproj \
  -scheme jiachang \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$archive" \
  "${auth_args[@]}" \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
  CURRENT_PROJECT_VERSION="$build_number" \
  > "$output/archive.log" 2>&1
then
  grep -E "error:|ARCHIVE FAILED" "$output/archive.log" >&2 || true
  echo "Archive failed; see $output/archive.log" >&2
  exit 1
fi

# Read back what was actually built before anything leaves this Mac.
app="$archive/Products/Applications/jiachang.app"
built_version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Info.plist")
built_build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$app/Info.plist")
built_bundle=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$app/Info.plist")
[[ "$built_version" == "$version" && "$built_build" == "$build_number" ]] || {
  echo "Archive reports $built_version ($built_build), expected $version ($build_number)" >&2
  exit 1
}
[[ "$built_bundle" == "io.github.BrookZeng2023.jiachang" ]] || {
  echo "Unexpected bundle identifier: $built_bundle" >&2
  exit 1
}
echo "Archived $built_bundle $built_version ($built_build)"

sed "s/TEAM_ID/$DEVELOPMENT_TEAM/" scripts/ExportOptions.plist > "$output/ExportOptions.plist"
if ! xcodebuild -exportArchive \
  -archivePath "$archive" \
  -exportOptionsPlist "$output/ExportOptions.plist" \
  -exportPath "$output/export" \
  "${auth_args[@]}" \
  > "$output/upload.log" 2>&1
then
  grep -E "error:|EXPORT FAILED" "$output/upload.log" >&2 || true
  echo "Upload failed; see $output/upload.log" >&2
  exit 1
fi
grep -q "EXPORT SUCCEEDED" "$output/upload.log" || {
  echo "Upload did not report success; see $output/upload.log" >&2
  exit 1
}

tag="build/$version-$build_number"
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "Tag $tag already exists; leaving it unchanged"
else
  git tag "$tag"
fi
echo "Uploaded $version ($build_number). TestFlight processes it in a few minutes; tagged $tag."
