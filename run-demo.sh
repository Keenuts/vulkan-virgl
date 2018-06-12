#!/bin/bash

TO_CHECK=(VULKAN_DRIVER USE_VIRTIOGPU VK_ICD_FILENAMES)

for v in ${TO_CHECK[*]}; do
    if [ "$(set | grep $v=)" != "" ]; then
        echo "$v env variable is set. This might be an error"
        echo "press enter to continue"
        read
    fi
done


function clone_repo()
{
    url="$1"
    folder="$2"

    if [ ! -d "$folder" ]; then
        git clone "$url" "$folder" || exit 1
    else
        cd "$folder" && git pull
    fi

    echo $root
    cd "$root"
}

function build_mesa()
{
    echo "building mesa"

    if [ ! -d mesa/build ]; then
        meson setup mesa mesa/build
        meson configure mesa/build -Dvulkan-drivers=virgl -Dgallium-drivers=virgl
    fi

    ninja -C mesa/build -j $(( $(nproc) * 2 ))

    export ICD_JSON="$(realpath mesa/build/src/virgl/vulkan/dev_icd.x86_64.json)"
}

function build_virglrenderer()
{
    echo "building virglrenderer"
    cd virglrenderer

    echo $(pwd)
    if [ ! -f Makefile ]; then
        ./autogen.sh                    \
            --with-vulkan               \
            --enable-debug              \
            --enable-tests              \
            --prefix=$(realpath build)
    fi

    make -j $(( $(nproc) * 2 ))

    cp vtest/virgl_test_server "$root/"
    cd "$root"
}

function build_vulkan_compute()
{
    echo "building vulkan application"
    cd vulkan-compute

    if [ ! -d build ]; then
        mkdir build
        cmake -H. -Bbuild/
    fi

    make -C build -j $(( $(nproc) * 2 ))

    cp build/sum.spv "$root/sum.spv"
    cp build/sum "$root/vulkan-application"
    cd "$root"
}

function run_app()
{
    ./virgl_test_server &
    SERVER_PID=$!

    sleep 1

    export VULKAN_DRIVER=virpipe
    export USE_VIRTIOGPU=true
    export VK_ICD_FILENAMES="$ICD_JSON"
    
    set +e
    ./vulkan-application
    set -e

    echo "killing vtest server."
    kill $SERVER_PID
}

set -e
cd $(dirname $0)
mkdir -p build
cd build
export root="$(pwd)"

clone_repo "https://github.com/Keenuts/mesa.git" mesa
clone_repo "https://github.com/Keenuts/virglrenderer.git" virglrenderer
clone_repo "https://github.com/Keenuts/vulkan-compute.git" vulkan-compute

build_mesa
build_virglrenderer
build_vulkan_compute

run_app
