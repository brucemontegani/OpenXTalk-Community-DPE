# OpenXTalk - Darwin (macOS/iOS) Shared Settings
# Common settings for all Apple platforms

message(STATUS "Configuring for Darwin platform")

# Ensure we have Objective-C/C++ support
enable_language(OBJC)
enable_language(OBJCXX)

# Default SDK - use the system default if not specified
if(NOT CMAKE_OSX_SYSROOT)
    # Let CMake auto-detect the SDK
    # This works with modern Xcode installations
endif()

# Compiler settings from mac.gypi
# Disable C++ exceptions (only std::bad_alloc allowed per code style)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-exceptions")

# Disable RTTI (except dynamic_cast)
# Note: Can't fully disable RTTI as dynamic_cast is allowed
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-rtti")

# Use libc++ (modern C++ library)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")

# Symbol visibility
set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_C_VISIBILITY_PRESET hidden)

# Warning flags from mac.gypi
set(OPENXTALK_WARNING_FLAGS
    -Wall
    -Wextra
    -Wno-conversion
    -Wno-shorten-64-to-32
    -Werror=declaration-after-statement
    -Werror=delete-non-virtual-dtor
    -Werror=overloaded-virtual
    -Wno-unused-parameter
    -Werror=uninitialized
    -Werror=return-type
    -Werror=tautological-compare
    -Werror=logical-not-parentheses
    -Werror=conversion-null
    -Werror=missing-declarations
    -Werror=mismatched-new-delete
    -Werror=parentheses
    -Werror=unused-variable
    -Werror=constant-logical-operand
    -Werror=unknown-pragmas
    -Werror=missing-field-initializers
    -Werror=objc-literal-compare
    -Werror=shadow
    -Werror=unreachable-code
    -Werror=enum-compare
    -Werror=switch
)

# Apply warning flags
add_compile_options(${OPENXTALK_WARNING_FLAGS})

# Suppress deprecated function warnings (as per mac.gypi)
add_compile_options(-Wno-deprecated-declarations)

# Framework search paths
set(CMAKE_FRAMEWORK_PATH "${CMAKE_OSX_SYSROOT}/System/Library/Frameworks")

# Function to create a macOS/iOS application bundle
function(openxtalk_create_app_bundle TARGET_NAME)
    set_target_properties(${TARGET_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/engine/rsrc/Info.plist.in"
        MACOSX_BUNDLE_BUNDLE_NAME "${TARGET_NAME}"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.openxtalk.${TARGET_NAME}"
    )
endfunction()

# Function to link Apple frameworks
function(openxtalk_link_frameworks TARGET_NAME)
    foreach(FRAMEWORK ${ARGN})
        target_link_libraries(${TARGET_NAME} PRIVATE "-framework ${FRAMEWORK}")
    endforeach()
endfunction()

# Common Apple frameworks used across the project
set(OPENXTALK_COMMON_FRAMEWORKS
    CoreFoundation
    Foundation
)

# Platform-specific build output directories for Xcode
if(CMAKE_GENERATOR MATCHES "Xcode")
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>/lib)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>/lib)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>/bin)
endif()
