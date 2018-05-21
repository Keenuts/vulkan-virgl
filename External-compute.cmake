set(NAME vulkan-compute)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${NAME}
    BINARY_DIR compute-build

    GIT_REPOSITORY git@github.com:Keenuts/vulkan-compute
    GIT_TAG master
    GIT_SHALLOW TRUE

    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DVIRGL_INCLUDES=${VIRGL_INCLUDES_DIR}
        -DVIRGL_LIBS=${VIRGL_LIBS_DIR}
    INSTALL_COMMAND ""
    DEPENDS fake-icd
)
unset(NAME)

set(APP_DIR ${CMAKE_BINARY_DIR}/compute-build)
