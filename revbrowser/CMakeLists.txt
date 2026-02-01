# revbrowser - Browser External
# Provides embedded web browser functionality

message(STATUS "Configuring revbrowser")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revbrowser configured")
else()
    message(STATUS "revbrowser: source directory not found, skipping")
endif()
