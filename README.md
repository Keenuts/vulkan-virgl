# Vulkan virgl


This is the main repository for the Vulkan-virglrenderer experiment.
It will clone 3 repositories:

- virglrenderer (vulkan-wip branch)
- mesa (virgl-vulkan branch)
- vulkan-compute

## Virglrenderer

Virglrenderer is a lib desinged to bring 3D acceleration to VirtIO-gpu.
Initialy, this project was designed with OpenGL in mind.
The goal of this experiment is to redesign it to support both Vulkan and OpenGL.

## Vulkan compute

A sample vulkan compute application.

# Requirements (Using Fedora's package names)
- gcc
- git
- glibc-common
- glibc-utils
- kernel
- bison
- flex
- gcc-c++
- meson
- python
- python2
- expat-devel
- libXvMC-devel
- libdrm-devel
- libva-devel
- libvdpau-devel
- llvm-devel
- python2-mako
- vulkan-devel
- zlib-devel
- elfutils-libelf-devel
- libXdamage-devel
- libxshmfence-devel
- wayland-protocols-devel
- autoconf
- automake
- file
- libtool
- make
- check-devel
- libepoxy-devel
- mesa-libgbm-devel
- cmake
- glslang-devel

If you want to build it in debug, you will need LunarG Vulkan SDK.

# There is also a dockerfile available to build it using a valid Fedora setup

docker-fedora/dockerfile

# How to use

If you have an Intel GPU, and any issue on your current distro, I recommand using
a docker container. One is ready in the fedora-docker folder.
I tested it on my machine, with a simple HD-Graphics.
Maybe it will work on your machine.
Otherwise, you can:

```bash
./run-demo.sh
```

There is also some options available

```bash
$ ./run-demo.sh -help
vulkan-virgl-helper:
  --url-mesa=   : override the URL for the mesa project
  --url-virgl=  : override the URL for the virglrenderer project
  --url-app=    : override the URL for the vulkan-compute project
  -c        : disable repo cloning step
  -p        : disable repo pull step
  -b        : disable building step, implies -r
  -r        : disable running step
  -f        : remove the build folder first (force)
```
