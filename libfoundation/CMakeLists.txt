# libfoundation - OpenXTalk Foundation Library
# Depends on libcore, ICU, zlib, libffi

# Public header files
set(LIBFOUNDATION_HEADERS
    include/foundation.h
    include/foundation-auto.h
    include/foundation-bidi.h
    include/foundation-chunk.h
    include/foundation-filters.h
    include/foundation-inline.h
    include/foundation-locale.h
    include/foundation-math.h
    include/foundation-objc.h
    include/foundation-span.h
    include/foundation-stdlib.h
    include/foundation-system.h
    include/foundation-text.h
    include/foundation-unicode.h
    include/system-commandline.h
    include/system-error.h
    include/system-file.h
    include/system-info.h
    include/system-init.h
    include/system-library.h
    include/system-random.h
    include/system-stream.h
)

# Private header files
set(LIBFOUNDATION_PRIVATE_HEADERS
    src/foundation-private.h
    src/foundation-unicode-private.h
    src/foundation-hash.h
    src/foundation-string-hash.h
    src/foundation-java-private.h
    src/system-private.h
)

# Core source files (all platforms)
set(LIBFOUNDATION_SOURCES
    src/foundation-array.cpp
    src/foundation-bidi.cpp
    src/foundation-chunk.cpp
    src/foundation-core.cpp
    src/foundation-custom.cpp
    src/foundation-data.cpp
    src/foundation-debug.cpp
    src/foundation-error.cpp
    src/foundation-filters.cpp
    src/foundation-foreign.cpp
    src/foundation-handler.cpp
    src/foundation-java.cpp
    src/foundation-java-private.cpp
    src/foundation-list.cpp
    src/foundation-locale.cpp
    src/foundation-math.cpp
    src/foundation-name.cpp
    src/foundation-number.cpp
    src/foundation-pickle.cpp
    src/foundation-proper-list.cpp
    src/foundation-record.cpp
    src/foundation-set.cpp
    src/foundation-stream.cpp
    src/foundation-string.cpp
    src/foundation-text.cpp
    src/foundation-typeconvert.cpp
    src/foundation-typeinfo.cpp
    src/foundation-unicode.cpp
    src/foundation-unicodechars.cpp
    src/foundation-value.cpp
    src/system-commandline.cpp
    src/system-error.cpp
    src/system-file.cpp
    src/system-info.cpp
    src/system-init.cpp
    src/system-library.cpp
    src/system-random.cpp
    src/system-stream.cpp
)

# Platform-specific system library headers (included, not compiled separately)
set(LIBFOUNDATION_SYSTEM_LIBRARY_HEADERS
    src/system-library-android.hpp
    src/system-library-emscripten.hpp
    src/system-library-ios.hpp
    src/system-library-linux.hpp
    src/system-library-mac.hpp
    src/system-library-posix.hpp
    src/system-library-static.hpp
    src/system-library-w32.hpp
)

# POSIX-specific sources (macOS, iOS, Linux, Android)
if(UNIX)
    list(APPEND LIBFOUNDATION_SOURCES
        src/system-file-posix.cpp
    )
endif()

# Windows-specific sources
if(WIN32)
    list(APPEND LIBFOUNDATION_SOURCES
        src/system-file-w32.cpp
    )
endif()

# Apple-specific sources (macOS and iOS)
if(APPLE)
    list(APPEND LIBFOUNDATION_SOURCES
        src/foundation-cf.cpp
        src/foundation-objc.mm
    )
else()
    # Non-Apple platforms need the dummy objc file
    list(APPEND LIBFOUNDATION_SOURCES
        src/foundation-objc-dummy.cpp
    )
endif()

# Emscripten-specific sources
if(EMSCRIPTEN)
    list(APPEND LIBFOUNDATION_SOURCES
        src/foundation-ffi-js.cpp
    )
endif()

# Create the library
add_library(libFoundation STATIC
    ${LIBFOUNDATION_HEADERS}
    ${LIBFOUNDATION_PRIVATE_HEADERS}
    ${LIBFOUNDATION_SOURCES}
    ${LIBFOUNDATION_SYSTEM_LIBRARY_HEADERS}
)

# Set the library output name
set_target_properties(libFoundation PROPERTIES
    OUTPUT_NAME "Foundation"
    PREFIX "lib"
)

# Include directories
target_include_directories(libFoundation
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Dependencies
if(TARGET ICU::ICU)
    target_link_libraries(libFoundation PUBLIC ICU::ICU)
elseif(ICU_FOUND)
    target_include_directories(libFoundation PUBLIC ${ICU_INCLUDE_DIRS})
    target_link_libraries(libFoundation PUBLIC ${ICU_LIBRARIES})
endif()

if(TARGET ZLIB::ZLIB)
    target_link_libraries(libFoundation PRIVATE ZLIB::ZLIB)
elseif(TARGET libz)
    target_link_libraries(libFoundation PRIVATE libz)
elseif(ZLIB_FOUND)
    target_link_libraries(libFoundation PRIVATE ${ZLIB_LIBRARIES})
endif()

# Link libffi from thirdparty if available, otherwise find it
if(TARGET libffi)
    target_link_libraries(libFoundation PRIVATE libffi)
else()
    find_library(FFI_LIBRARY ffi)
    if(FFI_LIBRARY)
        target_link_libraries(libFoundation PRIVATE ${FFI_LIBRARY})
    endif()
endif()

# Platform-specific link libraries
if(APPLE)
    target_link_libraries(libFoundation
        PRIVATE
            "-framework CoreFoundation"
            "-framework Foundation"
    )
endif()

if(ANDROID)
    target_link_libraries(libFoundation
        PRIVATE
            log
            m
    )
endif()

if(WIN32)
    target_link_libraries(libFoundation
        PRIVATE
            oleaut32
    )
endif()

# Java support (macOS and Linux, not iOS or Emscripten)
if((APPLE AND NOT IOS) OR (UNIX AND NOT APPLE AND NOT EMSCRIPTEN AND NOT ANDROID))
    # Try to find Java
    find_package(Java COMPONENTS Development)
    find_package(JNI)

    if(JNI_FOUND)
        target_compile_definitions(libFoundation PRIVATE TARGET_SUPPORTS_JAVA)
        target_include_directories(libFoundation PRIVATE ${JNI_INCLUDE_DIRS})

        # Generate JVM stubs (placeholder - this would need the actual perl script)
        # For now, we'll handle this in a custom command if needed
    endif()
endif()

# Generated ICU data (will be created by a custom command)
# The minimal ICU data file needs to be generated during build
set(LIBFOUNDATION_GENERATED_DIR "${CMAKE_BINARY_DIR}/generated/libfoundation")
file(MAKE_DIRECTORY ${LIBFOUNDATION_GENERATED_DIR})

# Add a placeholder for the generated ICU data
# This will be properly implemented when we set up the ICU data generation
target_include_directories(libFoundation PRIVATE ${LIBFOUNDATION_GENERATED_DIR})

# Create an alias for consistent naming
add_library(OpenXTalk::Foundation ALIAS libFoundation)

# Tests
if(BUILD_TESTING)
    set(LIBFOUNDATION_TEST_SOURCES
        test/environment.cpp
        test/test_foreign.cpp
        test/test_hash.cpp
        test/test_memory.cpp
        test/test_name.cpp
        test/test_proper-list.cpp
        test/test_string.cpp
        test/test_typeconvert.cpp
        test/test_system-library.cpp
    )

    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/test")
        # Tests will be set up when libcpptest is available
    endif()
endif()
