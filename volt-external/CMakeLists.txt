cmake_minimum_required(VERSION 3.16)
project(VoltExternal LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT WIN32)
    message(FATAL_ERROR "Volt External is a Windows overlay (Direct2D/DirectWrite/Win32).")
endif()

add_executable(Volt WIN32
    src/main.cpp
    src/App.cpp
    src/Store.cpp
    src/UI.cpp
    src/Renderer.cpp
    src/Bridge.cpp
)

target_link_libraries(Volt PRIVATE d2d1 dwrite)

if(MSVC)
    target_compile_options(Volt PRIVATE /W4 /permissive- /utf-8)
    set_property(TARGET Volt PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()
