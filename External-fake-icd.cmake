set(NAME fake-icd)

ExternalProject_Add(${NAME}
    PREFIX ${NAME}
    STAMP_DIR ${STAMP_DIR}/${NAME}
    TMP_DIR ${TMP_DIR}/${NAME}
    SOURCE_DIR ${NAME}
    BINARY_DIR icd-build

    GIT_REPOSITORY git@github.com:Keenuts/vulkan-fake-icd
    GIT_TAG master
    GIT_SHALLOW TRUE

    CMAKE_ARGS
        -DVIRGL_INCLUDES=${VIRGL_INCLUDES_DIR}
    INSTALL_COMMAND ""
    DEPENDS virglrenderer
)
unset(NAME)

message("includes: ${VIRGL_INCLUDES_DIR}")

set(ICD_DIR ${CMAKE_BINARY_DIR}/icd-build)
