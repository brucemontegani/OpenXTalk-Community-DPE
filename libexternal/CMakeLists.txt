# libexternal - External interface library
# Provides API for creating external plugins

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    file(GLOB LIBEXTERNAL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
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
