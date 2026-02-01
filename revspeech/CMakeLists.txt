# revspeech - Speech External
# Provides text-to-speech functionality

message(STATUS "Configuring revspeech")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    message(STATUS "revspeech configured")
else()
    message(STATUS "revspeech: source directory not found, skipping")
endif()
