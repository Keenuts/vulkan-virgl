# Vulkan virgl


This is the main repository for the Vulkan-virglrenderer experiment.
It will clone 3 repositories:

- virglrenderer (vulkan-wip branch)
- vulkan-fake-icd
- vulkan-compute

## Virglrenderer

Virglrenderer is a lib desinged to bring 3D acceleration to VirtIO-gpu.
Initialy, this project was designed with OpenGL in mind.
The goal of this experiment is to redesign it to support both Vulkan and OpenGL.

## Vulkan fake-ICD

Virglrenderer is usualy used with QEMU. Thus, if we want to test the whole pipeline, we
need a guest and a host. The setup gets heavy, and debugging a bit more complex.
This, this project is designed to run without any host/guest.

The Vulkan test app will directly be linked to this Vulkan ICD, which will call virgl.

## Vulkan compute

A sample vulkan compute application.


# Requirements

- cmake
- git
- vulkan-headers
- libepoxy
- libdrm
- libgbm
- libdl

# How to build

```bash
mkdir build
cd build
cmake ..
make
```

To disable git related commands.

```bash
cd build
cmake -DSYNC=OFF ..
```
