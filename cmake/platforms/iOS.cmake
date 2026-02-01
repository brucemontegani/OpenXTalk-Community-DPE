# OpenXTalk - iOS Platform Configuration
# Settings specific to iOS builds

message(STATUS "Configuring for iOS")

# Deployment target - iOS 15.0 as per modernization plan
# Covers iPhone 6s+ and vast majority of active devices
if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0" CACHE STRING "Minimum iOS deployment target" FORCE)
endif()
message(STATUS "iOS deployment target: ${CMAKE_OSX_DEPLOYMENT_TARGET}")

# iOS SDK detection
# CMAKE_OSX_SYSROOT should be set via toolchain file or preset
# e.g., iphoneos, iphonesimulator
if(NOT CMAKE_OSX_SYSROOT)
    # Default to device SDK
    set(CMAKE_OSX_SYSROOT "iphoneos" CACHE STRING "iOS SDK" FORCE)
endif()

# Determine if building for device or simulator
string(TOLOWER "${CMAKE_OSX_SYSROOT}" SDK_LOWER)
if(SDK_LOWER MATCHES "simulator")
    set(OPENXTALK_IOS_SIMULATOR TRUE)
    set(OPENXTALK_IOS_DEVICE FALSE)
    message(STATUS "Building for iOS Simulator")
else()
    set(OPENXTALK_IOS_SIMULATOR FALSE)
    set(OPENXTALK_IOS_DEVICE TRUE)
    message(STATUS "Building for iOS Device")
endif()

# Architecture configuration
if(NOT CMAKE_OSX_ARCHITECTURES)
    if(OPENXTALK_IOS_SIMULATOR)
        # Simulator: x86_64 for Intel Macs, arm64 for Apple Silicon Macs
        set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "iOS Simulator architectures" FORCE)
    else()
        # Device: arm64 only (armv7 support dropped with iOS 11+)
        set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "iOS Device architectures" FORCE)
    endif()
endif()
message(STATUS "iOS architectures: ${CMAKE_OSX_ARCHITECTURES}")

# Platform definitions
add_compile_definitions(
    TARGET_PLATFORM_MOBILE
    TARGET_SUBPLATFORM_IPHONE
    _MOBILE
    _IOS_MOBILE
)

# iOS-specific frameworks
set(OPENXTALK_IOS_FRAMEWORKS
    UIKit
    Foundation
    CoreFoundation
    CoreGraphics
    CoreText
    CoreMedia
    CoreVideo
    AVFoundation
    AudioToolbox
    Security
    SystemConfiguration
    MobileCoreServices
    QuartzCore
    ImageIO
    MediaPlayer
    StoreKit
    AddressBook
    AddressBookUI
    MessageUI
    AssetsLibrary
    Photos
    PhotosUI
    EventKit
    EventKitUI
    GameKit
    Social
    Accounts
    CoreMotion
    CoreLocation
    MapKit
    UserNotifications
    WebKit
)

# Prebuilt library paths for iOS
# iOS libraries are organized by SDK name (iphoneos, iphonesimulator)
if(OPENXTALK_IOS_DEVICE)
    set(OPENXTALK_IOS_SDK_NAME "iphoneos")
else()
    set(OPENXTALK_IOS_SDK_NAME "iphonesimulator")
endif()

set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/ios/${OPENXTALK_IOS_SDK_NAME}")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")

# Bitcode configuration (deprecated in Xcode 14, but still present in some builds)
option(OPENXTALK_ENABLE_BITCODE "Enable bitcode for iOS" OFF)
if(OPENXTALK_ENABLE_BITCODE)
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE YES)
else()
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)
endif()

# Function to configure an iOS application target
function(openxtalk_configure_ios_app TARGET_NAME)
    cmake_parse_arguments(ARG "" "BUNDLE_ID;BUNDLE_NAME" "FRAMEWORKS" ${ARGN})

    # Set bundle properties
    set_target_properties(${TARGET_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "${ARG_BUNDLE_NAME}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "${ARG_BUNDLE_ID}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${ARG_BUNDLE_ID}"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"  # iPhone and iPad
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "${CMAKE_OSX_DEPLOYMENT_TARGET}"
    )

    # Link frameworks
    if(ARG_FRAMEWORKS)
        openxtalk_link_frameworks(${TARGET_NAME} ${ARG_FRAMEWORKS})
    else()
        # Link default iOS frameworks
        openxtalk_link_frameworks(${TARGET_NAME} ${OPENXTALK_IOS_FRAMEWORKS})
    endif()
endfunction()

# Code signing configuration for iOS
# Required for device builds
set(OPENXTALK_CODE_SIGN_IDENTITY "" CACHE STRING "Code signing identity")
set(OPENXTALK_DEVELOPMENT_TEAM "" CACHE STRING "Apple Development Team ID")
set(OPENXTALK_PROVISIONING_PROFILE "" CACHE STRING "Provisioning profile name or UUID")

if(OPENXTALK_CODE_SIGN_IDENTITY)
    set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "${OPENXTALK_CODE_SIGN_IDENTITY}")
endif()

if(OPENXTALK_DEVELOPMENT_TEAM)
    set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${OPENXTALK_DEVELOPMENT_TEAM}")
endif()

if(OPENXTALK_PROVISIONING_PROFILE)
    set(CMAKE_XCODE_ATTRIBUTE_PROVISIONING_PROFILE_SPECIFIER "${OPENXTALK_PROVISIONING_PROFILE}")
endif()

# For device builds, code signing is required
if(OPENXTALK_IOS_DEVICE AND NOT OPENXTALK_CODE_SIGN_IDENTITY)
    message(WARNING "Building for iOS device without code signing identity. Set OPENXTALK_CODE_SIGN_IDENTITY for device deployment.")
endif()
