# Coffee-Screen ☕

<p align="center">
  <img src="coffee-screen.png" alt="Coffee-Screen" width="600">
</p>

<p align="center">
  <strong>A lightweight, retro-styled macOS application for long-running process protection, lock screen customization, and screen security.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-green" alt="Architecture">
  <img src="https://img.shields.io/badge/License-MIT-purple" alt="License">
</p>

---

**[🇰🇷 한국어 README 보기](README_KR.md)**

## 🌟 Overview

**Coffee-Screen** keeps your Mac awake during long-running tasks (e.g., deep learning model training, 4K video rendering, heavy data compiling) while offering **enterprise-grade screen concealment** and a **delightful 8-bit retro lock screen customization studio**.

Designed to operate safely even in strict enterprise security environments (MDM, DLP, antivirus).

---

## ✨ Key Features

### 🛡️ Core Security & Keep-Awake
- **Prevent System Sleep**: Uses native `IOKit` Power Assertion to keep CPU, GPU, and network connections fully active.
- **Standalone Awake Mode**: Prevent sleep without locking the screen—perfect for live dashboard and build monitoring.
- **Full Screen Concealment**: Covers all connected monitors with blackout or custom artwork to protect confidential work.
- **Kiosk Input Shield**: Disables `Cmd+Tab`, Mission Control, force quit, and hot corners during lock mode.
- **Multi-Factor Unlock**: Authenticate seamlessly via **Touch ID**, **macOS System Password**, or **4-8 Digit PIN**.
- **Emergency Escape Key**: Safe instant unlock shortcut (**Both Shift + Cmd + L**) in case of unexpected freezes.

### 🎨 Lock Screen Studio & Sticker Editor
- **Custom Visual Editor (`Edit Lock Screen`)**: Real-time canvas for crafting your personalized lock screen.
- **Apple Vision AI Background Removal**: Automatically strips backgrounds from dropped sticker images into clean transparent cutout sprites.
- **Canvas Controls**: Freely place, resize, rotate, and reorder sticker layers with retro 8-bit handles.

### 🎬 30-Second Long Cinematic HD GIF Presets
Built-in 1280×720 HD 30-second seamless looping animated presets:
1. **Interactive Typing**: Realistic real-time developer terminal typing, compilation streaming, 42/42 unit test suite, and live CPU performance dashboard.
2. **Pixel Dog**: An authentic 1-line height terminal companion Shiba Inu that walks along code corridors, taps the cursor with its front paw, sniffs hot espresso, plays with a bone, and curls up into a donut sleep.
3. **Dev Terminal**: 30-second rich C++/Swift syntax-highlighted kernel source code display.
4. **Ghostty ASCII**: Retro glowing ASCII art terminal loop.
5. **Summer Horror**: Atmospheric chilling horror artwork preset.

### ☕ Buy Me a Coffee Halftone Animation
- Integrated donation sheet featuring an authentic **Halftone Steaming Coffee Cup QR Code animation** with tap-outside-to-dismiss overlay.

### 🔄 In-App Updates
- Automatic lightweight updates powered by the **Sparkle 2 framework**.

---

## 💻 System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or later
- **Architecture**: Universal (Apple Silicon & Intel 64-bit)

---

## 🚀 Installation & Build

### Direct Download
Download the latest `.dmg` installer from the [Releases](https://github.com/Gorita/Coffee-Screen/releases) page.

> **Gatekeeper Notice**: As an independent developer build, right-click the app on first launch → select **"Open"** to grant permission.

### Build from Source
```bash
# Clone the repository
git clone https://github.com/Gorita/Coffee-Screen.git
cd Coffee-Screen

# Create standalone Release DMG
./scripts/release.sh

# Or open in Xcode
open CoffeeScreen.xcodeproj
```

---

## 📖 How to Use

### 1. Lock Screen Mode
1. Launch **Coffee-Screen**.
2. Set up your 4-8 digit PIN on first run.
3. Click **"Lock Screen"** (or press the global lock hotkey).
4. When you return, click the screen and unlock with **Touch ID**, **password**, or **PIN**.

### 2. Standalone Awake Mode
1. Click the coffee cup toggle on the main card or select **"Keep Mac Awake"** from the menu bar.
2. Your Mac stays awake while you use it normally.

### 3. Customizing the Lock Screen
1. Open the menu bar ➡️ **"Edit Lock Screen"**.
2. Pick any of the 5 built-in 30-second HD presets or drop your own image/GIF.
3. Add sticker sprites with automatic Vision AI cutout.
4. Click **"Save Changes"**.

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.
