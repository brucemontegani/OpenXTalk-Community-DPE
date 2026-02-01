# FindZLIB.cmake
# Find the OpenXTalk prebuilt zlib library
#
# This module defines:
#   ZLIB_FOUND - True if zlib was found
#   ZLIB_INCLUDE_DIRS - zlib include directories
#   ZLIB_LIBRARIES - zlib libraries to link
#
# Provides imported target:
#   ZLIB::ZLIB - zlib library

# Determine the platform-specific library directory
if(APPLE)
    if(IOS)
        if(OPENXTALK_IOS_DEVICE)
            set(_ZLIB_LIB_SUFFIX "ios/iphoneos")
        else()
            set(_ZLIB_LIB_SUFFIX "ios/iphonesimulator")
        endif()
    else()
        set(_ZLIB_LIB_SUFFIX "mac")
    endif()
elseif(WIN32)
    set(_ZLIB_LIB_SUFFIX "${OPENXTALK_UNIFORM_ARCH}-win32")
elseif(UNIX)
    if(ANDROID)
        set(_ZLIB_LIB_SUFFIX "android/${CMAKE_ANDROID_ARCH}")
    else()
        set(_ZLIB_LIB_SUFFIX "linux/${CMAKE_SYSTEM_PROCESSOR}")
    endif()
elseif(EMSCRIPTEN)
    set(_ZLIB_LIB_SUFFIX "emscripten/js")
endif()

# Set search paths - check thirdparty first (built from source), then prebuilt
set(_ZLIB_SEARCH_PATHS
    "${CMAKE_BINARY_DIR}/thirdparty/libz"
    "${OPENXTALK_THIRDPARTY_DIR}/libz"
    "${OPENXTALK_PREBUILT_DIR}/lib/${_ZLIB_LIB_SUFFIX}"
    "${OPENXTALK_PREBUILT_DIR}/lib/mac"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/${_ZLIB_LIB_SUFFIX}"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac"
)

set(_ZLIB_INCLUDE_SEARCH_PATHS
    "${OPENXTALK_THIRDPARTY_DIR}/libz/include"
    "${OPENXTALK_THIRDPARTY_DIR}/libz/src"
    "${OPENXTALK_PREBUILT_DIR}/include"
    "${CMAKE_SOURCE_DIR}/prebuilt/include"
    "${CMAKE_SOURCE_DIR}/thirdparty/libz/include"
    "${CMAKE_SOURCE_DIR}/thirdparty/libz/src"
)

# Find include directory
find_path(ZLIB_INCLUDE_DIR
    NAMES zlib.h
    PATHS ${_ZLIB_INCLUDE_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Find library
find_library(ZLIB_LIBRARY
    NAMES z libz zlib
    PATHS ${_ZLIB_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ZLIB
    REQUIRED_VARS
        ZLIB_INCLUDE_DIR
        ZLIB_LIBRARY
)

if(ZLIB_FOUND)
    set(ZLIB_INCLUDE_DIRS ${ZLIB_INCLUDE_DIR})
    set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})

    # Create imported target
    if(NOT TARGET ZLIB::ZLIB)
        add_library(ZLIB::ZLIB STATIC IMPORTED)
        set_target_properties(ZLIB::ZLIB PROPERTIES
            IMPORTED_LOCATION "${ZLIB_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${ZLIB_INCLUDE_DIR}"
        )
    endif()

    # Try to determine version from header
    if(EXISTS "${ZLIB_INCLUDE_DIR}/zlib.h")
        file(STRINGS "${ZLIB_INCLUDE_DIR}/zlib.h" _ZLIB_VERSION_LINE
            REGEX "^#define ZLIB_VERSION")
        if(_ZLIB_VERSION_LINE)
            string(REGEX REPLACE ".*\"([0-9]+\\.[0-9]+\\.[0-9]+)\".*" "\\1" ZLIB_VERSION "${_ZLIB_VERSION_LINE}")
            message(STATUS "ZLIB version: ${ZLIB_VERSION}")
        endif()
    endif()
endif()

mark_as_advanced(
    ZLIB_INCLUDE_DIR
    ZLIB_LIBRARY
)
