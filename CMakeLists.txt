cmake_minimum_required(VERSION 2.8)
project(vulkan-virglrenderer)

set(STAMP_DIR               ${CMAKE_BINARY_DIR}/stamps)
set(TMP_DIR                 ${CMAKE_BINARY_DIR}/tmp)
set(EXECUTABLE_OUTPUT_PATH  ${PROJECT_BINARY_DIR})

option(SYNC "SYNC" ON)

macro(GIT_TASK name url branch)
    ExternalProject_Add(${name}-git
        PREFIX ${name}
        STAMP_DIR ${STAMP_DIR}/${name}
        TMP_DIR ${TMP_DIR}/${name}
        SOURCE_DIR ${name}
        BINARY_DIR ${name}-build

        GIT_REPOSITORY ${url}
        GIT_TAG ${branch}
        GIT_SHALLOW FALSE

        CONFIGURE_COMMAND ""
        BUILD_COMMAND ""
        INSTALL_COMMAND ""
    )

    set_target_properties(${name}-git
        PROPERTIES
        EXCLUDE_FROM_ALL TRUE
        EXCLUDE_FROM_DEFAULT_BUILD TRUE
    )
endmacro(GIT_TASK)

message("repositories update: ${SYNC}")
include(${CMAKE_SOURCE_DIR}/build.cmake)
