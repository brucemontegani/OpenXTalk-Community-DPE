# libbrowser - Browser integration library
# WebView/CEF integration for embedded browser functionality

message(STATUS "Configuring libbrowser")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    set(LIBBROWSER_SOURCES)

    # Common sources
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/libbrowser.cpp")
        list(APPEND LIBBROWSER_SOURCES src/libbrowser.cpp)
    endif()

    # macOS WebView implementation
    if(APPLE AND NOT IOS)
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/libbrowser_osx_webview.mm")
            list(APPEND LIBBROWSER_SOURCES src/libbrowser_osx_webview.mm)
        endif()
    endif()

    # iOS WebView implementation
    if(APPLE AND IOS)
        if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src/libbrowser_ios.mm")
            list(APPEND LIBBROWSER_SOURCES src/libbrowser_ios.mm)
        endif()
    endif()

    # Windows implementation
    if(WIN32)
        file(GLOB LIBBROWSER_WIN_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*_win*.cpp")
        list(APPEND LIBBROWSER_SOURCES ${LIBBROWSER_WIN_SOURCES})
    endif()

    # Linux/CEF implementation
    if(UNIX AND NOT APPLE)
        file(GLOB LIBBROWSER_LINUX_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/*_linux*.cpp")
        list(APPEND LIBBROWSER_SOURCES ${LIBBROWSER_LINUX_SOURCES})
    endif()

    if(LIBBROWSER_SOURCES)
        add_library(libBrowser STATIC ${LIBBROWSER_SOURCES})
        target_include_directories(libBrowser PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        )
        target_link_libraries(libBrowser PUBLIC libFoundation)

        if(APPLE)
            target_link_libraries(libBrowser PRIVATE
                "-framework WebKit"
            )
        endif()

        add_library(OpenXTalk::Browser ALIAS libBrowser)
    else()
        message(STATUS "libbrowser: no sources found, skipping")
    endif()
else()
    message(STATUS "libbrowser: source directory not found, skipping")
endif()
