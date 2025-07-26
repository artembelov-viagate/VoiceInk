# Building VoiceInk for macOS

This guide explains how to build and distribute VoiceInk for macOS with proper code signing and notarization to avoid "app is damaged" warnings.

## Overview

VoiceInk uses GitHub Actions to automatically build, code sign, and notarize the macOS app. The built app will be trusted by macOS Gatekeeper and can be distributed directly to users without the App Store.

## Prerequisites

### 1. Apple Developer Account

- An active Apple Developer Program membership ($99/year)
- Access to [Apple Developer Console](https://developer.apple.com/account/)

### 2. Required Certificates

You need a **Developer ID Application** certificate to sign apps for distribution outside the Mac App Store.

#### Creating the Certificate

1. Go to [Apple Developer Console > Certificates](https://developer.apple.com/account/resources/certificates/)
2. Click the "+" button to create a new certificate
3. Select **Developer ID Application** under "Production"
4. Generate a Certificate Signing Request (CSR):
   ```bash
   # On your Mac, open Keychain Access
   # Go to Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
   # Enter your email and name, select "Saved to disk"
   ```
5. Upload the CSR file and download the certificate
6. Double-click the certificate to install it in your Keychain

#### Exporting the Certificate

1. Open Keychain Access on your Mac
2. Find your "Developer ID Application" certificate
3. Right-click and select "Export..."
4. Save as `.p12` format with a strong password
5. Convert to base64 for GitHub secrets:
   ```bash
   base64 -i YourCertificate.p12 | pbcopy
   ```

### 3. App-Specific Password

Create an app-specific password for notarization:

1. Go to [Apple ID account page](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID
3. In the "Security" section, click "Generate Password..."
4. Label it "VoiceInk Notarization" and copy the generated password

### 4. Team ID

Find your Team ID:
1. Go to [Apple Developer Console > Membership](https://developer.apple.com/account/#!/membership/)
2. Your Team ID is listed (10-character alphanumeric string)

## GitHub Repository Setup

### Required Secrets

Add these secrets to your GitHub repository at `Settings > Secrets and variables > Actions`:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | (Long base64 string) |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the .p12 certificate | `your-cert-password` |
| `APPLE_KEYCHAIN_PASSWORD` | Password for temporary keychain | `temp-keychain-pass` |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID | `ABCD123456` |
| `CODE_SIGN_IDENTITY` | Full name of your signing identity | `Developer ID Application: Your Name (ABCD123456)` |
| `APPLE_ID` | Your Apple ID email | `your-email@example.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password for notarization | `abcd-efgh-ijkl-mnop` |

### Finding Your Code Sign Identity

To find the exact identity name:
```bash
security find-identity -v -p codesigning
```

Look for something like: `Developer ID Application: Your Name (TEAM_ID)`

## Local Development

### Building Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/VoiceInk.git
   cd VoiceInk
   ```

2. **Install Xcode 16.4+ and command line tools:**
   ```bash
   xcode-select --install
   ```

3. **Build whisper.cpp framework:**
   ```bash
   cd ..
   git clone https://github.com/ggerganov/whisper.cpp.git
   cd whisper.cpp
   chmod +x ./build-xcframework.sh
   ./build-xcframework.sh
   cd ../VoiceInk
   ```

4. **Open in Xcode:**
   ```bash
   open VoiceInk.xcodeproj
   ```

5. **Configure signing in Xcode:**
   - Select the VoiceInk target
   - Go to "Signing & Capabilities"
   - Ensure your Team is selected
   - Code signing identity should be "Apple Development" for local builds

### Local Signing for Distribution

For local distribution builds, you can manually sign and notarize:

```bash
# Build the app
xcodebuild -project VoiceInk.xcodeproj \
           -scheme VoiceInk \
           -configuration Release \
           -derivedDataPath ./DerivedData \
           OTHER_CODE_SIGN_FLAGS="--options=runtime" \
           clean build

# Create archive for notarization
ditto -c -k --keepParent "./DerivedData/Build/Products/Release/VoiceInk.app" "VoiceInk.zip"

# Submit for notarization
xcrun notarytool submit "VoiceInk.zip" \
  --apple-id "your-apple-id@example.com" \
  --password "your-app-specific-password" \
  --team-id "YOUR_TEAM_ID" \
  --wait

# Staple the notarization
xcrun stapler staple "./DerivedData/Build/Products/Release/VoiceInk.app"

# Create DMG
mkdir dmg-staging
cp -R "./DerivedData/Build/Products/Release/VoiceInk.app" dmg-staging/
hdiutil create -volname "VoiceInk" -srcfolder dmg-staging -ov -format UDZO VoiceInk.dmg

# Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
         --options=runtime \
         --verbose \
         VoiceInk.dmg
```

## CI/CD Workflow

### How It Works

The GitHub Actions workflow (`.github/workflows/build.yml`) automatically:

1. **Sets up the build environment** with Xcode 16.4
2. **Configures code signing** using the certificates from secrets
3. **Builds whisper.cpp framework** as a dependency
4. **Resolves Swift Package dependencies**
5. **Builds the VoiceInk app** with proper signing and hardened runtime
6. **Verifies the code signature**
7. **Notarizes the app** with Apple
8. **Staples the notarization** to the app
9. **Creates a signed DMG** for distribution
10. **Uploads the DMG** as a build artifact

### Conditional Behavior

- **Pull Requests**: Builds without signing (for testing)
- **Main Branch**: Full signing and notarization process

### Triggering a Build

Push to the main branch or create a pull request to trigger the build:

```bash
git push origin main
```

The signed and notarized DMG will be available as a downloadable artifact in the GitHub Actions run.

## Security Considerations

1. **Certificate Security**: The .p12 certificate contains your private key. Keep it secure and never commit it to version control.

2. **Secret Management**: GitHub secrets are encrypted and only accessible during workflow runs.

3. **Hardened Runtime**: The app is built with hardened runtime enabled for additional security.

4. **Notarization**: Apple scans the app for malicious content before approving it.

## Troubleshooting

### Common Issues

1. **"Developer cannot be verified" error**
   - Ensure the app is properly signed and notarized
   - Check that all secrets are correctly set in GitHub

2. **Code signing fails**
   - Verify your certificate is valid and not expired
   - Ensure the certificate password is correct
   - Check that the CODE_SIGN_IDENTITY matches exactly

3. **Notarization fails**
   - Verify your Apple ID and app-specific password
   - Ensure your Apple Developer account is in good standing
   - Check that hardened runtime is enabled

4. **"App is damaged" warning**
   - This happens when the app is not properly signed/notarized
   - Re-download the app from the official source
   - Check the notarization status

### Debug Commands

```bash
# Check code signature
codesign -dv --verbose=4 VoiceInk.app

# Verify signature
codesign --verify --deep --strict VoiceInk.app

# Check notarization
xcrun stapler validate VoiceInk.app

# Remove quarantine (for testing only)
xattr -d com.apple.quarantine VoiceInk.app
```

## Distribution

The built DMG can be distributed:
- Directly to users via download links
- Through your website
- Via release assets on GitHub

Users will be able to install and run the app without security warnings.

## References

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Apple Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference) 