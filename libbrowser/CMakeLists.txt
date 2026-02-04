# libbrowser - Browser integration library
# WebView/CEF integration for embedded browser functionality

message(STATUS "Configuring libbrowser")

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    # Common sources (all platforms)
    set(LIBBROWSER_SOURCES
        src/libbrowser.cpp
        src/libbrowser_memory.cpp
        src/libbrowser_value.cpp
    )

    # macOS sources
    if(APPLE AND NOT IOS)
        list(APPEND LIBBROWSER_SOURCES
            src/libbrowser_osx_webview.mm
            src/libbrowser_nsvalue.mm
            src/libbrowser_osx_factories.cpp
        )
    endif()

    # iOS sources
    if(APPLE AND IOS)
        list(APPEND LIBBROWSER_SOURCES
            src/libbrowser_wkwebview.mm
            src/libbrowser_nsvalue.mm
            src/libbrowser_ios_factories.cpp
        )
    endif()

    # Windows sources
    if(WIN32)
        list(APPEND LIBBROWSER_SOURCES
            src/libbrowser_cef.cpp
            src/libbrowser_cef_win.cpp
            src/libbrowser_win_factories.cpp
        )
    endif()

    # Linux sources (CEF on x86/x86_64)
    if(UNIX AND NOT APPLE)
        list(APPEND LIBBROWSER_SOURCES
            src/libbrowser_cef.cpp
            src/libbrowser_cef_lnx.cpp
            src/libbrowser_lnx_factories.cpp
            src/signal_restore_posix.cpp
        )
    endif()

    if(LIBBROWSER_SOURCES)
        add_library(libBrowser STATIC ${LIBBROWSER_SOURCES})
        target_include_directories(libBrowser PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        )
        target_link_libraries(libBrowser PUBLIC libFoundation libCore)

        if(APPLE)
            target_link_libraries(libBrowser PRIVATE
                "-framework WebKit"
                "-framework JavaScriptCore"
            )
        endif()

        add_library(OpenXTalk::Browser ALIAS libBrowser)
    else()
        message(STATUS "libbrowser: no sources found, skipping")
    endif()
else()
    message(STATUS "libbrowser: source directory not found, skipping")
endif()
