# libexternal - External interface library
# Provides API for creating external plugins

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    # Common source files
    set(LIBEXTERNAL_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/src/external.c
    )

    # Platform-specific sources
    if(APPLE)
        list(APPEND LIBEXTERNAL_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/src/osxsupport.cpp
        )
    elseif(WIN32)
        list(APPEND LIBEXTERNAL_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/src/w32support.cpp
        )
    else()
        # Linux/Unix
        list(APPEND LIBEXTERNAL_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/src/unxsupport.cpp
        )
    endif()

    if(LIBEXTERNAL_SOURCES)
        add_library(libExternal STATIC ${LIBEXTERNAL_SOURCES})
        target_include_directories(libExternal PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        )
        target_link_libraries(libExternal PUBLIC libFoundation)
        add_library(OpenXTalk::External ALIAS libExternal)
    endif()
else()
    message(STATUS "libexternal: source directory not found, skipping")
endif()
