# Compiling for macOS and iOS

![OpenXTalk Community Logo](http://livecode.com/wp-content/uploads/2015/02/livecode-logo.png)

Copyright © 2015-2024 LiveCode Ltd., Edinburgh, UK
Copyright © 2024-2026 OpenXTalk Community

## Overview

OpenXTalk can be built for macOS (Intel and Apple Silicon) and iOS devices and simulators. This guide covers the requirements and build process for both platforms.

## System Requirements

### Required Software

- **macOS**: macOS 13 (Ventura) or later
- **Xcode**: Xcode 14 or later (latest version recommended)
  - Install from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
- **Command Line Tools**: Installed automatically with Xcode, or run:
```bash
  xcode-select --install
```
- **Python**: Python 2.7 (via pyenv) or Python 3.x
  - The build system has been updated to work with Python 3
- **Git**: For cloning the repository and managing submodules

### Supported Target Platforms

- **macOS**: 11.0 (Big Sur) or later
  - Universal binaries supported (Intel x86_64 + Apple Silicon arm64)
- **iOS**: 16.0 or later
  - arm64 only (modern iPhones and iPads)
- **iOS Simulator**: Runs on your Mac's native architecture
  - arm64 on Apple Silicon Macs
  - x86_64 on Intel Macs

## Getting Started

### 1. Clone the Repository
```bash
git clone --recursive https://github.com/OpenXTalk-org/OpenXTalk-Community-DPE.git
cd OpenXTalk-Community-DPE
```

If you've already cloned without `--recursive`, initialize the submodules:
```bash
git submodule update --init --recursive
```

### 2. Install Python 2.7 (if needed)

Some legacy build scripts still require Python 2.7. Install it using pyenv:
```bash
# Install pyenv
brew install pyenv

# Install Python 2.7
pyenv install 2.7.18

# Set it for this directory only
pyenv local 2.7.18
```

Alternatively, the build system supports Python 3.x for most operations.

## Building for macOS

### Quick Start
```bash
# Configure the build (generates Xcode project files)
make config-mac

# Compile (Debug build)
make compile-mac

# Or compile Release build (optimized)
MODE=release make compile-mac
```

### Build Configurations

- **Debug**: Full debugging symbols, no optimization (default)
```bash
  MODE=debug make compile-mac
```
  
- **Release**: Optimized for performance, stripped symbols
```bash
  MODE=release make compile-mac
```
  
- **Fast**: Optimized with some debug information
```bash
  MODE=fast make compile-mac
```

### Using Xcode (Optional)

After running `make config-mac`, you can open the generated Xcode project:
```bash
open build-mac/livecode/livecode.xcodeproj
```

Then build using Xcode's standard build commands (⌘B).

### Architecture Notes

The build system automatically detects your Mac's architecture:
- **Apple Silicon Macs**: Builds arm64 binaries by default
- **Intel Macs**: Builds x86_64 binaries by default

To build a universal binary (both architectures), modify the build configuration or use Xcode's architecture settings.

## Building for iOS

### Configure for iOS
```bash
# Configure for iOS device (latest supported version)
make config-ios-iphoneos

# Or for iOS Simulator
make config-ios-iphonesimulator
```

### Compile for iOS
```bash
# Build for iOS device
make compile-ios-iphoneos

# Build for iOS Simulator
make compile-ios-iphonesimulator
```

### iOS Requirements

- **Apple Developer Account**: Required for deploying to physical devices
- **Code Signing**: Configure in Xcode project settings
- **Provisioning Profiles**: Set up in Xcode or Apple Developer portal

### Supported iOS Versions

OpenXTalk supports:
- iOS 16.0 and later
- arm64 architecture only

This covers devices receiving current security updates from Apple.

## Engine Flavors

OpenXTalk builds several engine variants for different purposes:

1. **Development Engine**: Used to run the IDE
   - Target: `development`
   - Contains IDE-specific features

2. **Standalone Engine**: Embedded in compiled applications
   - Target: `standalone`
   - Optimized, minimal dependencies

3. **Server Engine**: For headless/server contexts
   - Target: `server`
   - No GUI dependencies

4. **Installer Engine**: Used to create the OpenXTalk installer
   - Target: `installer`
   - Archive and installation utilities

## Cleaning Build Artifacts
```bash
# Clean macOS builds
make clean-mac

# Clean iOS builds
make clean-ios

# Clean everything
make clean-all
```

## Troubleshooting

### "Command not found" Errors

If you see errors about missing commands:
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Verify Python is available: `python --version` or `python3 --version`

### Xcode Version Issues

If you have multiple Xcode versions installed, set the active one:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

### Submodule Issues

If builds fail with missing files, ensure submodules are initialized:
```bash
git submodule update --init --recursive --force
```

### Architecture Mismatch

The build system auto-detects your Mac's architecture. If you need to override:
```bash
TARGET_ARCH=arm64 make config-mac  # Force arm64
TARGET_ARCH=x86_64 make config-mac # Force x86_64
```

## Advanced Configuration

For detailed configuration options:
```bash
./config.sh --help
```

You can customize:
- Target architectures
- SDK versions
- Build options
- Feature flags

## Additional Resources

- [OpenXTalk Forums](https://forums.openxtalk.org/)
- [Contributing Guide](../../CONTRIBUTING.md)
- [Build System Overview](../development/)

## Legacy Support

This documentation covers modern build requirements (macOS 11+, iOS 16+). 

For building with older SDKs or architectures, refer to:
- Legacy LiveCode documentation
- Older commits in the repository history
- Community forums for archived build instructions

Note: Older OS versions no longer receive security updates from Apple and are not recommended for production use.