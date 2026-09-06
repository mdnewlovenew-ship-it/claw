# HOS — Health OS (iOS)

Native SwiftUI iPhone app. Local-first personal health / context prototype.

## Requirements

- Xcode 15+
- iOS 17+
- Physical iPhone recommended (HealthKit, Motion, Camera, Mic)

## Open

1. Open `HOS.xcodeproj` in Xcode
2. Select the **HOS** target
3. Set your Team under Signing & Capabilities
4. Enable **HealthKit** capability if Xcode does not pick up `HOS.entitlements`
5. Run on a connected iPhone

## Privacy

Permissions are requested only when you tap Request on the Permissions screen (or an explicit feature button). MVP data stays on device — no cloud, ads, or analytics SDK.
