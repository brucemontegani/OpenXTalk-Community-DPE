# OpenXTalk - Android Platform Configuration
# Settings specific to Android builds

message(STATUS "Configuring for Android")

# Platform definitions
add_compile_definitions(
    TARGET_PLATFORM_MOBILE
    TARGET_SUBPLATFORM_ANDROID
    _MOBILE
    _ANDROID_MOBILE
    ANDROID
)

# Prebuilt library paths
set(OPENXTALK_PREBUILT_LIB_DIR "${OPENXTALK_PREBUILT_DIR}/lib/android/${CMAKE_ANDROID_ARCH}/${ANDROID_PLATFORM}")
set(OPENXTALK_PREBUILT_INCLUDE_DIR "${OPENXTALK_PREBUILT_DIR}/include")

message(STATUS "Android platform configured")
