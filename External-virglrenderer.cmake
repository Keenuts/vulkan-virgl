set(NAME virglrenderer)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${CMAKE_BINARY_DIR}/${NAME}
    BINARY_DIR ${CMAKE_BINARY_DIR}/virgl-build

    GIT_REPOSITORY git@github.com:Keenuts/virglrenderer
    GIT_TAG vulkan-wip
    GIT_SHALLOW TRUE

    CONFIGURE_COMMAND ${CMAKE_BINARY_DIR}/virglrenderer/autogen.sh
        --prefix=${CMAKE_BINARY_DIR}/virgl-build
        --with-vulkan
        --enable-debug
        --enable-static
    BUILD_COMMAND make
)

set(VIRGL_DIR ${CMAKE_BINARY_DIR}/virgl-build)
set(VIRGL_LIBS_DIR "${CMAKE_BINARY_DIR}/virgl-build/lib")
set(VIRGL_INCLUDES_DIR "${CMAKE_BINARY_DIR}/virgl-build/include/virgl")
