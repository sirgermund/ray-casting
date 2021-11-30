cmake_minimum_required(VERSION 3.0)
project (3d)

set(CMAKE_CXX_STANDARD 23)

# In most cases better set in the CMake cache
set(SFML_DIR C:/Users/sirge/Downloads/SFML-2.5.1-windows-gcc-7.3.0-mingw-64-bit/SFML-2.5.1/lib/cmake/SFML)
set(SFML_STATIC_LIBRARIES TRUE)

find_package(SFML 2.5 COMPONENTS graphics audio REQUIRED)

add_executable(3d main.cpp)

include_directories(C:/Users/sirge/Downloads/SFML-2.5.1-windows-gcc-7.3.0-mingw-64-bit/SFML-2.5.1/include)
target_link_libraries(3d sfml-graphics sfml-audio)
