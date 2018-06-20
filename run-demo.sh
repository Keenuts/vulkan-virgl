#!/bin/bash

# First step, check if the env is sane.

COLOR_BEGIN="\033[93m"
COLOR_END="\033[0m"

TO_CHECK=(VULKAN_DRIVER USE_VIRTIOGPU VK_ICD_FILENAMES)

for v in ${TO_CHECK[*]}; do
    if [ "$(set | grep $v=)" != "" ]; then
        echo "$v env variable is set. This might be an error"
        echo "press enter to continue"
        read
    fi
done


# Then, parse args. Repos URL can be overiden
mesa_url="https://github.com/Keenuts/mesa.git"
virglrenderer_url="https://github.com/Keenuts/virglrenderer.git"
vulkan_compute_url="https://github.com/Keenuts/vulkan-compute.git"

function show_help()
{
    echo "vulkan-virgl-helper:"
    echo "  --mesa=   : override the URL for the mesa project"
    echo "  --virgl=  : override the URL for the virglrenderer project"
    echo "  --app=    : override the URL for the vulkan-compute project"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mesa=*)   mesa_url="${1#*=}";             shift 1;;
        --virgl=*)  virglrenderer_url="${1#*=}";    shift 1;;
        --app=*)    vulkan_compute_url="${1#*=}";   shift 1;;

        *) show_help; exit 1;;
    esac
done


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
    updated=0

    if [ ! -d "$folder" ]; then
        echo -e "${COLOR_BEGIN}[GIT] cloning ${url} ${branch}${COLOR_END}"
        git clone "$url" "$folder" -b "$branch" --depth=1 || exit 1
    else
        cd "$folder"
        git remote set-url origin "$url"

        REMOTE=$(git rev-parse "$branch")
        BASE=$(git merge-base @ "$branch")

        if [ $REMOTE != $BASE ]; then
            echo -e "${COLOR_BEGIN}[GIT] updating ${url} ${branch}${COLOR_END}"
            updated=1
            git pull || (echo "unstaged changes. Exiting now" ; exit 1)
        fi
    fi

    cd "$root"

    return $updated
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
            -Dprefix=$(realpath mesa/build) > /dev/null
    fi

    echo -e "${COLOR_BEGIN}[INFO] building MESA${COLOR_END}"
    ninja -C mesa/build -j $(( $(nproc) * 2 ))

    echo -e "${COLOR_BEGIN}[INFO] locating ICD files${COLOR_END}"
    export ICD_JSON="$(realpath mesa/build/src/virgl/virglrenderer_debug.x86_64.json)"
}

function build_virglrenderer()
{
    cd virglrenderer

    if [ ! -f Makefile ]; then
        echo -e "${COLOR_BEGIN}[INFO] configuring virglrenderer${COLOR_END}"
        ./autogen.sh                    \
            --with-vulkan               \
            --enable-debug              \
            --enable-tests              \
            --prefix=$(realpath build) > /dev/null
    fi

    echo -e "${COLOR_BEGIN}[INFO] building virglrenderer${COLOR_END}"
    make -j $(( $(nproc) * 2 )) > /dev/null

    cp vtest/virgl_test_server "$root/"
    cd "$root"
}

function build_vulkan_compute()
{
    cd vulkan-compute

    if [ ! -d build ]; then
        echo -e "${COLOR_BEGIN}[INFO] configuring vulkan application${COLOR_END}"
        mkdir build
        cmake -H. -Bbuild/ > /dev/null
    fi

    echo -e "${COLOR_BEGIN}[INFO] building vulkan application${COLOR_END}"
    make -C build -j $(( $(nproc) * 2 ))

    cp build/sum.spv "$root/sum.spv"
    cp build/sum "$root/vulkan-application"
    cd "$root"
}

function run_app()
{
    echo -e "${COLOR_BEGIN}[INFO] running the application now.${COLOR_END}"
    ./virgl_test_server &
    SERVER_PID=$!

    sleep 1

    export VULKAN_DRIVER=virpipe
    export USE_VIRTIOGPU=true
    export VK_ICD_FILENAMES="$ICD_JSON"
    
    set +e
    ./vulkan-application
    set -e

    echo -e "${COLOR_BEGIN}[INFO] Killing the vtest server.${COLOR_END}"
    kill $SERVER_PID
}

set -e
cd $(dirname $0)
mkdir -p build
cd build
export root="$(pwd)"

clone_repo "$mesa_url"            virgl-vulkan  mesa
clone_repo "$virglrenderer_url"   vulkan-wip    virglrenderer
clone_repo "$vulkan_compute_url"  master        vulkan-compute

build_mesa
build_virglrenderer
build_vulkan_compute

run_app
