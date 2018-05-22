set(NAME virglrenderer)

GIT_TASK(${NAME} git@github.com:Keenuts/virglrenderer vulkan-wip)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${CMAKE_BINARY_DIR}/${NAME}
    BINARY_DIR ${CMAKE_BINARY_DIR}/${NAME}-build

    CONFIGURE_COMMAND ${CMAKE_BINARY_DIR}/virglrenderer/autogen.sh
        --prefix=${CMAKE_BINARY_DIR}/${NAME}-build
        --with-vulkan
        --enable-debug
        --enable-static
    BUILD_COMMAND make
)

IF (${SYNC})
    add_dependencies(${NAME} ${NAME}-git)
ENDIF()

set(VIRGL_DIR ${CMAKE_BINARY_DIR}/${NAME}-build)
set(VIRGL_LIB "${CMAKE_BINARY_DIR}/${NAME}-build/lib/libvirglrenderer.a")
set(VIRGL_INCLUDES_DIR "${CMAKE_BINARY_DIR}/${NAME}-build/include/virgl")

unset(NAME)
