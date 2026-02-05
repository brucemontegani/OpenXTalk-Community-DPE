# OpenXTalk Community Edition - Release Notes

## Development Build - February 2025

### What's New

**OpenXTalk now builds natively on modern macOS!**

This release represents a major overhaul of the build system, making it possible to compile OpenXTalk from source on current macOS versions with modern Xcode, without needing legacy SDKs or old Xcode installations.

### Highlights

🚀 **New CMake Build System**
- Simple two-step build: `make config-mac && make compile-mac`
- Generates native Xcode projects for debugging
- Supports both Apple Silicon (arm64) and Intel (x86_64) Macs

🎨 **Start Center Works**
- All widgets and extensions load correctly
- SVG icons, tiles, and browser widgets render properly
- New OpenXTalk logo displayed

📦 **Batteries Included**
- Prebuilt ICU and OpenSSL libraries included in repo
- No need to fetch or compile dependencies separately
- Clone and build immediately

### System Requirements

- **macOS**: 12.0 (Monterey) or later
- **Xcode**: 14.0 or later (latest stable recommended)
- **Python**: 3.x (for build scripts)
- **Disk Space**: ~2GB for source and build

### Quick Start

```bash
# Clone the repository
git clone --recursive https://github.com/brucemontegani/OpenXTalk-Community-DPE.git
cd OpenXTalk-Community-DPE

# Configure and build
make config-mac
make compile-mac

# Run the IDE
open build-mac-debug/Debug/bin/LiveCode-Community.app
```

### Known Limitations

- Dark mode is disabled (IDE doesn't fully support it yet)
- Some documentation features may show errors on first run
- Windows and Linux builds not yet ported to CMake

### What's Fixed

- IDE no longer crashes on startup
- Extension loading works correctly
- Start Center displays all graphics and widgets
- Menu initialization issues resolved
- Recent files menu filters correctly

### For Developers

The new CMake build system provides:
- Proper dependency tracking
- Incremental builds
- Xcode project for debugging and profiling
- Clear separation of build artifacts

See `CLAUDE.md` for detailed build instructions and architecture overview.

---

*OpenXTalk Community Edition is an open-source fork of LiveCode Community Edition.*
