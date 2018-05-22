set(NAME fake-icd)

GIT_TASK(${NAME} git@github.com:Keenuts/vulkan-fake-icd master)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${NAME}
    BINARY_DIR ${NAME}-build

    CMAKE_ARGS
        -DVIRGL_INCLUDES=${VIRGL_INCLUDES_DIR}
    INSTALL_COMMAND ""
    DEPENDS
        virglrenderer
)

IF (${SYNC})
    add_dependencies(${NAME} ${NAME}-git)
ENDIF()

set(ICD_LIB "${CMAKE_BINARY_DIR}/${NAME}-build/libvulkan-fake-icd.a")
unset(NAME)
