#!/bin/bash
# Script to build a barebones kernel and rootfs using ARM cross-compile toolchain
# Author: Siddhant Jajoo

set -e
set -u

# Default output directory
OUTDIR=/tmp/aeld

# Default values for kernel and busybox versions
KERNEL_VERSION="v5.1.10"
BUSYBOX_VERSION="1_33_1"

# Finder app directory
FINDER_APP_DIR=$(realpath $(dirname $0))

# Architecture and cross-compile prefix
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

# Check if output directory is provided as argument
if [ $# -ge 1 ]; then
    OUTDIR="$1"
fi

echo "Using output directory: $OUTDIR"

# Create output directory if it doesn't exist
mkdir -p "$OUTDIR"

# Clone Linux kernel source if not already present
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    echo "Cloning Linux kernel source..."
    git clone --depth 1 --single-branch --branch "$KERNEL_VERSION" "$KERNEL_REPO" "${OUTDIR}/linux-stable"
fi

# Build kernel
echo "Building Linux kernel..."
cd "${OUTDIR}/linux-stable"

# Clean and configure kernel
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig

# Build kernel
make -j$(nproc) ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all

# Copy kernel image to output directory
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"

# Create root filesystem staging directory
echo "Creating root filesystem staging directory..."
mkdir -p "${OUTDIR}/rootfs"

# Clone or update BusyBox source
if [ ! -d "${OUTDIR}/busybox" ]; then
    echo "Cloning BusyBox source..."
    git clone --depth 1 "git://busybox.net/busybox.git" "${OUTDIR}/busybox"
else
    echo "Updating existing BusyBox source..."
    cd "${OUTDIR}/busybox"
    git fetch origin
    git reset --hard origin/master
fi

cd "${OUTDIR}/busybox"

# Configure BusyBox
echo "Configuring BusyBox..."
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" defconfig

# Build BusyBox
echo "Building BusyBox..."
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}"

# Install BusyBox
echo "Installing BusyBox to rootfs..."
make ARCH="${ARCH}" CROSS_COMPILE="${CROSS_COMPILE}" CONFIG_PREFIX="${OUTDIR}/rootfs" install

# Create necessary base directories
echo "Creating base directories..."
cd "${OUTDIR}/rootfs"
mkdir -p proc sys dev etc home

# Create device nodes
echo "Creating device nodes..."
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1

# Clean and build the writer utility
echo "Building writer utility..."
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}

# Copy the finder related scripts and executables to the /home directory on the target rootfs
echo "Copying finder scripts and executables..."
cp writer "${OUTDIR}/rootfs/home/"
cp finder.sh finder-test.sh "${OUTDIR}/rootfs/home/"
mkdir -p "${OUTDIR}/rootfs/home/conf"
cp conf/username.txt conf/assignment.txt "${OUTDIR}/rootfs/home/conf/"

# Chown root directory
echo "Changing owner of root directory..."
sudo chown -R root:root "${OUTDIR}/rootfs"

# Create initramfs
echo "Creating initramfs..."
cd "${OUTDIR}/rootfs"
find . | cpio -H newc -o | gzip > "${OUTDIR}/initramfs.cpio.gz"

echo "Done."
