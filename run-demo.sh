#!/bin/bash

COLOR_BEGIN="\033[93m"
COLOR_END="\033[0m"

DEFAULT_URL_MESA="https://github.com/Keenuts/mesa.git"
DEFAULT_URL_VIRGL="https://github.com/Keenuts/virglrenderer.git"
DEFAULT_URL_APP="https://github.com/Keenuts/vulkan-compute.git"

DEFAULT_BRANCH_MESA="virgl-vulkan"
DEFAULT_BRANCH_VIRGL="vulkan-wip"
DEFAULT_BRANCH_APP="master"

function show_help()
{
    echo "vulkan-virgl-helper:"
    echo "  --url-mesa=   : override the URL for the mesa project"
    echo "  --url-virgl=  : override the URL for the virglrenderer project"
    echo "  --url-app=    : override the URL for the vulkan-compute project"
    echo "  -c        : disable repo cloning step"
    echo "  -p        : disable repo pull step"
    echo "  -b        : disable building step, implies -r"
    echo "  -r        : disable running step"
    echo "  -f        : remove the build folder first (force)"
}

# Takes two parameters:
#   - REPO-URL: URL to thr git repo
#   - REVISION: Revision to checkout
#   - DST-DIR:  DST directory to clone to
#
# Will clone or update the given repo
function clone_repo()
{
    url="$1"
    branch="$2"
    folder="$3"

    echo -e "${COLOR_BEGIN}[GIT] checking ${branch}${COLOR_END}"

    if [ ! -d "$folder" ]; then
        echo -e "${COLOR_BEGIN}\tcloning ${url} ${branch}${COLOR_END}"
        git clone "$url" "$folder" -b "$branch" --depth=1 || exit 1
    else
        echo -e "${COLOR_BEGIN}\trepo $(basename ${folder}) already cloned.${COLOR_END}"
    fi

    cd "$root"
}

# takes 2 params
#  - REPO-DIR
#  - REMOTE-URL
#
# Will update the remote on the given repo
function set_remote()
{
    folder="$1"
    url="$2"

    echo -e "${COLOR_BEGIN}[GIT] changing remote to ${url}${COLOR_END}"
    cd "$folder"
    git remote set-url origin "$url"
    cd "$root"
}

# takes 1 param
#  - REPO-DIR
#
# Will do a 'git pull' in the given repo
function pull_repo()
{
    folder="$1"

    echo -e "${COLOR_BEGIN}[GIT] pulling changes for ${folder}${COLOR_END}"
    cd "$folder"
    git pull
    cd "$root"
}

function build_mesa()
{

    if [ ! -d mesa/build ]; then
        echo -e "${COLOR_BEGIN}[INFO] configuring MESA${COLOR_END}"
        meson setup mesa mesa/build         \
            -Dvulkan-drivers=virgl          \
            -Dgallium-drivers=virgl         \
            -Dbuildtype=debug               \
            -Dglx=disabled                  \
            -Dprefix=$(realpath mesa/build)
    fi

    echo -e "${COLOR_BEGIN}[INFO] building MESA${COLOR_END}"
    ninja -C mesa/build

    echo -e "${COLOR_BEGIN}[INFO] locating ICD files${COLOR_END}"
    export ICD_JSON="$(realpath mesa/build/src/virgl/virglrenderer_debug.x86_64.json)"

    if [ ! -f "$ICD_JSON" ]; then
        echo "ERROR: ICD json file not found. Exiting now"
        exit 1
    fi

    cd "$root"
}

function build_virglrenderer()
{
    cd virglrenderer

    if [ ! -f Makefile ]; then
        echo -e "${COLOR_BEGIN}[INFO] configuring virglrenderer${COLOR_END}"
        ./autogen.sh                    \
            --with-vulkan               \
            --enable-debug              \
            --prefix=$(realpath build)
    fi

    echo -e "${COLOR_BEGIN}[INFO] building virglrenderer${COLOR_END}"
    make -j $(( $(nproc) * 2 ))
    make install

    echo -e "${COLOR_BEGIN}[INFO] locating vtest server binary${COLOR_END}"
    export VIRGL_SERVER_BIN="$(realpath build/bin/virgl_test_server)"
    if [ ! -f "$VIRGL_SERVER_BIN" ]; then
        echo "ERROR: Vtest server's binary not found. Exiting now"
        exit 1
    fi

    cd "$root"
}

