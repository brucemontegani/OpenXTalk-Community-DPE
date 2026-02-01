# FindICU.cmake
# Find the OpenXTalk prebuilt ICU libraries
#
# This module defines:
#   ICU_FOUND - True if ICU was found
#   ICU_INCLUDE_DIRS - ICU include directories
#   ICU_LIBRARIES - ICU libraries to link
#   ICU_VERSION - ICU version (if determinable)
#
# Provides imported targets:
#   ICU::ICU - Main ICU target with all components
#   ICU::uc - Unicode Common library
#   ICU::i18n - Internationalization library
#   ICU::io - IO library
#   ICU::data - Data library

# Determine the platform-specific library directory
if(APPLE)
    if(IOS)
        # iOS: organized by SDK name
        if(OPENXTALK_IOS_DEVICE)
            set(_ICU_LIB_SUFFIX "ios/iphoneos")
        else()
            set(_ICU_LIB_SUFFIX "ios/iphonesimulator")
        endif()
    else()
        set(_ICU_LIB_SUFFIX "mac")
    endif()
elseif(WIN32)
    set(_ICU_LIB_SUFFIX "${OPENXTALK_UNIFORM_ARCH}-win32-${CMAKE_VS_PLATFORM_TOOLSET}_static_${CMAKE_BUILD_TYPE}")
elseif(UNIX)
    if(ANDROID)
        set(_ICU_LIB_SUFFIX "android/${CMAKE_ANDROID_ARCH}/${ANDROID_PLATFORM}")
    else()
        set(_ICU_LIB_SUFFIX "linux/${CMAKE_SYSTEM_PROCESSOR}")
    endif()
elseif(EMSCRIPTEN)
    set(_ICU_LIB_SUFFIX "emscripten/js")
endif()

# Set search paths
set(_ICU_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/lib/${_ICU_LIB_SUFFIX}"
    "${OPENXTALK_PREBUILT_DIR}/lib/mac"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/${_ICU_LIB_SUFFIX}"
    "${CMAKE_SOURCE_DIR}/prebuilt/lib/mac"
)

set(_ICU_INCLUDE_SEARCH_PATHS
    "${OPENXTALK_PREBUILT_DIR}/include"
    "${CMAKE_SOURCE_DIR}/prebuilt/include"
)

