# OpenXTalk - macOS Platform Configuration
# Settings specific to macOS builds

message(STATUS "Configuring for macOS")

# Deployment target - macOS 12.0 (Monterey) as per modernization plan
# This covers 4 major versions and is fully optimized for Apple Silicon
if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS deployment target" FORCE)
endif()
message(STATUS "macOS deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")

# Architecture configuration
# Default to native architecture, but support Universal Binaries
if(NOT CMAKE_OSX_ARCHITECTURES)
    # Default to the current architecture for faster development builds
    # For release builds, use the preset or specify -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
    set(CMAKE_OSX_ARCHITECTURES "${CMAKE_SYSTEM_PROCESSOR}" CACHE STRING "macOS architectures" FORCE)
endif()
message(STATUS "macOS architectures: ${CMAKE_OSX_ARCHITECTURES}")

# Platform definitions from mac.gypi
add_compile_definitions(
    TARGET_PLATFORM_MACOS_X
    _MACOSX
)

# Server mode definitions (applied conditionally to server targets)
# These will be added per-target for server engine builds
set(OPENXTALK_SERVER_DEFINITIONS
    _SERVER
    _MAC_SERVER
)

# macOS-specific frameworks
set(OPENXTALK_MACOS_FRAMEWORKS
    AppKit
    Cocoa
    Carbon
    Security
    SystemConfiguration
    IOKit
    CoreServices
    CoreGraphics
    CoreText
    ImageIO
    AudioToolbox
    AudioUnit
    AVFoundation
    CoreMedia
    CoreVideo
    QuartzCore
    WebKit
)

# Linker flags for deployment target
# This ensures the binary is marked for the correct minimum OS version
add_link_options(
    -Wl,-platform_version,macos,${CMAKE_OSX_DEPLOYMENT_TARGET},${CMAKE_OSX_DEPLOYMENT_TARGET}
)

# RPATH settings for macOS bundles
set(CMAKE_INSTALL_RPATH "@executable_path/../Frameworks")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_MACOSX_RPATH TRUE)

# Prebuilt library paths for macOS
set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/mac")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")
set(OPENXTALK_PREBUILT_BIN_DIR "${OPENXTALK_PREBUILT_DIR}/bin/mac")
set(OPENXTALK_PREBUILT_SHARE_DIR "${OPENXTALK_PREBUILT_DIR}/share")

# Function to configure a macOS application target
function(openxtalk_configure_macos_app TARGET_NAME)
    cmake_parse_arguments(ARG "SERVER" "BUNDLE_ID;BUNDLE_NAME" "FRAMEWORKS" ${ARGN})

    # Set bundle properties
    set_target_properties(${TARGET_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "${ARG_BUNDLE_NAME}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${ARG_BUNDLE_ID}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${ARG_BUNDLE_ID}"
    )

    # Apply server definitions if needed
    if(ARG_SERVER)
        target_compile_definitions(${TARGET_NAME} PRIVATE ${OPENXTALK_SERVER_DEFINITIONS})
    endif()

    # Link frameworks
    if(ARG_FRAMEWORKS)
        openxtalk_link_frameworks(${TARGET_NAME} ${ARG_FRAMEWORKS})
    endif()
endfunction()

# Helper function to create Universal Binary from architecture-specific builds
function(openxtalk_create_universal_binary OUTPUT_PATH)
    cmake_parse_arguments(ARG "" "" "INPUTS" ${ARGN})

    add_custom_command(
        OUTPUT ${OUTPUT_PATH}
        COMMAND lipo -create ${ARG_INPUTS} -output ${OUTPUT_PATH}
        DEPENDS ${ARG_INPUTS}
        COMMENT "Creating Universal Binary: ${OUTPUT_PATH}"
    )
endfunction()

# Configure pkgbuild/productbuild for installer creation
find_program(PKGBUILD_EXECUTABLE pkgbuild)
find_program(PRODUCTBUILD_EXECUTABLE productbuild)
if(PKGBUILD_EXECUTABLE AND PRODUCTBUILD_EXECUTABLE)
    message(STATUS "Installer tools available: pkgbuild, productbuild")
    set(OPENXTALK_CAN_BUILD_INSTALLER TRUE)
else()
    message(STATUS "Installer tools not found - installer target will be unavailable")
    set(OPENXTALK_CAN_BUILD_INSTALLER FALSE)
endif()

# Code signing configuration
set(OPENXTALK_CODE_SIGN_IDENTITY "" CACHE STRING "Code signing identity")
set(OPENXTALK_DEVELOPMENT_TEAM "" CACHE STRING "Apple Development Team ID")

if(OPENXTALK_CODE_SIGN_IDENTITY)
    message(STATUS "Code signing enabled: ${OPENXTALK_CODE_SIGN_IDENTITY}")
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${OPENXTALK_CODE_SIGN_IDENTITY}")
endif()

if(OPENXTALK_DEVELOPMENT_TEAM)
    message(STATUS "Development team: ${OPENXTALK_DEVELOPMENT_TEAM}")
    set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${OPENXTALK_DEVELOPMENT_TEAM}")
endif()

# Hardened runtime (required for notarization)
option(OPENXTALK_HARDENED_RUNTIME "Enable hardened runtime for notarization" OFF)
if(OPENXTALK_HARDENED_RUNTIME)
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES)
    message(STATUS "Hardened runtime enabled")
endif()