function build_vulkan_compute()
{
    cd vulkan-compute

    if [ ! -d build ]; then
        echo -e "${COLOR_BEGIN}[INFO] configuring vulkan application${COLOR_END}"
        mkdir build
        cmake -H. -Bbuild/
    fi

    echo -e "${COLOR_BEGIN}[INFO] building vulkan application${COLOR_END}"
    make -C build -j $(( $(nproc) * 2 ))

    echo -e "${COLOR_BEGIN}[INFO] locating test application${COLOR_END}"
    export VULKAN_COMPUTE_BINARY="$(realpath build/sum)"
    export VULKAN_COMPUTE_SHADER="$(realpath build/sum.spv)"
    if [ ! -f "$VULKAN_COMPUTE_BINARY" ]; then
        echo "ERROR: test app's binary not found. Exiting now"
        exit 1
    fi
    if [ ! -f "$VULKAN_COMPUTE_SHADER" ]; then
        echo "ERROR: test app shader's not found. Exiting now"
        exit 1
    fi
    cd "$root"
}

function run_app()
{
    echo -e "${COLOR_BEGIN}[INFO] running the application now.${COLOR_END}"

    export VTEST_USE_VULKAN=1
    $VIRGL_SERVER_BIN --no-fork &
    SERVER_PID=$!

    sleep 1

    export VULKAN_DRIVER=virpipe
    export USE_VIRTIOGPU=true
    export VK_ICD_FILENAMES="$ICD_JSON"

    set +e

    cp -f $VULKAN_COMPUTE_SHADER .
    cp -f $VULKAN_COMPUTE_BINARY .
    ./$(basename $VULKAN_COMPUTE_BINARY)

    set -e

    echo -e "${COLOR_BEGIN}[INFO] Killing the vtest server.${COLOR_END}"
    kill $SERVER_PID
}

set -e

# parse args. Repos URL can be overiden
mesa_url="$DEFAULT_URL_MESA"
virglrenderer_url="$DEFAULT_URL_VIRGL"
vulkan_compute_url="$DEFAULT_URL_APP"

step_clone=true
step_pull=true
step_build=true
step_run=true

update_remote=false
force_clean=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --url-mesa=*)   mesa_url="${1#*=}";             update_remote=true; shift 1;;
        --url-virgl=*)  virglrenderer_url="${1#*=}";    update_remote=true; shift 1;;
        --url-app=*)    vulkan_compute_url="${1#*=}";   update_remote=true; shift 1;;
        -c) step_clone=false; shift 1;;
        -p) step_pull=false; shift 1;;
        -b) step_build=false; step_run=false; shift 1;;
        -r) step_run=false; shift 1;;
        -f) force_clean=true; shift 1;;
        *) show_help; exit 1;;
    esac
done

# ENV checkup: is out env sane ?
to_check=(VULKAN_DRIVER USE_VIRTIOGPU VK_ICD_FILENAMES)
for v in ${to_check[*]}; do
    if [ "$(env | grep $v=)" != "" ]; then
        echo "$v env variable is set. This might be an error"
        echo "press enter to continue"
        read
    fi
done

# Creating build tree

cd $(dirname $0)
if $force_clean; then
    rm -rf build
fi

mkdir -p build
cd build
export root="$(pwd)"

if $step_clone; then
    # cloning repos
    clone_repo "$mesa_url"            "$DEFAULT_BRANCH_MESA"   mesa
    clone_repo "$virglrenderer_url"   "$DEFAULT_BRANCH_VIRGL"  virglrenderer
    clone_repo "$vulkan_compute_url"  "$DEFAULT_BRANCH_APP"    vulkan-compute
fi

if $update_remote; then
    set_remote "mesa"           "$mesa_url"
    set_remote "virglrenderer"  "$virglrenderer_url"
    set_remote "vulkan-compute" "$vulkan_compute_url"
fi

if $step_pull; then
    pull_repo mesa
    pull_repo virglrenderer
    pull_repo vulkan-compute
fi

if $step_build; then
    # building
    build_mesa
    build_virglrenderer
    build_vulkan_compute
fi

if $step_run; then
    # running
    run_app
fi
