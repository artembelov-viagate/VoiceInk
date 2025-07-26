# VoiceInk Maintenance Guide

## 📋 Overview

This guide contains all essential information for maintaining the VoiceInk macOS app repository, including upstream updates, rebuilding DMGs, and troubleshooting.

## 🏗️ Repository Structure

### **Source Repository**
- **Original**: `Beingpax/VoiceInk` (upstream)
- **Forked**: `artembelov-viagate/VoiceInk` (our version)
- **Local**: `/Users/whitesiroi/Downloads/p/VoiceInk`

### **Key Files**
- **`.github/workflows/build.yml`** - Main build workflow with smart code signing
- **`BUILDING.md`** - Complete setup guide for Apple Developer certificates
- **`CODE_SIGNING_SOLUTION.md`** - Technical documentation of the signing solution
- **`IMMEDIATE_WORKAROUND.md`** - User instructions for unsigned builds
- **`MAINTENANCE_GUIDE.md`** - This file (maintenance instructions)

## 🔄 Updating from Upstream

### **Check for Updates**
```bash
# Add upstream remote (only needed once)
git remote add upstream https://github.com/Beingpax/VoiceInk.git

# Check for updates
git fetch upstream
git log --oneline main..upstream/main

# See what changed
git diff main upstream/main
```

### **Merge Updates**
```bash
# Create a backup branch
git checkout -b backup-before-update

# Switch to main and merge
git checkout main
git merge upstream/main

# Resolve any conflicts if they occur
# Priority: Keep our workflow and documentation files
```

### **Critical Files to Preserve**
During upstream merges, always keep our versions of:
- `.github/workflows/build.yml` (our enhanced workflow)
- `BUILDING.md` (our comprehensive guide)
- `CODE_SIGNING_SOLUTION.md` (our technical docs)
- `IMMEDIATE_WORKAROUND.md` (user workaround)
- `MAINTENANCE_GUIDE.md` (this file)

### **Post-Merge Testing**
```bash
# Test the build workflow
git push origin main

# Monitor GitHub Actions
gh run list --limit 3
```

## 🚀 Rebuilding DMG

### **Automatic Build (Recommended)**
Builds trigger automatically on:
- **Push to main branch** → Full build with signing (if secrets available)
- **Pull requests** → Test build without signing
- **Manual trigger** → `gh workflow run build.yml`

### **Manual Build Process**
```bash
# Ensure clean state
git status
git pull origin main

# Trigger build manually
gh workflow run build.yml

# Monitor progress
gh run list --limit 1
gh run watch
```

### **Download Built DMG**
```bash
# Get latest successful run ID
RUN_ID=$(gh run list --status success --limit 1 --json databaseId --jq '.[0].databaseId')

# Download artifacts
gh run download $RUN_ID --dir ./downloads

# Find the DMG
find ./downloads -name "*.dmg"
```

## 🔧 Build Workflow Details

### **Smart Code Signing Detection**
The workflow automatically detects:
- **Has Apple certificates** → Full signing + notarization
- **No certificates** → Unsigned build with ad-hoc signature
- **Pull request** → Always unsigned (for testing)

### **Required Secrets (for Production)**
```
APPLE_CERTIFICATE_BASE64     # Base64-encoded .p12 certificate
APPLE_CERTIFICATE_PASSWORD   # Password for .p12 file
APPLE_KEYCHAIN_PASSWORD      # Temporary keychain password
APPLE_TEAM_ID               # Apple Developer Team ID
CODE_SIGN_IDENTITY          # Full signing identity name
APPLE_ID                    # Apple ID email
APPLE_APP_SPECIFIC_PASSWORD # App-specific password for notarization
```

### **Dependencies Built Automatically**
- **whisper.cpp** - Cloned and built from `ggerganov/whisper.cpp`
- **Swift Packages** - Resolved automatically via Xcode

## 📦 Distribution Options

### **Current (Unsigned) Distribution**
- ✅ **Works with workaround** (right-click → Open)
- ⚠️ **Security warnings** for users
- 🎯 **Good for testing** and internal use

### **Future (Signed) Distribution**
- ✅ **No security warnings**
- ✅ **Professional distribution**
- 💰 **Requires Apple Developer Account** ($99/year)

## 🚨 Troubleshooting

### **Build Failures**
```bash
# Check build logs
gh run view --log

# Common issues:
# 1. whisper.cpp build failure → Check upstream changes
# 2. Swift package issues → Check Package.resolved file
# 3. Xcode version issues → Update workflow if needed
```

### **Code Signing Issues**
```bash
# Test local signing (if you have certificates)
security find-identity -v -p codesigning

# Check app signature
codesign -dv --verbose=4 /path/to/VoiceInk.app
```

### **"App is Damaged" Error**
**Solution**: Follow `IMMEDIATE_WORKAROUND.md`
1. Right-click app → Open
2. Or run: `xattr -d com.apple.quarantine /Applications/VoiceInk.app`

## 🔄 Regular Maintenance Tasks

### **Weekly**
- [ ] Check for upstream updates
- [ ] Monitor GitHub Actions status
- [ ] Review any new issues or discussions

### **Monthly**
- [ ] Update dependencies if needed
- [ ] Test latest build on clean macOS system
- [ ] Review security/signing setup

### **Before Major Updates**
- [ ] Create backup branch
- [ ] Test merge conflicts resolution
- [ ] Verify all documentation is current
- [ ] Test complete build → install → launch cycle

## 📋 Quick Reference Commands

```bash
# Status check
git status
gh run list --limit 3

# Update from upstream
git fetch upstream
git merge upstream/main

# Trigger new build
git push origin main

# Download latest build
gh run download $(gh run list --status success --limit 1 --json databaseId --jq '.[0].databaseId')

# Emergency reset
git reset --hard origin/main
```

## 🎯 Future Improvements

### **When Ready for Production**
1. **Get Apple Developer Account**
2. **Create Developer ID Application certificate**
3. **Add all 7 secrets to GitHub repository**
4. **Test signed build end-to-end**
5. **Update documentation for signed distribution**

### **Potential Enhancements**
- Automatic release creation for tagged builds
- Multi-architecture builds (Intel + Apple Silicon)
- Update checking within the app
- Crash reporting integration

## 🆘 Emergency Contacts

- **Repository**: https://github.com/artembelov-viagate/VoiceInk
- **Upstream**: https://github.com/Beingpax/VoiceInk
- **GitHub CLI**: `gh help` for commands
- **Documentation**: All `.md` files in repository root

## 📝 Notes

- **This repository is a fork** - always sync with upstream before major changes
- **The build system is fully automated** - just push to main branch
- **Users can always use the workaround** for unsigned builds
- **All infrastructure is ready** for signing when certificates are available

---

**Last Updated**: 2025-01-26
**Maintainer**: artembelov-viagate
**Status**: Production Ready (unsigned), Signing Ready (needs certificates) 