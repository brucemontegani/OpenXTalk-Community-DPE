# Compiling OpenXTalk for macOS and iOS

![OpenXTalk Community Logo](http://livecode.com/wp-content/uploads/2015/02/livecode-logo.png)

Copyright © 2015-2024 LiveCode Ltd., Edinburgh, UK  
Copyright © 2024-2026 OpenXTalk Community

## Overview

OpenXTalk can be built for macOS (Intel and Apple Silicon) and iOS devices and simulators. This guide covers the requirements and build process for both platforms.

The build system has been modernized to support current Apple development practices, eliminating the need for multiple Xcode installations and legacy SDK management.

## Understanding SDKs vs Deployment Targets

Before building, it's important to understand two key concepts:

### Base SDK (What You Build WITH)
- The SDK version you compile against
- Should be the **latest available** on your development machine
- Provides access to newest APIs and compiler features
- **Automatically detected** by the build system

### Deployment Target (What You Build FOR)
- The **minimum** OS version your application will run on
- Users on this version (and newer) can run your application
- Set to **macOS 13.0** by default (supporting last 3 major releases)
- Can be customized via environment variable

**Example**: You can build OpenXTalk using macOS 15.2 SDK, but set deployment target to 13.0, meaning the compiled IDE will run on macOS 13.0 (Ventura) through 15.x (Sequoia) and future versions.

## System Requirements

### Required Software

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 14.0 or later (latest stable version recommended)
  - Install from the Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
- **Command Line Tools**: Installed automatically with Xcode, or run:
  ```bash
  xcode-select --install
  ```
- **Python**: Python 2.7 or Python 3.x
  - Python 3 is recommended and supported by the modernized build system
  - Python 2.7 can be installed via pyenv if needed for legacy scripts
- **Git**: For cloning the repository and managing submodules

### Recommended Setup

For the best development experience:
- **macOS**: 14.0 (Sonoma) or 15.0 (Sequoia)
- **Xcode**: Latest stable version (15.x or 16.x)
- Keeps you current with Apple's latest tooling and optimizations

### What You DON'T Need

❌ Multiple Xcode versions  
❌ Legacy SDK downloads  
❌ Complex SDK caching scripts  
❌ Xcode 6.2, 7.2.1, 8.x (old documentation is outdated)

The build system automatically detects and uses your installed Xcode and SDK.

### Supported Target Platforms

- **macOS**: 13.0 (Ventura) or later
  - Universal binaries supported (Intel x86_64 + Apple Silicon arm64)
  - Architecture automatically detected based on your Mac
- **iOS**: 16.0 or later
  - arm64 only (modern iPhones and iPads)
  - Dropped 32-bit armv7 support (iPhone 5c and earlier)
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

### 2. Install Python (if needed)

The build system works with Python 3.x for most operations. If you need Python 2.7 for legacy scripts:

```bash
# Install pyenv
brew install pyenv

# Install Python 2.7
pyenv install 2.7.18

# Set it for this directory only
pyenv local 2.7.18
```

Verify Python is available:
```bash
python --version
# or
python3 --version
```

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

The build system will:
- Auto-detect your Mac's architecture (Apple Silicon arm64 or Intel x86_64)
- Auto-detect your installed macOS SDK version
- Set deployment target to macOS 13.0 (runs on Ventura and later)
- Generate Xcode project files in `build-mac/`

### Build Configurations

OpenXTalk supports three build modes:

- **Debug** (default): Full debugging symbols, no optimization
  ```bash
  MODE=debug make compile-mac
  ```
  Best for development and debugging.
  
- **Release**: Optimized for performance, stripped symbols
  ```bash
  MODE=release make compile-mac
  ```
  Best for distribution and production use.
  
- **Fast**: Optimized with some debug information
  ```bash
  MODE=fast make compile-mac
  ```
  Balance between performance and debuggability.

### Using Xcode (Optional)

After running `make config-mac`, you can open the generated Xcode project:

```bash
open build-mac/livecode/livecode.xcodeproj
```

Then build using Xcode's standard build commands (⌘B).

### Architecture Notes

The build system automatically detects your Mac's architecture:
- **Apple Silicon Macs** (M1, M2, M3, etc.): Builds arm64 binaries by default
- **Intel Macs**: Builds x86_64 binaries by default

To override or build for a specific architecture:
```bash
TARGET_ARCH=arm64 make config-mac   # Force arm64
TARGET_ARCH=x86_64 make config-mac  # Force x86_64
```

For universal binaries (both architectures), this can be configured in the Xcode project settings after generation.

### Customizing Deployment Target

By default, OpenXTalk targets macOS 13.0. To change this:

```bash
# Build for macOS 12.0 and later
MACOSX_DEPLOYMENT_TARGET=12.0 make config-mac

# Build for macOS 14.0 and later
MACOSX_DEPLOYMENT_TARGET=14.0 make config-mac
```

## Building for iOS

### Configure for iOS

```bash
# Configure for iOS device (latest supported version)
make config-ios-iphoneos

# Or for iOS Simulator
make config-ios-iphonesimulator
```

The build system supports iOS 16.0 and later by default.

### Compile for iOS

```bash
# Build for iOS device
make compile-ios-iphoneos

# Build for iOS Simulator
make compile-ios-iphonesimulator
```

### iOS Requirements

- **Apple Developer Account**: Required for deploying to physical devices
- **Code Signing**: Configure in Xcode project settings or via command line
- **Provisioning Profiles**: Set up in Xcode or Apple Developer portal

### Supported iOS Versions

OpenXTalk supports:
- iOS 16.0 and later (arm64 only)
- Covers devices receiving current security updates from Apple
- Supports last 3-4 major iOS releases

This modern approach:
- Drops 32-bit armv7 support (iPhone 5c era)
- Focuses on actively supported iOS versions
- Reduces build complexity and maintenance burden

## Engine Flavors

OpenXTalk builds several engine variants for different purposes:

1. **Development Engine** (`development` target)
   - Used to run the OpenXTalk IDE
   - Contains IDE-specific features, debugging tools
   - Larger binary with additional functionality

2. **Standalone Engine** (`standalone` target)
   - Embedded in compiled end-user applications
   - Optimized for size and performance
   - Minimal dependencies

3. **Server Engine** (`server` target)
   - For headless/server contexts
   - No GUI dependencies
   - Command-line focused

4. **Installer Engine** (`installer` target)
   - Used to create the OpenXTalk installer
   - Archive and installation utilities
   - Special packaging features

To build a specific engine flavor:
```bash
# After config-mac, build specific target in Xcode
# Or use make with specific targets (see Makefile for options)
```

## Cleaning Build Artifacts

```bash
# Clean macOS builds
make clean-mac

# Clean iOS builds
make clean-ios

# Clean everything (all platforms)
make clean-all
```

This removes:
- Generated Xcode projects
- Compiled binaries
- Intermediate build files
- Cached data

## Troubleshooting

### "Command not found" Errors

If you see errors about missing commands:
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Verify Python is available: `python --version` or `python3 --version`
- Restart your terminal to pick up environment changes

### Xcode Version Issues

If you have multiple Xcode versions installed, set the active one:

```bash
# List installed Xcode versions
ls /Applications | grep Xcode

# Set active Xcode
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Verify
xcode-select -p
xcodebuild -version
```

### SDK Not Found Errors

If you see "unable to find sdk" errors:

1. Check available SDKs:
   ```bash
   xcodebuild -showsdks
   ```

2. The build system should auto-detect, but if it fails, ensure you have Xcode properly installed and licensed:
   ```bash
   sudo xcodebuild -license accept
   ```

3. Run Xcode at least once to complete setup

### Submodule Issues

If builds fail with missing files, ensure submodules are initialized:

```bash
git submodule update --init --recursive --force
```

Check submodule status:
```bash
git submodule status
```

All submodules should show a commit hash (not a `-` prefix indicating uninitialized).

### Architecture Mismatch

The build system auto-detects your Mac's architecture. If you need to override:

```bash
# Check your Mac's architecture
uname -m

# Force specific architecture
TARGET_ARCH=arm64 make config-mac   # For Apple Silicon
TARGET_ARCH=x86_64 make config-mac  # For Intel
```

### Python Issues

If you encounter Python-related errors:

```bash
# Check Python version
python --version
python3 --version

# For Python 2.7 specific issues, use pyenv
pyenv versions
pyenv local 2.7.18
```

The build system has been updated to work with Python 3, but some legacy scripts may still require Python 2.7.

### Build Fails After System Update

After updating macOS or Xcode:

```bash
# Clean everything
make clean-all

# Re-accept Xcode license
sudo xcodebuild -license accept

# Ensure command line tools are updated
xcode-select --install

# Reconfigure
make config-mac
```

## Advanced Configuration

### Custom Configuration Options

For detailed configuration options, use the config script directly:

```bash
./config.sh --help
```

You can customize:
- Target architectures
- SDK versions
- Deployment targets
- Build options
- Feature flags
- Platform-specific settings

### Environment Variables

Key environment variables you can set:

```bash
# Deployment target
export MACOSX_DEPLOYMENT_TARGET=13.0

# Target architecture
export TARGET_ARCH=arm64

# Build mode
export MODE=release

# Custom Xcode location
export XCODEBUILD=/Applications/Xcode-Custom.app/Contents/Developer/usr/bin/xcodebuild
```

### Building from Xcode IDE

After configuration, you can use Xcode for development:

1. Open the generated project:
   ```bash
   open build-mac/livecode/livecode.xcodeproj
   ```

2. Select your target from the scheme selector

3. Choose your architecture (My Mac, Any Mac, etc.)

4. Build with ⌘B

5. Debug with ⌘R

This is useful for:
- Interactive debugging
- Profiling with Instruments
- Using Xcode's analysis tools
- Graphical project navigation

### Building Universal Binaries

Universal binaries contain code for both Intel (x86_64) and Apple Silicon (arm64) architectures, providing optimal performance on all Mac types.

#### Quick Universal Build

```bash
# Configure and build universal binary in one step
make compile-mac-universal
```

This automatically:
- Configures the build for both architectures
- Compiles for x86_64 and arm64
- Creates a single binary that runs natively on both platforms

#### Manual Universal Build

For more control:

```bash
# Configure for universal build
make config-mac-universal

# Build with your preferred mode
MODE=release make compile-mac
```

Or using environment variable directly:

```bash
# Configure for universal
UNIVERSAL_BUILD=1 make config-mac

# Compile
make compile-mac
```

#### When to Use Universal Binaries

**Advantages**:
- ✅ Single download works on all Macs
- ✅ Native performance on both Intel and Apple Silicon
- ✅ Best user experience for distribution
- ✅ Future-proof as Apple transitions

**Disadvantages**:
- ❌ Larger file size (roughly 2x)
- ❌ Longer build times
- ❌ More disk space required

**Recommendation**: 
- Use **universal builds** for releases and distribution
- Use **single-architecture builds** for development and testing

## Development Workflow

### Typical Development Cycle

```bash
# 1. Make code changes
vim engine/src/your-file.cpp

# 2. Reconfigure if you changed .gyp files
make config-mac

# 3. Build
MODE=debug make compile-mac

# 4. Test your changes
# Run the compiled IDE or engine

# 5. Iterate
```

### Incremental Builds

After initial compilation, subsequent builds are incremental:
- Only changed files are recompiled
- Much faster than full rebuilds
- Use `make clean-mac` only when needed

### Building for Different Architectures

```bash
# Build for Apple Silicon only (faster on M1/M2/M3 Macs)
TARGET_ARCH=arm64 make config-mac
make compile-mac

# Build for Intel only
TARGET_ARCH=x86_64 make config-mac
make compile-mac

# Build universal binary (both architectures)
make compile-mac-universal
```

### Testing Changes

After building:
```bash
# Find your compiled binaries
ls -la _build/mac/Debug/
ls -la _build/mac/Release/

# Run the development engine
open _build/mac/Debug/LiveCode-Community.app

# Check architecture of compiled binary
file _build/mac/Debug/LiveCode-Community.app/Contents/MacOS/LiveCode-Community
# Output for single arch: Mach-O 64-bit executable arm64
# Output for universal:   Mach-O universal binary with 2 architectures
```

### Verifying Universal Binaries

To confirm a binary is truly universal:

```bash
# Check architecture
lipo -info _build/mac/Release/LiveCode-Community.app/Contents/MacOS/LiveCode-Community

# Should show: Architectures in the fat file: x86_64 arm64

# Or use file command
file _build/mac/Release/LiveCode-Community.app/Contents/MacOS/LiveCode-Community

# Should show: Mach-O universal binary with 2 architectures
```

## About App Store Distribution

### For End-User Applications

If you're building applications **with OpenXTalk** for App Store distribution:
- Apple requires recent SDK versions
- Typically needs Xcode from last 12 months
- Build with latest recommended Xcode

### For OpenXTalk IDE Distribution

OpenXTalk is GPL open source, so:
- **No App Store requirement** for the IDE itself
- Can be distributed directly to users
- No need for App Store submission
- More flexibility in Xcode/SDK versions

However, keeping current with Apple's tooling is still recommended for security and compatibility.

## System Requirements Summary

### To Build OpenXTalk

**Minimum**:
- macOS 13.0 (Ventura)
- Xcode 14.0
- 8GB RAM (16GB recommended)
- 20GB free disk space

**Recommended**:
- macOS 14.0 (Sonoma) or 15.0 (Sequoia)
- Xcode 15.x or 16.x (latest stable)
- 16GB+ RAM
- SSD with 30GB+ free space

### To Run OpenXTalk IDE

The compiled OpenXTalk IDE runs on:
- macOS 13.0 (Ventura) and later (default deployment target)
- Both Intel and Apple Silicon Macs
- Future macOS versions (forward compatible)

## Additional Resources

- [OpenXTalk Forums](https://forums.openxtalk.org/) - Community support and discussion
- [Contributing Guide](../../CONTRIBUTING.md) - How to contribute to OpenXTalk
- [Build System Overview](../development/) - Technical details of the build system
- [OpenXTalk Repository](https://github.com/OpenXTalk-org/OpenXTalk-Community-DPE) - Source code and issues

## Migrating from Legacy Build Instructions

If you previously built OpenXTalk (or LiveCode) with the old multi-Xcode setup:

### What Changed

❌ **No longer needed**:
- Multiple Xcode versions (6.2, 7.2.1, 8.x)
- SDK caching scripts (`setup_xcode_sdks.sh`)
- Manual SDK installation
- Complex `/Applications/Xcode-Dev/` setup

✅ **New approach**:
- Single Xcode installation (latest)
- Auto-detection of SDK and architecture
- Modern deployment targets (13.0+)
- Simplified configuration

### Migration Steps

1. **Remove old Xcode versions** (optional, saves disk space):
   ```bash
   # Back up first if unsure!
   rm -rf /Applications/Xcode-Dev/
   ```

2. **Install latest Xcode** from App Store

3. **Clean old builds**:
   ```bash
   make clean-all
   ```

4. **Reconfigure with new system**:
   ```bash
   make config-mac
   ```

5. **Build as normal**:
   ```bash
   make compile-mac
   ```

### Benefits of Modern Approach

- **Simpler**: One Xcode, automatic configuration
- **Faster**: Less complexity, faster builds
- **Maintained**: Follows Apple's current practices
- **Secure**: Uses latest toolchains with security updates
- **Future-proof**: Easier to update as Apple releases new versions

## Legacy Support Note

This documentation covers modern build requirements (macOS 13+, Xcode 14+, iOS 16+).

If you need to build for older OS versions:
- Refer to legacy LiveCode documentation
- Check older commits in the repository history
- Ask on community forums for archived build instructions

**Important**: Older OS versions no longer receive security updates from Apple and are not recommended for production use. OpenXTalk focuses on currently supported platforms.

## License

OpenXTalk Community Edition is open source software licensed under GPLv3.

For more information, see the [LICENSE](../../LICENSE) file in the repository.

---

**Questions or issues?** Visit the [OpenXTalk Forums](https://forums.openxtalk.org/) or open an issue on [GitHub](https://github.com/OpenXTalk-org/OpenXTalk-Community-DPE/issues).