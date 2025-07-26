# 🚨 IMMEDIATE WORKAROUND: "VoiceInk is damaged" Error

## The Problem

You're seeing this error because the VoiceInk app was built **without Apple Developer code signing**. macOS is being overly protective of unsigned apps downloaded from the internet.

**Important**: The app is NOT actually damaged - this is just a security warning from macOS.

## ✅ Quick Fix (2 minutes)

### Method 1: Right-Click Override

1. **Download** VoiceInk.dmg from GitHub Actions
2. **Mount the DMG** by double-clicking it
3. **Drag VoiceInk.app** to your Applications folder
4. **Don't double-click the app yet!**
5. **Right-click** on VoiceInk.app in Applications
6. **Select "Open"** from the context menu
7. **Click "Open"** in the security dialog that appears
8. ✅ **VoiceInk will now launch successfully!**

### Method 2: Terminal Command (Advanced)

If you're comfortable with Terminal:

```bash
# Remove the quarantine attribute that causes the "damaged" error
xattr -d com.apple.quarantine /Applications/VoiceInk.app

# Now launch normally
open /Applications/VoiceInk.app
```

## 🔬 Technical Explanation

- **What's happening**: macOS adds a "quarantine" flag to downloaded files
- **Why it fails**: Unsigned apps with quarantine flags trigger strict security
- **The fix**: Right-clicking bypasses the quarantine check for that specific launch
- **After first launch**: macOS remembers your choice and allows normal launching

## 🚀 Long-term Solution

For production releases without these security warnings, we need to:

1. **Get Apple Developer Account** ($99/year)
2. **Add signing certificates** to GitHub secrets
3. **Enable automatic code signing** and notarization
4. **Distribute fully signed apps** that install without warnings

The infrastructure is already built - we just need the Apple Developer certificates!

## ✅ Verification

After following the workaround:
- VoiceInk should launch normally
- Future launches won't require the right-click method
- The app functions exactly the same as a signed version

## 📞 Need Help?

If the workaround doesn't work:
1. Check that you fully extracted the app from the DMG
2. Make sure you're right-clicking on the app in Applications (not in Downloads)
3. Look for any additional security dialogs that might need approval

The app **will work** once macOS trusts it! 🎉 