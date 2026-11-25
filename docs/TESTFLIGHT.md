# Our TestFlight build

Fork: https://github.com/stuV2/duo-desktop

Bundle ID: `com.stuv2.duodesktop`. Minimum iOS: 27.0.

Includes Mac screen sharing, SSH Terminal, Windows RDP, and JetKVM.
iCloud sync and unfinished basic VNC are off by default.

## Build

Install Xcode 27.2, XcodeGen, CMake, and Rust via rustup. Set a Rust default
toolchain before building. The scripts fetch and verify the upstream dependencies.

From `app/`, create `signing.local.env` (ignored by Git):

```sh
DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

Then run:

```sh
scripts/testflight.sh simulator
scripts/testflight.sh archive
```

## Upload

Sign into the paid developer team in Xcode. Create an iOS app record in App Store
Connect using `com.stuv2.duodesktop`, then run:

```sh
scripts/testflight.sh upload
```

Apple must finish processing the build before it becomes available in TestFlight.
Configure testers in App Store Connect. External testing may require beta review.
Increase `CURRENT_PROJECT_VERSION` in `app/project.yml` before each subsequent upload.

Signing details, generated projects, dependencies, archives, and export settings
stay local. Keep the bundled upstream licence notices intact.

For Mac connections, install the Duo Desktop fork's compatible Glass Act Host
as described in [INSTALL.md](INSTALL.md).
