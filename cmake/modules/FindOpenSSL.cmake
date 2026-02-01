# FindOpenSSL.cmake
# Find the OpenXTalk prebuilt OpenSSL libraries
#
# This module defines:
#   OPENSSL_FOUND - True if OpenSSL was found
#   OPENSSL_INCLUDE_DIR - OpenSSL include directory
#   OPENSSL_LIBRARIES - OpenSSL libraries to link
#   OPENSSL_VERSION - OpenSSL version
#
# Provides imported targets:
#   OpenSSL::SSL - SSL library
#   OpenSSL::Crypto - Crypto library

# Determine the platform-specific library directory
if(APPLE)
    if(IOS)
        if(OPENXTALK_IOS_DEVICE)
            set(_SSL_LIB_SUFFIX "ios/iphoneos")
        else()
            set(_SSL_LIB_SUFFIX "ios/iphonesimulator")
        endif()
    else()
        set(_SSL_LIB_SUFFIX "mac")
    endif()
elseif(WIN32)
    set(_SSL_LIB_SUFFIX "${OPENXTALK_UNIFORM_ARCH}-win32-${CMAKE_VS_PLATFORM_TOOLSET}_static_${CMAKE_BUILD_TYPE}")
elseif(UNIX)
    if(ANDROID)
        set(_SSL_LIB_SUFFIX "android/${CMAKE_ANDROID_ARCH}/${ANDROID_PLATFORM}")
    else()
        set(_SSL_LIB_SUFFIX "linux/${CMAKE_SYSTEM_PROCESSOR}")
    endif()
elseif(EMSCRIPTEN)
    set(_SSL_LIB_SUFFIX "emscripten/js")
endif()

# Set search paths
set(_SSL_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/lib/${_SSL_LIB_SUFFIX}"
    "${OPENXTALK_PREBUILT_DIR}/lib/mac"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/${_SSL_LIB_SUFFIX}"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac"
)

set(_SSL_INCLUDE_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/include"
    "${CMAKE_SOURCE_DIR}/prebuilt/include"
)

# Find include directory
find_path(OPENSSL_INCLUDE_DIR
    NAMES openssl/ssl.h
    PATHS ${_SSL_INCLUDE_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Find libraries
find_library(OPENSSL_SSL_LIBRARY
    NAMES ssl libssl
    PATHS ${_SSL_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

find_library(OPENSSL_CRYPTO_LIBRARY
    NAMES crypto libcrypto
    PATHS ${_SSL_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenSSL
    REQUIRED_VARS
        OPENSSL_INCLUDE_DIR
        OPENSSL_SSL_LIBRARY
        OPENSSL_CRYPTO_LIBRARY
)

if(OPENSSL_FOUND)
    set(OPENSSL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
    set(OPENSSL_LIBRARIES
        ${OPENSSL_SSL_LIBRARY}
        ${OPENSSL_CRYPTO_LIBRARY}
    )

    # Create imported targets
    if(NOT TARGET OpenSSL::Crypto)
        add_library(OpenSSL::Crypto STATIC IMPORTED)
        set_target_properties(OpenSSL::Crypto PROPERTIES
            IMPORTED_LOCATION "${OPENSSL_CRYPTO_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
        )
        # Platform-specific dependencies
        if(WIN32)
            set_property(TARGET OpenSSL::Crypto APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ws2_32 crypt32)
        elseif(UNIX AND NOT APPLE)
            set_property(TARGET OpenSSL::Crypto APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES dl pthread)
        endif()
    endif()

    if(NOT TARGET OpenSSL::SSL)
        add_library(OpenSSL::SSL STATIC IMPORTED)
        set_target_properties(OpenSSL::SSL PROPERTIES
            IMPORTED_LOCATION "${OPENSSL_SSL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENSSL_INCLUDE_DIR}"
            INTERFACE_LINK_LIBRARIES OpenSSL::Crypto
        )
    endif()

    # Try to determine version from header
    if(EXISTS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h")
        file(STRINGS "${OPENSSL_INCLUDE_DIR}/openssl/opensslv.h" _SSL_VERSION_LINE
            REGEX "^#define OPENSSL_VERSION_TEXT")
        if(_SSL_VERSION_LINE)
            string(REGEX REPLACE ".*\"OpenSSL ([0-9]+\\.[0-9]+\\.[0-9]+[a-z]?).*\".*" "\\1" OPENSSL_VERSION "${_SSL_VERSION_LINE}")
            message(STATUS "OpenSSL version: ${OPENSSL_VERSION}")
        endif()
    endif()
endif()

mark_as_advanced(
    OPENSSL_INCLUDE_DIR
    OPENSSL_SSL_LIBRARY
    OPENSSL_CRYPTO_LIBRARY
)