# Find include directory
find_path(ICU_INCLUDE_DIR
    NAMES unicode/uversion.h
    PATHS ${_ICU_INCLUDE_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Find libraries
find_library(ICU_UC_LIBRARY
    NAMES icuuc libicuuc sicuuc
    PATHS ${_ICU_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

find_library(ICU_I18N_LIBRARY
    NAMES icui18n libicui18n sicuin
    PATHS ${_ICU_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

find_library(ICU_IO_LIBRARY
    NAMES icuio libicuio sicuio
    PATHS ${_ICU_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

find_library(ICU_DATA_LIBRARY
    NAMES icudata libicudata sicudt
    PATHS ${_ICU_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Optional: ICU tools library (for host tools)
find_library(ICU_TU_LIBRARY
    NAMES icutu libicutu sicutu
    PATHS ${_ICU_SEARCH_PATHS}
    NO_DEFAULT_PATH
)

# Handle standard find_package arguments
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ICU
    REQUIRED_VARS
        ICU_INCLUDE_DIR
        ICU_UC_LIBRARY
        ICU_I18N_LIBRARY
        ICU_DATA_LIBRARY
)

if(ICU_FOUND)
    set(ICU_INCLUDE_DIRS ${ICU_INCLUDE_DIR})
    set(ICU_LIBRARIES
        ${ICU_I18N_LIBRARY}
        ${ICU_UC_LIBRARY}
        ${ICU_DATA_LIBRARY}
    )

    # Add optional libraries if found
    if(ICU_IO_LIBRARY)
        list(APPEND ICU_LIBRARIES ${ICU_IO_LIBRARY})
    endif()
    if(ICU_TU_LIBRARY)
        list(APPEND ICU_LIBRARIES ${ICU_TU_LIBRARY})
    endif()

    # Create imported targets
    if(NOT TARGET ICU::data)
        add_library(ICU::data STATIC IMPORTED)
        set_target_properties(ICU::data PROPERTIES
            IMPORTED_LOCATION "${ICU_DATA_LIBRARY}"
        )
    endif()

    if(NOT TARGET ICU::uc)
        add_library(ICU::uc STATIC IMPORTED)
        set_target_properties(ICU::uc PROPERTIES
            IMPORTED_LOCATION "${ICU_UC_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${ICU_INCLUDE_DIRS}"
            INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION=1"
            INTERFACE_LINK_LIBRARIES ICU::data
        )
    endif()

    if(NOT TARGET ICU::i18n)
        add_library(ICU::i18n STATIC IMPORTED)
        set_target_properties(ICU::i18n PROPERTIES
            IMPORTED_LOCATION "${ICU_I18N_LIBRARY}"
            INTERFACE_LINK_LIBRARIES ICU::uc
        )
    endif()

    if(ICU_IO_LIBRARY AND NOT TARGET ICU::io)
        add_library(ICU::io STATIC IMPORTED)
        set_target_properties(ICU::io PROPERTIES
            IMPORTED_LOCATION "${ICU_IO_LIBRARY}"
            INTERFACE_LINK_LIBRARIES ICU::uc
        )
    endif()

    if(ICU_TU_LIBRARY AND NOT TARGET ICU::tu)
        add_library(ICU::tu STATIC IMPORTED)
        set_target_properties(ICU::tu PROPERTIES
            IMPORTED_LOCATION "${ICU_TU_LIBRARY}"
            INTERFACE_LINK_LIBRARIES ICU::i18n
        )
    endif()

    # Main ICU target that links all components
    if(NOT TARGET ICU::ICU)
        add_library(ICU::ICU INTERFACE IMPORTED)
        set_target_properties(ICU::ICU PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${ICU_INCLUDE_DIRS}"
            INTERFACE_COMPILE_DEFINITIONS "U_STATIC_IMPLEMENTATION=1"
        )
        target_link_libraries(ICU::ICU INTERFACE
            ICU::i18n
            ICU::uc
            ICU::data
        )
        if(TARGET ICU::io)
            target_link_libraries(ICU::ICU INTERFACE ICU::io)
        endif()
        if(TARGET ICU::tu)
            target_link_libraries(ICU::ICU INTERFACE ICU::tu)
        endif()

        # Platform-specific dependencies
        if(WIN32)
            target_link_libraries(ICU::ICU INTERFACE advapi32)
        elseif(UNIX AND NOT APPLE AND NOT ANDROID)
            target_link_libraries(ICU::ICU INTERFACE dl)
        elseif(ANDROID)
            target_link_libraries(ICU::ICU INTERFACE stdc++ m atomic)
        endif()
    endif()

    # Try to determine version from header
    if(EXISTS "${ICU_INCLUDE_DIR}/unicode/uversion.h")
        file(STRINGS "${ICU_INCLUDE_DIR}/unicode/uversion.h" _ICU_VERSION_LINE
            REGEX "^#define U_ICU_VERSION_MAJOR_NUM")
        if(_ICU_VERSION_LINE)
            string(REGEX REPLACE ".*#define U_ICU_VERSION_MAJOR_NUM[ \t]+([0-9]+).*" "\\1" ICU_VERSION_MAJOR "${_ICU_VERSION_LINE}")
        endif()
        file(STRINGS "${ICU_INCLUDE_DIR}/unicode/uversion.h" _ICU_VERSION_LINE
            REGEX "^#define U_ICU_VERSION_MINOR_NUM")
        if(_ICU_VERSION_LINE)
            string(REGEX REPLACE ".*#define U_ICU_VERSION_MINOR_NUM[ \t]+([0-9]+).*" "\\1" ICU_VERSION_MINOR "${_ICU_VERSION_LINE}")
        endif()
        if(ICU_VERSION_MAJOR AND ICU_VERSION_MINOR)
            set(ICU_VERSION "${ICU_VERSION_MAJOR}.${ICU_VERSION_MINOR}")
            message(STATUS "ICU version: ${ICU_VERSION}")
        endif()
    endif()
endif()

mark_as_advanced(
    ICU_INCLUDE_DIR
    ICU_UC_LIBRARY
    ICU_I18N_LIBRARY
    ICU_IO_LIBRARY
    ICU_DATA_LIBRARY
    ICU_TU_LIBRARY
)
