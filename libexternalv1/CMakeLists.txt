# libexternalv1 - External interface library (v1 API)
# Legacy external plugin API

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    file(GLOB LIBEXTERNALV1_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp")
    if(LIBEXTERNALV1_SOURCES)
        add_library(libExternalV1 STATIC ${LIBEXTERNALV1_SOURCES})
        target_include_directories(libExternalV1 PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        )
        target_link_libraries(libExternalV1 PUBLIC libFoundation)
        add_library(OpenXTalk::ExternalV1 ALIAS libExternalV1)
    endif()
else()
    message(STATUS "libexternalv1: source directory not found, skipping")
endif()
