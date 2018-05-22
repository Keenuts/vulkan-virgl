set(NAME vulkan-compute)

GIT_TASK(${NAME} git@github.com:Keenuts/vulkan-compute master)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${NAME}
    BINARY_DIR ${NAME}-build

    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=Release
        -DICD_LIB=${ICD_LIB}
        -DVIRGL_LIB=${VIRGL_LIB}
    INSTALL_COMMAND ""
    DEPENDS
        fake-icd
)

IF (${SYNC})
    add_dependencies(${NAME} ${NAME}-git)
ENDIF()

unset(NAME)
