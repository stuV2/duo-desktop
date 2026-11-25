#!/bin/sh
# Checks a BUILT Duo Desktop .app for every notice About shows (plan §9, M4 acceptance; the reviewer: "Verify the
# actual built About bundle"). Usage: scripts/verify-about-bundle.sh path/to/DuoDesktop.app
set -u
APP="${1:?usage: verify-about-bundle.sh DuoDesktop.app}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GA="$HERE/../vendor/glassact"
fail=0
check() { # file, text that must be in it
  if [ ! -f "$APP/$1" ]; then echo "MISSING  $1"; fail=1; return; fi
  if grep -qF -- "$2" "$APP/$1"; then echo "ok       $1: $2"; else echo "ABSENT   $1: $2"; fail=1; fi
}
same() { # bundled file, source file
  if cmp -s "$APP/$1" "$2"; then echo "ok       $1 = $(basename "$2") at the pin"; else echo "DIFFERS  $1"; fail=1; fi
}
check Acknowledgements.txt "# Glass Act"
check Acknowledgements.txt "Copyright (c) 2026 Brian Lopez"
check Acknowledgements.txt "# libwebp 1.5.0"
check Acknowledgements.txt "Additional IP Rights Grant (Patents)"
check Acknowledgements.txt "# libaom"
check Acknowledgements.txt "Alliance for Open Media Patent License 1.0"
check Acknowledgements.txt "# av1gpu"
check GlassActLICENSE.txt "MIT License"
check RustAV1ThirdPartyNotices.md "# Third-party notices"
check RustAV1ThirdPartyNotices.md "## libaom (Alliance for Open Media)"
check RustAV1ThirdPartyNotices.md "## AV1 patents"
check DuoDesktopNotice.txt "Apps/iPad/SessionModel.swift and Apps/iPad/CanvasView.swift"
check DuoDesktopNotice.txt "Permission is hereby granted"
check GLASSACT_COMMIT "$(cat "$HERE/GLASSACT_COMMIT")"
same Acknowledgements.txt "$GA/Apps/Shared/Acknowledgements.txt"
same GlassActLICENSE.txt "$GA/LICENSE"
same RustAV1ThirdPartyNotices.md "$GA/rust/av1/THIRD_PARTY_NOTICES.md"
# The Remote Desktop build (DUO_RDP) only: FreeRDP's and OpenSSL's licences, as the pinned sources have them.
if [ -f "$APP/RemoteDesktopNotice.txt" ]; then
  check RemoteDesktopNotice.txt "== FreeRDP 3.33.1 =="
  check RemoteDesktopNotice.txt "== OpenSSL 3.6.5 =="
  check RemoteDesktopNotice.txt "Alexander Peslyak"
  for l in "$HERE/../vendor/freerdp-build/FreeRDP-LICENSE.txt" "$HERE/../vendor/freerdp-build/OpenSSL-LICENSE.txt"; do
    if [ -f "$l" ] && python3 -c 'import sys; sys.exit(open(sys.argv[1]).read() not in open(sys.argv[2]).read())' "$l" "$APP/RemoteDesktopNotice.txt"
    then echo "ok       RemoteDesktopNotice.txt carries $(basename "$l") whole"; else echo "ABSENT   $(basename "$l")"; fail=1; fi
  done
fi
# The Basic Screen Sharing build (DUO_VNC) only: RoyalVNCKit's licence (our copy) and CryptoSwift's, whole.
if [ -f "$APP/BasicScreenSharingNotice.txt" ]; then
  check BasicScreenSharingNotice.txt "== RoyalVNCKit (commit $(cat "$HERE/../royalvnc/ROYALVNC_COMMIT")) =="
  check BasicScreenSharingNotice.txt "== CryptoSwift 1.9.0 =="
  check BasicScreenSharingNotice.txt "This product includes software developed by the \"Marcin Krzyzanowski\""
  check BasicScreenSharingNotice.txt "Olivetti & Oracle Research Laboratory"
  if python3 -c 'import sys; sys.exit(open(sys.argv[1]).read() not in open(sys.argv[2]).read())' "$HERE/../royalvnc/LICENSE" "$APP/BasicScreenSharingNotice.txt"
  then echo "ok       BasicScreenSharingNotice.txt carries RoyalVNCKit's LICENSE whole"; else echo "ABSENT   RoyalVNCKit LICENSE"; fail=1; fi
fi
# The copied source files still carry their MIT header.
for f in SessionModel.swift CanvasView.swift; do
  if head -4 "$HERE/DuoDesktop/$f" | sed 's|^// *||' | tr '\n' ' ' | grep -Eq 'MIT[[:space:]]+licensed'; then echo "ok       source header: $f"
  else echo "ABSENT   source header: $f"; fail=1; fi
done
[ $fail -eq 0 ] && echo "PASS: every notice is in the built app" || echo "FAIL"
exit $fail
