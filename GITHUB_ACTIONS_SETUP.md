# GitHub Actions Setup (Android + iOS)

This project now includes a GitHub Actions workflow at:

`.github/workflows/mobile-release.yml`

It runs:

- Android release build (`.aab`) on Ubuntu
- iOS IPA build and TestFlight upload on macOS

## 1) Add required GitHub Secrets

In GitHub: **Repo -> Settings -> Secrets and variables -> Actions -> New repository secret**

Create these secrets:

- `IOS_BUNDLE_ID` (example: `com.yourcompany.kutoot`)
- `IOS_TEAM_ID` (Apple Developer Team ID)
- `IOS_CERTIFICATE_P12_BASE64` (base64 of Distribution certificate `.p12`)
- `IOS_CERTIFICATE_PASSWORD` (password used when exporting `.p12`)
- `IOS_PROVISION_PROFILE_BASE64` (base64 of App Store provisioning profile `.mobileprovision`)
- `APP_STORE_CONNECT_KEY_ID` (App Store Connect API key id)
- `APP_STORE_CONNECT_ISSUER_ID` (App Store Connect issuer id)
- `APP_STORE_CONNECT_PRIVATE_KEY` (contents of `AuthKey_XXXXXX.p8`)

## 2) How to generate base64 values (Windows PowerShell)

For certificate:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\certificate.p12"))
```

For provisioning profile:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\profile.mobileprovision"))
```

Copy the output and paste it into the corresponding GitHub secret.

## 3) Run the workflow

Open GitHub repo -> **Actions** -> **Mobile Release** -> **Run workflow**.

You can also trigger automatically by pushing to `main`.

## Notes

- Current Android build uses debug signing config from project settings. For Play Store release, add a production keystore signing config later.
- Current iOS workflow replaces the default bundle id (`com.example.kutootMobile`) during CI using `IOS_BUNDLE_ID`.
