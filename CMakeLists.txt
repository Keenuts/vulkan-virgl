cmake_minimum_required(VERSION 2.8)
project(vulkan-virglrenderer)

set(STAMP_DIR               ${CMAKE_BINARY_DIR}/stamps)
set(TMP_DIR                 ${CMAKE_BINARY_DIR}/tmp)
set(EXECUTABLE_OUTPUT_PATH  ${PROJECT_BINARY_DIR})

include(${CMAKE_SOURCE_DIR}/build.cmake)

add_executable(toto toto.c)
add_dependencies(toto virglrenderer)
