# FindCURL.cmake
# Find the OpenXTalk prebuilt libcurl library
#
# This module defines:
#   CURL_FOUND - True if curl was found
#   CURL_INCLUDE_DIRS - curl include directories
#   CURL_LIBRARIES - curl libraries to link
#
# Provides imported target:
#   CURL::libcurl - curl library

# Determine the platform-specific library directory
if(APPLE)
    if(IOS)
        if(OPENXTALK_IOS_DEVICE)
            set(_CURL_LIB_SUFFIX "ios/iphoneos")
        else()
            set(_CURL_LIB_SUFFIX "ios/iphonesimulator")
        endif()
    else()
        set(_CURL_LIB_SUFFIX "mac")
    endif()
elseif(WIN32)
    set(_CURL_LIB_SUFFIX "${OPENXTALK_UNIFORM_ARCH}-win32")
elseif(UNIX)
    if(ANDROID)
        set(_CURL_LIB_SUFFIX "android/${CMAKE_ANDROID_ARCH}")
    else()
        set(_CURL_LIB_SUFFIX "linux/${CMAKE_SYSTEM_PROCESSOR}")
    endif()
endif()

# Set search paths
set(_CURL_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/lib/${_CURL_LIB_SUFFIX}"
    "${OPENXTALK_PREBUILT_DIR}/lib/mac"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/${_CURL_LIB_SUFFIX}"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac"
)

set(_CURL_INCLUDE_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/include"
    "${CMAKE_SOURCE_DIR}/prebuilt/include"
)

# Find include directory
find_path(CURL_INCLUDE_DIR
    NAMES curl/curl.h
    PATHS ${_CURL_INCLUDE_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Find library
find_library(CURL_LIBRARY
    NAMES curl libcurl
    PATHS ${_CURL_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(CURL
    REQUIRED_VARS
        CURL_INCLUDE_DIR
        CURL_LIBRARY
)

if(CURL_FOUND)
    set(CURL_INCLUDE_DIRS ${CURL_INCLUDE_DIR})
    set(CURL_LIBRARIES ${CURL_LIBRARY})

    # Create imported target
    if(NOT TARGET CURL::libcurl)
        add_library(CURL::libcurl STATIC IMPORTED)
        set_target_properties(CURL::libcurl PROPERTIES
            IMPORTED_LOCATION "${CURL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${CURL_INCLUDE_DIR}"
        )

        # curl depends on OpenSSL and zlib
        if(TARGET OpenSSL::SSL)
            set_property(TARGET CURL::libcurl APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES OpenSSL::SSL)
        endif()
        if(TARGET ZLIB::ZLIB)
            set_property(TARGET CURL::libcurl APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ZLIB::ZLIB)
        endif()

        # Platform-specific dependencies
        if(APPLE)
            set_property(TARGET CURL::libcurl APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES "-framework Security" "-framework SystemConfiguration")
        elseif(WIN32)
            set_property(TARGET CURL::libcurl APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ws2_32 wldap32 normaliz)
        endif()
    endif()

    # Try to determine version from header
    if(EXISTS "${CURL_INCLUDE_DIR}/curl/curlver.h")
        file(STRINGS "${CURL_INCLUDE_DIR}/curl/curlver.h" _CURL_VERSION_LINE
            REGEX "^#define LIBCURL_VERSION ")
        if(_CURL_VERSION_LINE)
            string(REGEX REPLACE ".*\"([0-9]+\\.[0-9]+\\.[0-9]+)\".*" "\\1" CURL_VERSION "${_CURL_VERSION_LINE}")
            message(STATUS "CURL version: ${CURL_VERSION}")
        endif()
    endif()
endif()

mark_as_advanced(
    CURL_INCLUDE_DIR
    CURL_LIBRARY
)
