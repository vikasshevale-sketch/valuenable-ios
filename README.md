# Valuenable Secure Workspace iOS App — Deployment Guide

A fully containerized, zero-data-leakage iOS app for company Google Workspace access (`valuenable.in`) on employee personal iPhones (BYOD).

---

## 📂 Complete Project Layout

```
SecureWorkspaceIOS/
├── SecureWorkspace.xcodeproj/       # Ready-to-open Xcode Project
│   └── project.pbxproj
├── SecureWorkspace/
│   ├── AppDelegate.swift             # Application entry point & pasteboard isolation
│   ├── SceneDelegate.swift           # Multitasking blur & Face ID resumption
│   ├── Info.plist                    # Bundle metadata & Face ID permission
│   ├── Assets.xcassets/              # App icons & color palette
│   ├── Security/
│   │   ├── SecureContainerView.swift # Hardware DRM screenshot & recording blocker
│   │   ├── ScreenCaptureMonitor.swift# Real-time video call & screen share detector
│   │   ├── BiometricAuthManager.swift# Face ID / Passcode lock manager
│   │   └── JailbreakDetector.swift   # Integrity & root check
│   ├── WebContainer/
│   │   ├── SecureWebViewController.swift # Isolated WKWebView container
│   │   ├── DomainGuard.swift         # Strict valuenable.in domain enforcement
│   │   └── WebSecurityScripts.swift  # CSS/JS copy/paste & text selection blocker
│   └── DocumentViewer/
│       ├── SecurePreviewController.swift # QuickLook viewer with Share Sheet stripped
│       └── SandboxedFileManager.swift    # Ephemeral encrypted attachment storage
├── ExportOptions.plist               # Configuration for automated IPA export
├── manifest.plist                    # Wireless Over-The-Air (OTA) distribution manifest
├── build_and_export.sh               # One-click build & archive shell script
└── README.md
```

---

## 🚀 How to Build, Test & Deploy

### Step 1: Open in Xcode
1. Double-click `SecureWorkspace.xcodeproj` to open the project in **Xcode**.
2. Select the **SecureWorkspace** target.
3. Go to **Signing & Capabilities**:
   - Check **Automatically manage signing**.
   - Select your **Apple Developer Team** (Apple Enterprise Developer or Apple Developer Program).
   - Bundle Identifier: `in.valuenable.secureworkspace` (or update to your preferred prefix).

---

### Step 2: Test on iPhone / Simulator
1. Connect an iPhone via USB or select an iOS Simulator (iOS 15.0+).
2. Press **Cmd + R** (or click the Play button) to build and launch.
3. **Verify Security Features**:
   - **Screenshot**: Take a screenshot (`Power + Volume Up`). Result: **Content is completely blacked out**.
   - **Screen Recording / Video Call**: Start screen recording in Control Center or start a video call. Result: **Opaque blackout shield covers the screen**.
   - **Domain Lock**: Only `@valuenable.in` Google accounts are permitted.
   - **Copy/Paste**: Long-press text selection and callouts are disabled.
   - **Attachments**: Tap an email attachment. Opens internally in the secure viewer with no Share Sheet, no AirDrop, and no Save to Files.

---

### Step 3: Build & Export `.ipa` Package

#### Option A: Using Xcode GUI
1. In the top menu, select **Product > Archive**.
2. Once the Organizer window opens, click **Distribute App**.
3. Choose your distribution method (**Enterprise**, **Custom App via Apple Business Manager**, or **App Store / TestFlight**).
4. Click **Export** to save the `SecureWorkspace.ipa`.

#### Option B: Using the Included Script
Run the automated packaging script from your terminal:
```bash
chmod +x build_and_export.sh
./build_and_export.sh
```
The resulting `.ipa` file will be placed in `./build/ExportedApp/SecureWorkspace.ipa`.

---

### Step 4: Distribute to Employees (BYOD)

Since employees are using personal devices, choose one of the three zero-friction distribution models:

#### Method 1: Apple Business Manager (ABM) Custom Apps (Recommended)
1. Upload the build via Xcode to **App Store Connect**.
2. Set Availability to **Private / Custom App** for your organization's Apple Business Manager ID.
3. Employees install the app directly on their personal iPhones using private redemption codes or via company portal **without enrolling their personal phone in MDM**.

#### Method 2: Enterprise Wireless Over-The-Air (OTA) Link
1. Host `SecureWorkspace.ipa` and `manifest.plist` on an internal HTTPS web server (e.g., `https://workspace.valuenable.in/ios/`).
2. Provide employees with an installation link:
   ```html
   <a href="itms-services://?action=download-manifest&url=https://workspace.valuenable.in/ios/manifest.plist">
       Tap here to Install Valuenable Secure Workspace
   </a>
   ```
3. When tapped on Safari on the iPhone, iOS installs the app wirelessly.

#### Method 3: TestFlight Private Group
- Add employee emails to a private internal TestFlight group for instant updates and automated installation.

---

### Step 5: Google Workspace Admin Console Setup
1. Log in to [admin.google.com](https://admin.google.com) as a Super Admin.
2. Navigate to **Security > Access and data control > Device management**.
3. Under **Account Chooser / Allowed Domains**, ensure only `valuenable.in` is specified.
4. (Optional) Under **Context-Aware Access**, create an access policy requiring the specific app identifier (`in.valuenable.secureworkspace`).
