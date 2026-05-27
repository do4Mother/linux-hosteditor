# hosteditor

A Flutter desktop app for Linux that manages `/etc/hosts`-style hostname → IP redirects with a clean Material 3 dark UI. Edits are applied to the real `/etc/hosts` via a small privileged helper, so you type your password **at most once per app launch** instead of every time you reach for `sudo`.

## How it works

- The app stores hosts in `~/.config/hosteditor/hosts.json` (your source of truth).
- Active hosts are materialized into a managed block of `/etc/hosts`:
  ```
  # BEGIN hosteditor — DO NOT EDIT THIS BLOCK BY HAND
  10.0.0.1   api.dev.local
  192.168.1.5  db.staging.local
  # END hosteditor
  ```
- Everything outside the markers is left untouched. Manual edits to `localhost`, IPv6 boilerplate, etc. survive.
- The privileged `hosteditor-helper` runs as root via `pkexec` and stays alive for the session. Polkit caches your auth for ~5 min on top of that, so consecutive saves are silent.
- Inactive hosts stay in the app DB but are omitted from `/etc/hosts` entirely.

## Building from source

```bash
flutter pub get
cd helper && dart pub get && cd ..
make -C linux/packaging build
```

`make build` runs both `flutter build linux --release` and `dart compile exe` on the helper.

## Installing system-wide

```bash
sudo make -C linux/packaging install
```

This installs:

| Path | Purpose |
|---|---|
| `/usr/bin/hosteditor` | Flutter GUI |
| `/usr/libexec/hosteditor-helper` | Privileged helper (NOT setuid) |
| `/usr/share/polkit-1/actions/com.hosteditor.apply.policy` | Polkit action — pins privileged execution to the helper path |
| `/usr/share/applications/hosteditor.desktop` | Desktop menu entry |
| `/usr/share/hosteditor/data/`, `/usr/share/hosteditor/lib/` | Flutter bundle support files |

To uninstall: `sudo make -C linux/packaging uninstall`.

`PREFIX` and `DESTDIR` are both honored, so this works the same for distro packagers.

## Running in development

You don't need to install system-wide to develop. Point the GUI at a local helper build and a scratch DB:

```bash
HOSTEDITOR_HELPER_PATH="$PWD/helper/build/hosteditor-helper" \
HOSTEDITOR_DB_PATH=/tmp/hosteditor-dev.json \
flutter run -d linux
```

The first time you add or edit a host, polkit will prompt for your password. After that, no further prompts until you quit the app.

Environment variables:

| Variable | Used by | Effect |
|---|---|---|
| `HOSTEDITOR_HELPER_PATH` | GUI | Path to the helper binary. Default `/usr/libexec/hosteditor-helper`. |
| `HOSTEDITOR_DB_PATH` | GUI | Override the app DB location. Default `~/.config/hosteditor/hosts.json`. |
| `HOSTEDITOR_TARGET_HOSTS` | helper | Override the target hosts file (used by the helper's tests). Default `/etc/hosts`. |

## Tests

```bash
flutter test                           # Flutter side
flutter analyze                        # must be clean
(cd helper && dart test && dart analyze)   # helper side
```

The widget test sets a 1400x900 viewport. Helper tests run against temp files; they never touch the real `/etc/hosts`.

## Requirements

- Linux desktop with a polkit authentication agent running in your session. Every mainstream desktop (GNOME, KDE, Cinnamon, XFCE) ships one. Tiling WMs (Hyprland, Sway, i3) usually need `polkit-gnome` or equivalent installed and autostarted.
- `pkexec` on `PATH` (part of polkit).
- Flutter SDK with Linux desktop support enabled.
- Dart SDK ≥ 3.12.0.

## Project layout

```
lib/
  models/           Host, Env, Ping
  data/             initialHosts (test fixture only; not loaded at runtime)
  providers/        Riverpod state — see providers.dart
  services/         HostsFileWriter, HostStore, HelperClient, ApplyStatus
  theme/            Material 3 dark palette
  widgets/          One widget per file; barrel at widgets.dart

helper/             Standalone Dart project — the privileged side-car
  bin/              Entry point
  lib/              MarkerBlock, HostLineValidator, AtomicWriter
  test/

linux/packaging/    Polkit policy, .desktop entry, install Makefile
docs/superpowers/   Design spec + implementation plan
```
