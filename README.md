# LeafDoctor AI

LeafDoctor AI is a SwiftUI iOS app for plant disease detection, plant care scheduling, health history, analytics, achievements, PDF care reports, and subscription scaffolding.

Mock AI mode is enabled by default through `MockAIService`. `RemoteAIService` contains the secure backend placeholder:

```http
POST https://YOUR_BACKEND_URL.com/leafdoctor-ai
```

Never store API keys in the app. Put model/provider credentials behind a server endpoint.

## Build

Open `LeafDoctorAI.xcodeproj` in Xcode, select the `LeafDoctorAI` scheme, and run on an iOS 17+ simulator or device.

StoreKit product identifiers are placeholders:

- `leafdoctor.pro.monthly`
- `leafdoctor.pro.yearly`
- `leafdoctor.premium.lifetime`

Configure real products in App Store Connect before release.
