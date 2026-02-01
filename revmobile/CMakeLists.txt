# revmobile - Mobile External
# Provides iOS and Android mobile functionality

message(STATUS "Configuring revmobile")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revmobile configured")
else()
    message(STATUS "revmobile: source directory not found, skipping")
endif()
