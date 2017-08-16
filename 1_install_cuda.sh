#!/usr/bin/env bash
# Installation script for Cuda and drivers on Ubuntu, by Giuseppe Attardi (attardi@di.unipi.it)
# Derived from:
# https://github.com/deeplearningparis/dl-machine/blob/master/scripts/install-deeplearning-libraries.sh

# TODO
# Make this more parametric.

###################################
#   Ubuntu Install script for:
# - Nvidia graphic drivers
# - Cuda 8.0
# - cuDNN 7
###################################

if [ "$(whoami)" != "root" ]; then
  echo "You must be root for running this script."
  exit 1
fi

# detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Unsopported OS release"
    exit 2
fi
MACHINE = `uname -m` 

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y git wget linux-image-generic build-essential unzip

# nvidia graphics drivers 384
# see http://docs.nvidia.com/deeplearning/sdk/cudnn-install/                                       

if [ $VER == '14.04' ]; then
   NVIDIA_DRIVER = nvidia-diag-driver-local-repo-ubuntu1404-384.66_1.0-1_amd64.deb
elif [ $OS == '16.04' ]; then
   NVIDIA_DRIVER = nvidia-diag-driver-local-repo-ubuntu1604-384.66_1.0-1_amd64.deb
else
   echo "Unavailable nVidia drivers"
   exit 3
fi

wget http://us.download.nvidia.com/tesla/384.66/$NVIDIA_DRIVER
sudo dpkg -i $NVIDIA_DRIVER
sudo apt-get update
sudo apt-get -y install nvidia-384

# Cuda 8.0
# see: http://docs.nvidia.com/cuda/cuda-installation-guide-linux/
if [ $VER == '14.04' ]; then
    CUDA_REPO = cuda-repo-ubuntu1404_8.0.61-1_amd64.deb
    REPOS = ubuntu1404
elif [ $VER == '16.04' ]; then
    CUDA_REPO = cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
    REPOS = ubuntu1604
else
   echo "Unavailable CUDA library drivers"
   exit 4
fi
cd /tmp
wget https://developer.download.nvidia.com/compute/cuda/repos/$REPOS/$MACHINE/$CUDA_REPO
sudo dpkg -i $CUDA_REPO
sudo apt-get update
sudo apt-get install -y cuda
rm -f $CUDA_REPO

if [ $VERSION == '14.04']; then
   PATCH = cuda-repo-ubuntu1404-8-0-local-cublas-performance-update_8.0.61-1_amd64-deb
   wget https://developer.nvidia.com/compute/cuda/8.0/Prod2/patches/2/$PATCH
   sudo dpkg -i $PATCH
   rm -f $PATCH
fi

# cuDNN
# Download requires registration:
CUDNN = libcudnn7_7.0.1.13-1+cuda8.0_amd64.deb
CUDNN_DEV = libcudnn7-dev_7.0.1.13-1+cuda8.0_amd64.deb
if [ -e $CUDNN]; then
   sudo dpkg -i $CUDNN
   sudo apt-get update
   sudo apt-get install -y libcudnn7
else
   echo Download cuDNN Runtime Library (Debian),
   echo from https://developer.nvidia.com/rdp/cudnn-download
fi
if [ -e CUDNN_DEV ]; then
   sudo dpkg -i $CUDNN_DEV
   sudo apt-get update
   sudo apt-get install -y libcudnn7-dev
else
   echo Download cuDNN Develooper Library (Debian),
   echo from https://developer.nvidia.com/rdp/cudnn-download
fi

sudo sh -c 'echo "export PATH=/usr/local/cuda/bin:\$PATH" > /etc/profile.d/cuda.sh'
sudo sh -c 'echo "export LD_LIBRARY_PATH=/usr/lib/$MACHINE-linux-gnu:/usr/local/cuda/lib64:\$LD_LIBRARY_PATH" >> /etc/profile.d/cuda.sh'
sudo sh -c 'echo "export CUDNN_LIBRARY=/usr/lib/$MACHINE-linux-gnu/libcudnn.so.7" >> /etc/profile.d/cuda.sh'

echo "CUDA installation complete: please reboot your machine and continue with script #2"
