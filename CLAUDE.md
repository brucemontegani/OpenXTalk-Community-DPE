# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenXTalk Community Edition is an open-source, cross-platform application development environment descended from LiveCode Community Edition.

**IDE platforms**: Linux, macOS, Windows

**Standalone deployment targets**: macOS, iOS, Android, Linux, Windows

**Server engine**: Headless engine for server-side scripting and CGI applications

## Build Commands

### macOS Build (Primary Development Platform)

```bash
# Configure and build (uses CMake)
make config-mac
make compile-mac                    # Debug build (default)
MODE=release make config-mac        # Configure release build
MODE=release make compile-mac       # Release build

# Universal binary (Intel + Apple Silicon)
make compile-mac-universal

# Open generated Xcode project
open build-mac-debug/OpenXTalk.xcodeproj

# Use Unix Makefiles instead of Xcode (faster for CI)
CMAKE_GENERATOR="Unix Makefiles" make config-mac
```

### iOS Build

```bash
make config-ios-iphoneos           # Device
make config-ios-iphonesimulator    # Simulator
make compile-ios-iphoneos
make compile-ios-iphonesimulator
```

### Linux Build

```bash
make config-linux-x86_64
make compile-linux-x86_64
```

### Android Build

```bash
# Supported architectures: armv6, armv7, arm64, x86, x86_64
make config-android-armv7
make compile-android-armv7

make config-android-arm64
make compile-android-arm64
```

### Windows Build

```bash
# Build under Wine on Linux, or natively on Windows
make config-win-x86
make compile-win-x86
```

### Running Tests

```bash
make check                         # Run all tests for current platform
make check-mac                     # macOS tests
make check-linux-x86_64           # Linux tests
```

### Cleaning

```bash
make clean-mac
make clean-ios
make clean-all
```

## Architecture

### Core Components

- **engine/** - Main OpenXTalk execution engine (~735 C++ source files). Produces IDE, standalone, installer, and server engine variants.
- **libfoundation/** - Foundation library for basic functionality
- **libgraphics/** - Graphics and rendering system
- **libscript/** - Script execution engine
- **libcore/** - Core utility functions and types

### Externals (Runtime-loadable Plugins)

- **revdb/** - Database access (MySQL, PostgreSQL, SQLite, ODBC)
- **revmobile/** - iOS/Android support
- **revxml/** - XML parsing/generation
- **revzip/** - ZIP archive management
- **revpdfprinter/** - PDF output

### Build System

- **toolchain/** - LiveCode Builder (LCB) compiler (`lc-compile`, `lc-run`) and parser tools (`gentle`, `reflex`)
- **extensions/** - Standard library modules in LCB
- **prebuilt/** - Pre-compiled dependencies (OpenSSL, ICU, libcURL)
- **thirdparty/** - Third-party libraries (git submodule)
- Build files use GYP format (`.gyp` files) to generate platform-specific projects

### Engine Flavors

1. **development** - IDE engine with debugging and syntax support (Linux, macOS, Windows)
2. **standalone** - Embedded in end-user applications (macOS, iOS, Android, Linux, Windows)
3. **server** - Headless engine for server-side scripting, CGI, and command-line use (Linux, macOS, Windows)
4. **installer** - For creating the OpenXTalk installer

## Code Style

### C++ Naming Conventions

Variable prefixes indicate scope:
- `t_` - local variables
- `p_` - in parameters
- `r_` - out parameters
- `x_` - in-out parameters
- `m_` - class/struct instance members
- `s_` - static variables
- `g_` - global variables

Constants and enum members: Title case with `kMC` prefix (e.g., `kMCByteOrderHost`)

Functions: Title case, public functions prefixed with `MC` and module name (e.g., `MCHashPointer`)

### C++ Feature Restrictions

- **Exceptions**: Only `std::bad_alloc` may be thrown/caught. Use internal error handling.
- **STL containers**: Prohibited (`<vector>`, `<map>`, `<string>`, etc.) - use internal types
- **RTTI**: Only `dynamic_cast` is permitted
- Use `std::unique_ptr`, `std::shared_ptr`, or `MCAuto` types for lifetime management
- Always use `new (nothrow)` - never throwing `new`
- Use `nullptr` instead of `NULL`
- Braces on their own line, 4-space indentation

## Test Suites

### Script Tests (LiveCode Script)
- Location: `tests/lcs/`
- Files: `.livecodescript` - automatically discovered
- Test handlers start with `Test` prefix
- Uses `TestAssert`, `TestSkip`, `TestDiagnostic` from TestLibrary

### Builder Tests (LiveCode Builder)
- Location: `tests/lcb/stdlib/` and `tests/lcb/vm/`
- Files: `.lcb` - automatically discovered
- Uses `com.livecode.unittest` module

### Compiler Frontend Tests
- Location: `tests/lcb/compiler/frontend/`
- Files: `.compilertest`
- Uses `%TEST`/`%EXPECT`/`%ERROR` directives

### C++ Tests (Google Test)
- Locations: `libcpptest/`, `libfoundation/`, `engine/test/`
- Add new test files to `module_test_sources` in corresponding `.gyp` file
- Engine tests: edit `engine_test_source_files` in `engine/engine-sources.gypi`

## Git Workflow

### Branches
- `develop` - Experimental/next major release
- `develop-X.Y` - Stable branches for X.Y.Z releases
- `feature/` and `bugfix/` - Feature/bug fix branches

### Commit Messages
```
[[Bug <number>]] or [<feature-name>] Summary line (< 80 chars)

Detailed explanation of changes and rationale.
```

## Key Dependencies

- OpenSSL 1.1.1g
- ICU 58.2
- libcURL
- Cairo, FreeType
- libPNG, libJPEG, libGIF
- libXML, libXSLT

## Platform Requirements

### macOS/iOS Development
- macOS 13.0+ (Ventura) for building
- Xcode 14.0+ (latest stable recommended)
- Python 2.7 or 3.x
- Deployment targets: macOS 13.0+, iOS 16.0+

### Linux Development
- GCC 4.7+ or compatible compiler
- Python 2.7 or 3.x
- Supported architectures: x86_64, x86, armv6hf, armv7

### Android Development
- Android NDK
- Can build from macOS or Linux hosts
- Supported architectures: armv6, armv7, arm64, x86, x86_64

### Windows Development
- Visual Studio (MSVC 2010+)
- Can cross-compile from Linux using Wine
