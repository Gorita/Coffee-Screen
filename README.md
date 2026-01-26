# Coffee-Screen

<p align="center">
  <img src="coffee-screen.png" alt="Coffee-Screen" width="600">
</p>

> A macOS application for long-running process protection and screen security

**[한국어 README](README_KR.md)**

## Introduction

Coffee-Screen is a macOS application that **prevents system sleep** and **hides the screen** to protect your work during long-running tasks such as AI training or large-scale data rendering.

Designed to work safely in enterprise security environments (MDM, DLP, antivirus, etc.).

## Key Features

- **Prevent System Sleep**: Keeps CPU and network active using IOKit Power Assertion
- **Screen Concealment**: Covers all monitors with black windows to protect work content
- **Input Blocking**: Prevents system escape via Cmd+Tab, force quit, etc. using Kiosk Mode API
- **Secure Unlock**: Authentication via Touch ID, password, or PIN
- **Menu Bar Control**: Quick lock/unlock and settings access from the menu bar

## System Requirements

- macOS 14 (Sonoma) or later
- Apple Silicon or Intel Mac

## Installation

### Direct Download
Download the latest version from the [Releases](https://github.com/Gorita/Coffee-Screen/releases) page.

### Build from Source
```bash
git clone https://github.com/Gorita/Coffee-Screen.git
cd coffee-screen
open CoffeeScreen.xcodeproj
```

## Usage

1. Launch the app.
2. **Set up a PIN** (4-8 digit number, required once).
3. Click the **"Lock Screen"** button.
4. The screen turns black and system sleep is prevented.
5. To unlock: Click the screen and authenticate with **Touch ID**, **password**, or **PIN**.

## Emergency Escape

If the app freezes or authentication fails in kiosk mode:
- Press **Both Shift + Cmd + L** simultaneously to unlock immediately (default)
- The emergency escape key can be changed in settings

## Notes

- Power adapter connection is recommended (sleep may occur when closing lid on battery)
- Physical power button force shutdown cannot be prevented

## License

MIT License

## Documentation

- [Tech Stack](docs/TECH_STACK.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Implementation Plan](docs/IMPLEMENTATION_PLAN.md)
