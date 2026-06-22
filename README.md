# AI-Sentinel — Cybersecurity Command Center (Flutter)

A dark-themed, multi-screen Flutter dashboard mocking an AI-powered Network
Intrusion Detection System (NIDS), backed by a Gemini-powered SOC analyst
API. State is shared across screens via `provider` instead of being passed
through constructors.

## Structure

```
lib/
├── main.dart                       entry point: wires up Provider + theme
├── theme/
│   └── app_colors.dart             dark/neon color palette
├── models/
│   └── network_packet.dart         NetworkPacket, RiskStatus, DefenseMode
├── services/
│   ├── api_config.dart             backend base URL (overridable)
│   ├── soc_analyst_api.dart        HTTP client -> api_server.py /analyze
│   └── mock_data_generator.dart    fake packet generator + local fallback text
├── state/
│   └── sentinel_state.dart         ChangeNotifier: single source of truth
├── screens/
│   ├── root_shell.dart             bottom-nav shell (Live Feed / Critical Issues)
│   ├── dashboard_screen.dart       Live Feed tab (the original dashboard)
│   └── critical_issues_page.dart   NEW: persistent, searchable incident log
└── widgets/
    ├── metric_card.dart
    ├── packet_row.dart
    ├── status_badge.dart
    └── live_source_badge.dart
```

## State management

All shared data lives in `SentinelState` (`state/sentinel_state.dart`), a
`ChangeNotifier` provided at the root in `main.dart`:

```dart
ChangeNotifierProvider(
  create: (_) => SentinelState(),
  child: MaterialApp(home: const RootShell()),
)
```

Screens/widgets read it with `context.watch<SentinelState>()` (rebuilds on
change) or `context.read<SentinelState>()` (one-off calls, e.g. inside
`onTap`). This replaced an earlier version that manually threaded
`mode` / `onModeChanged` / `onCriticalPacket` through constructors — Provider
removes that prop-drilling entirely, and both tabs now read from exactly the
same source instead of getting their own copies.

`SentinelState` owns:
- the live packet stream (capped at 45, oldest drop off)
- the **critical issues log** (uncapped-ish, up to 300, persists until
  cleared) — this is what powers the new tab
- top-line metrics (total scanned, threats blocked, system health)
- the current defense mode
- a **shared Gemini analysis cache**, keyed by packet id — so if a packet
  is analyzed in one tab, the other tab reuses the same result instead of
  calling the API again

## Tabs

- **Live Feed** — the original dashboard: header, metrics, live packet
  table, and the "AI Threat Analysis Room" sidebar for the currently
  selected critical packet.
- **Critical Issues** (new) — every critical packet flagged this session,
  with a per-attack-type breakdown, a search box (filter by IP or attack
  type), and tap-to-expand cards that lazily fetch the same Gemini
  analysis used in the Live Feed.

## Run it

```bash
flutter pub get
flutter run -d chrome
```

Point it at your backend (see ../api_server.py) with:

```bash
flutter run -d chrome --dart-define=SOC_API_BASE_URL=http://localhost:8000
```

If the backend isn't reachable, every analysis silently falls back to a
local canned explanation (see `mock_data_generator.dart`) — you'll see a
cyan "LOCAL FALLBACK" badge instead of green "LIVE GEMINI" wherever that
happens.
