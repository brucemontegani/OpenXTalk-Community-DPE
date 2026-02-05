# OpenXTalk Development Notes

Technical documentation for contributors working on the CMake build system.

## Build System Architecture

### Overview

The build system was migrated from GYP (Generate Your Projects) to CMake. GYP was Google's build system used by Chromium, but it's no longer maintained and had issues with modern Python and toolchains.

```
CMakeLists.txt (root)
├── thirdparty/          → Third-party libraries (zlib, libpng, libxml2, etc.)
├── libcore/             → Core utilities
├── libfoundation/       → Foundation library (strings, arrays, etc.)
├── libgraphics/         → Graphics and rendering
├── libscript/           → Script execution engine
├── toolchain/           → LCB compiler (lc-compile, lc-run)
├── libexternal/         → External plugin API
├── engine/              → Main engine (IDE, standalone, server variants)
├── extensions/          → LCB widgets and libraries
├── revxml/              → XML external plugin
├── revzip/              → ZIP external plugin
└── ...
```

### Key Build Targets

| Target | Description |
|--------|-------------|
| `LiveCode-Community` | IDE application (development engine) |
| `LiveCode-Community-Standalone` | Standalone engine for deployment |
| `LiveCode-Community-Server` | Headless server engine |
| `lc-compile-stage3` | Final LCB compiler |
| `lcb-extensions` | Compiled widget/library extensions |
| `external-revxml` | XML parsing external |
| `external-revzip` | ZIP archive external |

### Bootstrap Process

The LCB (LiveCode Builder) compiler bootstraps itself in three stages:

1. **Stage 1**: Minimal compiler built with precompiled grammar
2. **Stage 2**: Compiler rebuilt using Stage 1
3. **Stage 3**: Final compiler rebuilt using Stage 2

This ensures the compiler can compile itself.

## Critical Dependencies

### Extension Loading Chain

The IDE's extension system has a specific dependency chain:

```
IDE Startup
    ↓
revxml.bundle loads          ← Required for XML parsing
    ↓
extensionFetchMetadata()     ← Parses manifest.xml files
    ↓
LCB extensions load          ← Widgets become available
    ↓
Start Center renders         ← Uses tile, svgpath, browser widgets
```

**If revxml fails to load, NO extensions load, and the Start Center is blank.**

### Why revxml is Critical

The extension loader calls `revXMLCreateTree` to parse each extension's `manifest.xml`. This function is provided by `revxml.bundle`. Without it:
- `extensionFetchMetadata` fails silently
- Zero extensions are registered
- All LCB widgets render as empty rectangles

### Code Signing Requirement

macOS requires all bundles to be code-signed before `dlopen()` will load them. Even ad-hoc signing (no Apple Developer identity) is sufficient:

```cmake
add_custom_command(TARGET external-revxml POST_BUILD
    COMMAND codesign --force --sign - "${CMAKE_BINARY_DIR}/$<CONFIG>/bin/revxml.bundle"
)
```

Without this, you get:
```
dlopen failed: code signature not valid for use in process: Trying to load an unsigned library
```

## Third-Party Libraries

### Built from Source

| Library | Location | Notes |
|---------|----------|-------|
| zlib | `thirdparty/libz/` | Includes gzip functions (gz*.c) |
| libpng | `thirdparty/libpng/` | PNG image support |
| libjpeg | `thirdparty/libjpeg/` | JPEG image support |
| libgif | `thirdparty/libgif/` | GIF image support |
| libpcre | `thirdparty/libpcre/` | Regular expressions |
| libsqlite | `thirdparty/libsqlite/` | SQLite database |
| libxml2 | `thirdparty/libxml/` | XML parsing (for revxml) |
| libxslt | `thirdparty/libxslt/` | XSLT transforms (for revxml) |
| libzip | `thirdparty/libzip/` | ZIP archives (for revzip) |
| Skia | `thirdparty/libskia/` | 2D graphics engine |

### Prebuilt Libraries

| Library | Location | Notes |
|---------|----------|-------|
| ICU 58.2 | `prebuilt/lib/mac/` | Unicode support (universal binary) |
| OpenSSL 1.1.1g | `prebuilt/lib/mac/` | SSL/TLS (universal binary) |

Prebuilt libraries are committed to the repo for convenience. To rebuild them:

```bash
cd prebuilt
./build-libraries.sh
```

## Common Issues and Solutions

### Start Center is Blank

**Cause**: revxml.bundle failed to load
**Check**: Run IDE from terminal, look for `dlopen failed` or `revxml` errors
**Fix**: Ensure revxml.bundle exists and is code-signed

### Extension Not Loading

**Cause**: Missing manifest.xml or malformed XML
**Check**: Look in `build-mac-debug/Debug/bin/packaged_extensions/<extension-id>/`
**Fix**: Rebuild extensions with `xcodebuild -target lcb-extensions`

### Undefined Symbol Errors

**Cause**: Missing library dependency or link order issue
**Check**: The symbol name tells you which library is missing
**Fix**: Add the library to `target_link_libraries()` in CMakeLists.txt

### ICU/OpenSSL Not Found

**Cause**: Prebuilt libraries missing or in wrong location
**Check**: `prebuilt/lib/mac/libicuuc.a` should exist
**Fix**: Ensure prebuilt directory wasn't gitignored; check `.gitignore`

## File Generation

The build generates several files that aren't in source control:

| Generated File | Purpose |
|----------------|---------|
| `revbuild.h` | Version information |
| `hashedstrings.cpp` | Localized string hashes |
| `sslstubs.cpp` | OpenSSL function stubs |
| `startupstack.cpp` | Embedded startup stack bytecode |
| `*.lci` | LCB module interfaces |
| `*.lcm` | Compiled LCB bytecode |

## Debugging Tips

### Run IDE from Terminal

```bash
./build-mac-debug/Debug/bin/LiveCode-Community.app/Contents/MacOS/LiveCode-Community
```

This shows error messages that the GUI hides.

### Check Extension Loading

Look for these in terminal output:
- `MCU_library_load` - external loading attempts
- `dlopen failed` - bundle loading failures
- `extensionInitialize` - extension initialization errors

### Xcode Debugging

Open the generated Xcode project:
```bash
open build-mac-debug/OpenXTalk.xcodeproj
```

Set `LiveCode-Community` as the active scheme and debug normally.

## Architecture Notes

### Engine Modes

The engine is built in four variants from the same source:

| Mode | Purpose | Preprocessor Define |
|------|---------|---------------------|
| development | IDE with debugger | `MODE_DEVELOPMENT` |
| standalone | Embedded in apps | `MODE_STANDALONE` |
| server | Headless/CGI | `MODE_SERVER` |
| installer | Installer builder | `MODE_INSTALLER` |

### Platform Defines

| Platform | Defines |
|----------|---------|
| macOS | `_MACOSX`, `TARGET_PLATFORM_MACOS_X` |
| iOS | `TARGET_SUBPLATFORM_IPHONE` |
| Linux | `_LINUX`, `TARGET_PLATFORM_LINUX` |
| Windows | `_WINDOWS`, `TARGET_PLATFORM_WINDOWS` |
| Android | `TARGET_SUBPLATFORM_ANDROID` |

## Contributing

1. Make changes in a feature branch
2. Test with both Debug and Release builds
3. Ensure `make compile-mac` succeeds
4. Run the IDE and verify Start Center loads
5. Submit PR with clear description

---

*Last updated: February 2025*
