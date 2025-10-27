# Code Signing Guide for Narro

This document explains how to set up code signing for building and distributing Narro.

## Table of Contents

- [Overview](#overview)
- [When Do You Need Code Signing?](#when-do-you-need-code-signing)
- [Local Development (No Signing)](#local-development-no-signing)
- [Distribution Builds (With Signing)](#distribution-builds-with-signing)
- [Setting Up Code Signing](#setting-up-code-signing)
- [GitHub Actions Setup](#github-actions-setup)
- [Troubleshooting](#troubleshooting)

## Overview

Code signing is Apple's mechanism to verify that software:
- Comes from a known, trusted source
- Has not been tampered with since it was signed
- Can be notarized and distributed outside the Mac App Store

**Good news:** Code signing is **optional** for local development and testing!

## When Do You Need Code Signing?

### ✅ You DON'T need code signing for:
- Local development builds
- Testing on your own machine
- Contributing to the project
- Building from source for personal use

### ⚠️ You DO need code signing for:
- Creating DMG files for distribution
- Notarizing the app with Apple
- Distributing to users outside the development team
- Publishing releases on GitHub

## Local Development (No Signing)

For development, you can build and run Narro without any certificates:

### Building in Xcode

1. Open `NarroApp.xcodeproj`
2. Select the "NarroApp" scheme
3. Choose "My Mac" as the destination
4. Press `⌘R` to build and run

Xcode will automatically use **ad-hoc signing** (local testing only).

### Building from Command Line

```bash
# Simple build without signing
xcodebuild \
  -project NarroApp.xcodeproj \
  -scheme NarroApp \
  -configuration Debug \
  build
```

### Creating DMG Without Signing

You can create a DMG for local testing without certificates:

```bash
# Run the build script with signing disabled
SKIP_SIGNING=true ./scripts/build-dmg.sh
```

Or use the flag:

```bash
./scripts/build-dmg.sh --skip-signing
```

**Note:** Unsigned DMGs will show Gatekeeper warnings on other Macs. Users will need to:
1. Right-click the app
2. Select "Open"
3. Click "Open" in the dialog

This is normal for unsigned apps and suitable for development/testing.

## Distribution Builds (With Signing)

For distribution, you need an Apple Developer account and proper certificates.

### Requirements

1. **Apple Developer Account** ($99/year)
   - Individual or Organization account
   - [Sign up here](https://developer.apple.com/programs/)

2. **Developer ID Application Certificate**
   - For signing Mac apps distributed outside the Mac App Store
   - Created in your Apple Developer account

3. **Developer ID Installer Certificate** (optional)
   - For signing installer packages
   - Not needed for DMG distribution

## Setting Up Code Signing

### Step 1: Join Apple Developer Program

1. Go to [Apple Developer Program](https://developer.apple.com/programs/)
2. Enroll as an individual or organization
3. Complete payment and verification (may take 1-2 days)

### Step 2: Create Certificates

1. Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click the "+" button to create a new certificate
3. Select "Developer ID Application"
4. Follow the instructions to create a Certificate Signing Request (CSR)
5. Upload the CSR and download your certificate
6. Double-click the certificate to install it in Keychain

### Step 3: Verify Certificate Installation

```bash
# List all Developer ID Application certificates
security find-identity -v -p codesigning

# You should see output like:
# 1) ABC123... "Developer ID Application: Your Name (TEAMID123)"
```

### Step 4: Set Your Team ID

Your Team ID is a 10-character string found in your Apple Developer account.

For local builds, you can set it as an environment variable:

```bash
export APPLE_TEAM_ID="YOUR_TEAM_ID"
./scripts/build-dmg.sh
```

Or edit `scripts/build-dmg.sh` and change the default:

```bash
APPLE_TEAM_ID="${APPLE_TEAM_ID:-"YOUR_TEAM_ID"}"
```

### Step 5: Create App-Specific Password (for Notarization)

Notarization requires an app-specific password:

1. Go to [Apple ID account page](https://appleid.apple.com/)
2. Sign in with your Apple ID
3. Under "Sign-In and Security", select "App-Specific Passwords"
4. Click "Generate an app-specific password"
5. Enter a label (e.g., "Narro Notarization")
6. Save the generated password securely

### Step 6: Build Signed DMG

```bash
# With all required environment variables
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_ID="your.email@example.com"
export APPLE_ID_PASSWORD="your-app-specific-password"

./scripts/build-dmg.sh
```

The script will:
1. Build the app as a universal binary
2. Sign the app bundle with your Developer ID
3. Create a DMG
4. Sign the DMG
5. Notarize with Apple (takes 2-15 minutes)
6. Staple the notarization ticket

## GitHub Actions Setup

To enable automated signed builds in GitHub Actions, you need to configure repository secrets.

### Step 1: Export Certificate

Export your Developer ID Application certificate as a `.p12` file:

```bash
# Export certificate from Keychain
# 1. Open Keychain Access
# 2. Select "My Certificates"
# 3. Find your "Developer ID Application" certificate
# 4. Right-click → Export
# 5. Save as .p12 with a password
```

Convert to base64:

```bash
base64 -i YourCertificate.p12 | pbcopy
```

### Step 2: Configure GitHub Secrets

Go to your repository settings → Secrets and variables → Actions → New repository secret:

Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | `MIIKuQIBAzCC...` |
| `P12_PASSWORD` | Password for the .p12 file | `your-p12-password` |
| `KEYCHAIN_PASSWORD` | Temporary keychain password (any string) | `temp-keychain-pass` |
| `APPLE_ID` | Your Apple ID email | `your.email@example.com` |
| `APPLE_ID_PASSWORD` | App-specific password | `abcd-efgh-ijkl-mnop` |
| `APPLE_TEAM_ID` | Your 10-character team ID | `ABC1234567` |

### Step 3: Trigger a Build

Push a tag to trigger a release build:

```bash
git tag v1.2.0
git push origin v1.2.0
```

Or manually trigger the workflow from the Actions tab.

### Optional: Skip Signing in CI

If you don't have certificates set up, GitHub Actions will automatically detect this and create unsigned builds. The workflow checks for certificate availability and adapts accordingly.

## Troubleshooting

### "No Developer ID Application certificate found"

**Cause:** Certificate not installed or Team ID mismatch

**Solution:**
1. Verify certificate installation: `security find-identity -v -p codesigning`
2. Check that your Team ID is correct
3. Ensure the certificate is valid (not expired)

### "User interaction is not allowed"

**Cause:** Keychain is locked or requires user interaction

**Solution:**
```bash
# Unlock keychain (development machine)
security unlock-keychain ~/Library/Keychains/login.keychain-db
```

For CI, this is handled automatically by the build script.

### "Notarization failed"

**Cause:** Various issues with app structure, signing, or Apple's notarization service

**Solution:**
1. Check notarization logs:
   ```bash
   xcrun notarytool log <submission-id> \
     --apple-id "your.email@example.com" \
     --password "your-app-specific-password" \
     --team-id "YOUR_TEAM_ID"
   ```
2. Common issues:
   - Expired certificates
   - Missing or invalid entitlements
   - Unsigned frameworks or libraries
   - Hardened runtime issues

### "The application cannot be opened"

**Cause:** Gatekeeper is blocking the app

**Solution:**
For unsigned apps:
```bash
# Remove quarantine attribute
xattr -cr /Applications/Narro.app
```

For signed apps: Should not occur if properly signed and notarized.

### Certificate Expired

Certificates expire after 5 years. You'll need to:
1. Create a new certificate in Apple Developer portal
2. Download and install the new certificate
3. Update GitHub secrets with the new certificate
4. Rebuild and re-sign all distributed apps

## Additional Resources

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Xcode Code Signing](https://help.apple.com/xcode/mac/current/#/dev3a05256b8)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## Questions?

If you run into issues:
1. Check the [GitHub Issues](https://github.com/d1egoaz/narro/issues)
2. Search for similar problems in the original [VTS repository](https://github.com/j05u3/VTS/issues)
3. Open a new issue with:
   - Your macOS version
   - Xcode version
   - Error messages (with sensitive info removed)
   - Steps you've already tried

## Contributing Without Signing

You can contribute to Narro without any code signing setup! Simply:

1. Fork the repository
2. Make your changes
3. Test locally with `SKIP_SIGNING=true ./scripts/build-dmg.sh`
4. Submit a pull request

The CI will build Debug versions for PRs automatically (no signing required).
