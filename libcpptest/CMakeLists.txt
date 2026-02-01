# libcpptest - C++ Testing Library
# Google Test integration for C++ unit tests

message(STATUS "Configuring libcpptest")

if(BUILD_TESTING)
    # Include Google Test if available
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/googletest")
        # The bundled googletest has an old CMakeLists.txt
        # We need to set the minimum version policy before adding it
        set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "Min policy for googletest")
        add_subdirectory(googletest EXCLUDE_FROM_ALL)
        message(STATUS "Google Test available for testing")
    else()
        # Try to find system Google Test
        find_package(GTest)
        if(GTest_FOUND)
            message(STATUS "Using system Google Test")
        else()
            message(STATUS "Google Test not found, C++ tests disabled")
        endif()
    endif()
endif()
