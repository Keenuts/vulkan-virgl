FROM docker.io/fedora
MAINTAINER http://fedoraproject.org/wiki/Cloud

ENV container docker
LABEL RUN="docker run -it --name NAME --privileged --ipc=host --net=host --pid=host -e HOST=/host -e NAME=NAME -e IMAGE=IMAGE -v /run:/run -v /var/log:/var/log -v /etc/localtime:/etc/localtime -v /:/host IMAGE"

RUN [ -e /etc/yum.conf ] && sed -i '/tsflags=nodocs/d' /etc/yum.conf || true

# Reinstall all packages to get man pages for them
RUN dnf -y update && dnf -y reinstall "*" && dnf clean all

# Install all useful packages
RUN dnf -y install \
           gcc \
           git \
           glibc-common \
           glibc-utils \
           kernel

# MESA
RUN dnf -y install \
    bison   \
    flex    \
    gcc-c++ \
    meson   \
    python  \
    python2 \
    expat-devel     \
    libXvMC-devel   \
    libdrm-devel    \
    libva-devel     \
    libvdpau-devel  \
    llvm-devel      \
    python2-mako    \
    vulkan-devel    \
    zlib-devel      \
    elfutils-libelf-devel   \
    libXdamage-devel        \
    libxshmfence-devel      \
    wayland-protocols-devel

# Virglrenderer
RUN dnf -y install \
    autoconf    \
    automake    \
    file        \
    libtool     \
    make        \
    check-devel         \
    libepoxy-devel      \
    mesa-libgbm-devel

# Vulkan application
RUN dnf -y install \
    cmake          \
    glslang-devel

# Needed to use /dev/dri
RUN dnf -y install      \
    mesa-dri-drivers

ENV USER build
RUN useradd --create-home $USER
USER $USER

RUN git clone https://github.com/Keenuts/vulkan-virgl /home/$USER/vulkan-virgl
WORKDIR /home/$USER/vulkan-virgl

CMD ["/usr/bin/bash"]
