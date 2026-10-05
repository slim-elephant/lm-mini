# iOS Control Center Widget Setup

This guide explains how to add the Control Center widgets for LM Mini in Xcode.

## Prerequisites

- Xcode 16+ (required for Control Center widgets - iOS 18+)
- iOS 18+ deployment target for the widget extension

## ✅ Completed Steps

Steps 1-2 have been completed (project opened, widget extension target added).

## Remaining Steps

### Step 3: Configure Widget Target Settings

1. Select the **LMWidgetExtensionExtension** target in Xcode
2. Go to **General** tab:
   - Verify **Bundle Identifier**: `net.neuro9.lmmini.LMWidgetExtension` (Xcode may add "Extension" - that's OK)
   - Set **Minimum Deployments** iOS to **17.0** (or 18.0 for Control Center only)
3. Go to **Build Settings**:
   - Search for **Swift Language Version** and set to **Swift 5** or later

### Step 4: Add App Groups Capability (REQUIRED)

This is needed for Control Center widgets to communicate with the main app.

**For Runner (main app) target:**
1. Select **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Click **+** and add: `group.net.neuro9.lmmini`

**For LMWidgetExtensionExtension target:**
1. Select **LMWidgetExtensionExtension** target  
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Select **App Groups**
5. Add the same group: `group.net.neuro9.lmmini`

### Step 5: Update Signing

1. For both **Runner** and **LMWidgetExtensionExtension** targets:
   - Go to **Signing & Capabilities**
   - Set your **Team**
   - Enable **Automatically manage signing**

### Step 6: Clean and Build

1. **Product > Clean Build Folder** (⇧⌘K)
2. Build the project (⌘B)
3. Run on device (widgets don't work in simulator)

## Widget Features

### Control Center Widgets (iOS 18+)

| Widget | Icon | Action |
|--------|------|--------|
| New Chat | plus.message.fill | Opens app with new conversation |
| Quick Camera | camera.fill | Opens app with camera for vision chat |

### Home Screen Widget
- Small and Medium sizes available
- Taps open a new chat via URL scheme `lmmini://newchat`

## How Users Add Widgets

### Control Center (iOS 18+)
1. Open **Settings** > **Control Center**
2. Scroll down to find **LM Mini** widgets
3. Tap **+** to add them
4. Widgets appear in Control Center (swipe down from top-right)

### Home Screen
1. Long-press on home screen
2. Tap **+** in top-left
3. Search for "LM Mini"
4. Select widget size and tap **Add Widget**

## Troubleshooting

### Widget not appearing in Control Center settings
- Control Center widgets require iOS 18+
- Ensure the widget extension is properly embedded
- Try restarting the device

### Widget action not working
- Verify App Groups is configured on both targets
- Check that group identifier matches: `group.net.neuro9.lmmini`
- Ensure the app was rebuilt after adding App Groups

### Build errors
- Clean build folder: **Product > Clean Build Folder**
- Ensure Swift version matches between targets
- Check that all deleted files are also removed from Build Phases

### "No such module" errors
- Make sure all import statements are valid
- Control Center widgets need iOS 18+ SDK (Xcode 16+)

## Widget Features

### New Chat Widget
- **Control Center button** that opens the app with a new chat
- Icon: Plus message
- URL Scheme: `lmmini://newchat`

### Quick Camera Widget  
- **Control Center button** that opens camera directly for vision chat
- Icon: Camera
- URL Scheme: `lmmini://camera`

## How Users Add Widgets

1. Open **Settings** > **Control Center**
2. Tap **+** next to "LM Mini" widgets
3. Widgets appear in Control Center (swipe down from top-right)

## Troubleshooting

### Widget not appearing
- Ensure iOS 18+ is targeted
- Rebuild and reinstall the app
- Check that the extension is embedded in the main app

### URL scheme not working
- Verify `CFBundleURLSchemes` in main app's Info.plist contains `lmmini`
- Check AppDelegate.swift has URL handling code

### Build errors
- Clean build folder: **Product > Clean Build Folder**
- Reset package caches if using CocoaPods
- Ensure Swift version matches between targets

## Alternative: Add Widget Manually

If the auto-setup doesn't work, you can manually create the widget target:

1. In project.pbxproj, you'll need to add:
   - PBXFileReference entries for widget files
   - PBXGroup for LMWidgetExtension
   - PBXNativeTarget for the extension
   - Build configurations (Debug, Release, Profile)
   - Product reference

This is complex and error-prone - using Xcode's UI is recommended.
