# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`hosteditor` is a Flutter desktop app (Material 3, dark theme) for managing `/etc/hosts`-style hostname → target redirects. Primary target platform is Linux desktop (see `linux/`). Dart SDK `^3.12.0`, Flutter with `flutter_riverpod ^2.6.1`.

## Commands

```bash
flutter pub get          # install deps
flutter run -d linux     # run desktop app
flutter analyze          # lint (must be clean — zero issues is the bar)
flutter test             # run widget tests
flutter test test/widget_test.dart --name "renders"  # single test by name
```

## Architecture

Entry point `lib/main.dart` is a 6-line bootstrap that wraps `HostEditorApp` in a `ProviderScope`. All app code lives under `lib/` organized by layer — **do not put logic in `main.dart`**.

```
lib/
  theme/app_colors.dart       AppColors palette + `mono` TextStyle
  models/host.dart            Host class, Env enum, EnvX extension (label/short/accent/container colors)
  models/ping.dart            Ping value object (status + latency)
  data/initial_hosts.dart     const seed list `initialHosts`
  providers/providers.dart    Riverpod state layer (see below)
  widgets/                    One widget per file + `widgets.dart` barrel
```

### State management (Riverpod)

All mutable state lives in `lib/providers/providers.dart`. Widgets read via `ConsumerWidget` / `ConsumerStatefulWidget` — **never lift state back into `setState` or pass it through 20+ constructor params**.

- `hostsProvider` (`NotifierProvider<HostsNotifier, List<Host>>`) — CRUD, toggle, bulk, duplicate. `deleteOne`/`deleteMany` return a backup list for undo-via-SnackBar; `restore(backup)` puts it back.
- `selectedProvider` — `Set<int>` of selected host ids for bulk actions.
- `pingsProvider` — `Map<int, Ping>`. `PingsNotifier` owns `Timer`s; lifecycle is tied to `ref.onDispose` (replaces a manual `dispose()`). Simulated latency 200–900ms, ~18% fail rate, auto-clears after 4.5s.
- `activeNavProvider`, `filterStatusProvider`, `searchProvider` — simple `StateProvider<String>`s.
- `filteredHostsProvider` — derived `Provider` that watches the four above and recomputes the visible list. Use this; do not refilter in widgets.

### Widget layer conventions

- One widget per file under `lib/widgets/`; re-exported via `widgets/widgets.dart`.
- Names of widgets that would shadow Material built-ins are prefixed `Host` (e.g. `HostCheckbox`, `HostFilterChip`, `HostSearchBar`).
- Dialogs and SnackBars require `BuildContext` — keep them in `ConsumerStatefulWidget`s (e.g. `HostEditorHome`), not in providers.
- Form inputs use Flutter's built-in `TextField` with the global `InputDecorationTheme` defined in `HostEditorApp`. There is no custom field wrapper — past attempts (`_M3Field`) were removed because the floating label didn't animate.

### Tests

`test/widget_test.dart` imports `HostEditorApp` from `lib/widgets/host_editor_app.dart` and must wrap it in a `ProviderScope` to construct. Any new test that pumps the app needs the same wrapper.
