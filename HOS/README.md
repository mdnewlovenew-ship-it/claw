# HOS — Health OS (Native iOS)

Personal health / context operating system prototype for iPhone.

## Requirements

- Xcode 15.4+ (iOS 17 SDK)
- Physical iPhone recommended (Motion, HealthKit, mic, battery)
- Apple Developer account (free works for most sensors; HealthKit on device needs a team)

## Open & Run

1. Open `HOS.xcodeproj` in Xcode
2. Select the **HOS** scheme and your physical iPhone
3. Set your **Team** under Signing & Capabilities
4. Enable the **HealthKit** capability if Xcode did not pick up `HOS.entitlements`
5. Build and Run (⌘R)

## Architecture

```
HOS/
  App/           HOSApp, AppState
  Models/        SensorSnapshot, MotionState, VoiceMetrics, HealthSnapshot, ContextEvent
  Services/      Permissions, HealthKit, Motion, Location, Audio, Camera, Notifications, Battery, Device, Storage
  Views/         Dashboard, Permissions, Sensors, Voice, Health, Activity, Timeline, Settings
  Components/    MetricCard, PermissionRow, StatusIndicator
```

Local-first. No backend. No analytics. Permissions are request-on-tap only.

## Manual Xcode capability

- **HealthKit** — already listed in `HOS.entitlements`; confirm it appears under Signing & Capabilities.

## Privacy

MVP data stays on device (Documents + HealthKit read). No cloud upload.
