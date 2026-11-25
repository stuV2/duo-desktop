#!/bin/sh
# Reproducible fork build. Signing values stay in an ignored local file.
set -eu
app=$(cd "$(dirname "$0")/.." && pwd)
cd "$app"
[ ! -f signing.local.env ] || . ./signing.local.env
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export DUO_TERMINAL=YES DUO_JETKVM=YES DUO_RDP=YES DUO_VNC=NO
export DUO_SYNC="${DUO_SYNC:-NO}"
action=${1:-generate}
case "$action" in
  generate|simulator|archive|upload) ;;
  *) echo 'Usage: scripts/testflight.sh [generate|simulator|archive|upload]' >&2; exit 2 ;;
esac
if [ "$action" != upload ]; then
  scripts/fetch-glassact.sh
  scripts/build-freerdp.sh
  xcodegen generate
fi
case "$action" in
  generate) exit 0 ;;
  simulator)
    exec xcodebuild -project DuoDesktop.xcodeproj -scheme DuoDesktop \
      -destination 'generic/platform=iOS Simulator' -derivedDataPath build/testflight \
      -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build ;;
  archive)
    : "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM in app/signing.local.env}"
    exec xcodebuild -project DuoDesktop.xcodeproj -scheme DuoDesktop \
      -configuration Release -destination 'generic/platform=iOS' \
      -derivedDataPath build/testflight -archivePath build/DuoDesktop.xcarchive \
      -allowProvisioningUpdates -skipPackagePluginValidation \
      DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" archive ;;
  upload)
    : "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM in app/signing.local.env}"
    [ -d build/DuoDesktop.xcarchive ] || { echo 'Run archive first.' >&2; exit 1; }
    /usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:CFBundleIdentifier' \
      build/DuoDesktop.xcarchive/Info.plist
    python3 - "$DEVELOPMENT_TEAM" <<'PY'
import plistlib, sys
with open('build/ExportOptions.plist', 'wb') as f:
    plistlib.dump({'method': 'app-store-connect', 'destination': 'upload',
                  'teamID': sys.argv[1], 'signingStyle': 'automatic',
                  'uploadSymbols': True, 'manageAppVersionAndBuildNumber': False}, f)
PY
    exec xcodebuild -exportArchive -archivePath build/DuoDesktop.xcarchive \
      -exportOptionsPlist build/ExportOptions.plist -exportPath build/export \
      -allowProvisioningUpdates ;;
esac
