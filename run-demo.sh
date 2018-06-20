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
    echo "  --mesa=   : override the URL for the mesa project"
    echo "  --virgl=  : override the URL for the virglrenderer project"
    echo "  --app=    : override the URL for the vulkan-compute project"
    echo "  -u        : only update the repositories"
    echo "  -f        : remove the build folder. Forcing updates."
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
        echo -e "${COLOR_BEGIN}[GIT] cloning ${url} ${branch}${COLOR_END}"
        git clone "$url" "$folder" -b "$branch" --depth=1 || exit 1
    else
        cd "$folder"
        if $update_remote; then
            echo -e "${COLOR_BEGIN}[GIT] changing remote to ${url}${COLOR_END}"
            git remote set-url origin "$url"
        fi
        git pull
    fi

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
            -Dprefix=$(realpath mesa/build) > /dev/null
    fi

    echo -e "${COLOR_BEGIN}[INFO] building MESA${COLOR_END}"
    ninja -C mesa/build -j $(( $(nproc) * 2 ))

    echo -e "${COLOR_BEGIN}[INFO] locating ICD files${COLOR_END}"
    export ICD_JSON="$(realpath mesa/build/src/virgl/virglrenderer_debug.x86_64.json)"
    if [ ! -f "$ICD_JSON" ]; then
        echo "ERROR: ICD json file not found. Existing now"
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

# parse args. Repos URL can be overiden
mesa_url="$DEFAULT_URL_MESA"
virglrenderer_url="$DEFAULT_URL_VIRGL"
vulkan_compute_url="$DEFAULT_URL_APP"

update_only=false
update_remote=false
force_clean=false

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mesa=*)   mesa_url="${1#*=}";             update_remote=true; shift 1;;
        --virgl=*)  virglrenderer_url="${1#*=}";    update_remote=true; shift 1;;
        --app=*)    vulkan_compute_url="${1#*=}";   update_remote=true; shift 1;;

        -u) update_only=true; shift 1;;
        -f) force_clean=true; shift 1;;

        *) show_help; exit 1;;
    esac
done

# ENV checkup: is out env sane ?
to_check=(VULKAN_DRIVER USE_VIRTIOGPU VK_ICD_FILENAMES)
for v in ${to_check[*]}; do
    if [ "$(set | grep $v=)" != "" ]; then
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

# cloning repos
clone_repo "$mesa_url"            "$DEFAULT_BRANCH_MESA"   mesa
clone_repo "$virglrenderer_url"   "$DEFAULT_BRANCH_VIRGL"  virglrenderer
clone_repo "$vulkan_compute_url"  "$DEFAULT_BRANCH_APP"    vulkan-compute

if $update_only; then
    exit 0
fi

# building
build_mesa
build_virglrenderer
build_vulkan_compute

# running
run_app
