find_package(Git)
if (NOT GIT_FOUND)
    message(SEND_ERROR "git binary not found.")
ENDIF()

include(ExternalProject)

include(${CMAKE_SOURCE_DIR}/External-virglrenderer.cmake)
include(${CMAKE_SOURCE_DIR}/External-fake-icd.cmake)
include(${CMAKE_SOURCE_DIR}/External-compute.cmake)
