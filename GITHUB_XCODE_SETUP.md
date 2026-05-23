# GitHub Xcode Build Setup

This repo includes `.github/workflows/ios-xcode.yml`.

## What Runs Automatically

Every push to `main` and every pull request runs an unsigned iOS Simulator build on a GitHub-hosted macOS 26 runner:

```bash
xcodebuild -project LeafDoctorAI.xcodeproj -scheme LeafDoctorAI -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO clean build
```

That catches compile errors without needing Apple signing assets.

## TestFlight Upload

To archive and upload to TestFlight from GitHub Actions, add these repository secrets in GitHub:

- `APPLE_TEAM_ID`
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_API_KEY_BASE64`
- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`

Then run the `iOS Xcode` workflow manually and set `upload_testflight` to `true`.

## Creating The Base64 Secrets

On a Mac, encode the App Store Connect API key, distribution certificate, and provisioning profile like this:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
base64 -i distribution.p12 | pbcopy
base64 -i LeafDoctorAI_AppStore.mobileprovision | pbcopy
```

Paste each copied value into the matching GitHub secret.

## App Store Connect API Key

Create the API key in App Store Connect:

1. Users and Access
2. Integrations
3. App Store Connect API
4. Generate an API key with App Manager access

Download the `.p8` file once, then base64 encode it for `ASC_API_KEY_BASE64`.

## Signing Assets

The TestFlight workflow expects:

- Apple Distribution certificate exported as `.p12`
- App Store provisioning profile for bundle ID `com.obankole.LeafDoctorAI`
- The same Apple Team ID used by the App Store Connect app

The simulator build does not require any of these secrets.
