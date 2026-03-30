# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test

This is a Swift Package (UIKit, iOS 14+). Cannot use `swift build` directly — UIKit requires iOS SDK.

```bash
# Build
xcodebuild -scheme ScheduleView -destination 'generic/platform=iOS' build

# Run tests
xcodebuild -scheme ScheduleView -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

Swift Package library in `Sources/ScheduleView/`:

- **ScheduleEvent.swift** — `IScheduleEvent` protocol (requires only `start`/`end`).
- **EventLayoutCalculator.swift** — `EventLayout`, `layoutEvents()` (overlap clustering + greedy column assignment), `calculateEventFrames()` (pure function for frame calculation).
- **ScheduleConfig.swift** — `ScheduleConfig` (event layout params) + `TimelineConfig` (timeline params, ISP).
- **DayScheduleView.swift** — Generic `DayScheduleView<Event>` UIView. Supports `DisplayMode.standalone` (with timeline) and `.embedded` (without). Caller provides `viewForEvent` closure and `onEventTapped` callback.
- **WeekScheduleView.swift** — Composes 7 `DayScheduleView` instances via UIStackView. Uses `EventDayResolver` (injectable) for day splitting.
- **EventDayResolver.swift** — `EventDayResolver<Event>` splits multi-day/cross-midnight events into per-day `DaySlice<Event>` segments, timezone-aware.
- **TimelineView.swift** — Internal hour grid rendering.

## Key Design Decisions

- Day boundaries are 00:00–23:59 (not 00:00–00:00). A full-day slice runs from 00:00 to 23:59.
- View does NO filtering — caller is responsible for passing only events for the target day (use `EventDayResolver`).
- `viewForEvent` closure controls event appearance — protocol has no color/title requirements, only time. This supports different calendar backends (EAS, EWS, CalDAV) without coupling to a specific model.
- `EventLayout`, `layoutEvents()` and `calculateEventFrames()` are internal — only `IScheduleEvent`, `ScheduleConfig`, `TimelineConfig`, `DayScheduleView`, `WeekScheduleView`, `DaySlice`, and `EventDayResolver` are public API.
- Протоколы (интерфейсы) именуются с префиксом `I`: `IScheduleEvent`, не `ScheduleEventRepresentable`.
- Language: project uses Russian for comments and documentation.
- Unit-тесты обязательны для всего: любой новый код, изменение существующего, баг-фикс — всё должно сопровождаться тестами в `Tests/ScheduleViewTests/`.
