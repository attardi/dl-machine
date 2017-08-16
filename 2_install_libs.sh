#!/usr/bin/env bash
# Installation script for Deep Learning Libraries on Ubuntu, by Giuseppe Attardi (attardi@di.unipi.it)
# Derived from:
# https://github.com/deeplearningparis/dl-machine/blob/master/scripts/install-deeplearning-libraries.sh

######################################################################
#   Ubuntu Install script for various ML libraries:
# - Theano
# - Torch7
# - TensorFlow
# - ipython notebook
# - Caffe 
# - Lasagne
# - Nolearn
# - Keras
######################################################################

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
sudo apt-get install -y libncurses-dev

####################################
# Dependencies
####################################

# Build latest stable release of OpenBLAS without OPENMP to make it possible
# to use Python multiprocessing and forks without crash
# The torch install script will install OpenBLAS with OPENMP enabled in
# /opt/OpenBLAS so we need to install the OpenBLAS used by Python in a
# distinct folder.
# Note: the master branch only has the release tags in it
sudo apt-get install -y gfortran
export OPENBLAS_ROOT=/opt/OpenBLAS-no-openmp
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$OPENBLAS_ROOT/lib
if [ ! -d "OpenBLAS" ]; then
    git clone -q --branch=master git://github.com/xianyi/OpenBLAS.git
    (cd OpenBLAS \
      && make FC=gfortran USE_OPENMP=0 NO_AFFINITY=1 NUM_THREADS=$(nproc) \
      && sudo make install PREFIX=$OPENBLAS_ROOT)
    echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc
fi
sudo ldconfig

######################################################################
# Python basics: update pip and setup a virtualenv to avoid mixing packages
# installed from source with system packages
#sudo apt-get update
sudo apt-get install -y python-pip python-dev htop
sudo apt-get install -y python3-pip python3-dev htop
sudo pip install -U pip virtualenv

# avoid InsecurePlatformWarning
apt-get install -y libffi-dev libssl-dev
pip install 'requests[security]'

pip install circus circus-web Cython Pillow

# Numerical libraries
pip install numpy scipy

# Install common tools from the scipy stack
sudo apt-get install -y libfreetype6-dev libpng12-dev
pip install matplotlib ipython[all] pandas scikit-image

# Scikit-learn (generic machine learning utilities)
pip install -e git+git://github.com/scikit-learn/scikit-learn.git#egg=scikit-learn

# Python extra tools:
pip install config functools32 logging setuptools
pip install tk tqdm
pip install h5py seaborn

####################################
# Theano
####################################
# By default, Theano will detect if it can use cuDNN. If so, it will use it. 
# To get an error if Theano can not use cuDNN, use this Theano flag: optimizer_including=cudnn.

pip install -e git+git://github.com/Theano/Theano.git#egg=Theano

echo "Installed Theano"

####################################
# Tensorflow GPU
####################################
apt-get install -y libcupti-dev

# requirements
pip install numpy six libprotobuf-dev tensorflow-tensorboard autograd

pip install tensorflow-gpu  # Python 2.7;  GPU support
pip3 install tensorflow-gpu  # Python 3.n;  GPU support

echo "Installed TensorFlow"

pip install tflearn

####################################
# Torch
####################################

if [ ! -d "torch" ]; then
    git clone https://github.com/torch/distro.git torch --recursive
    cd torch; bash install-deps
# upgrade to use libcudnn.so.7
    rm -fr torch/cudnn
    cd torch; git clone -b R7 https://github.com/soumith/cudnn.torch.git cudnn
    rm -fr torch/cudnn
fi

echo "Installed Torch"

####################################
# Caffe
####################################

if [ $VER == '17.04']; then
    apt install caffe-cuda
else
   apt-get install -y libprotobuf-dev libleveldb-dev \
     libsnappy-dev libopencv-dev libboost-all-dev libhdf5-serial-dev \
     libgflags-dev libgoogle-glog-dev liblmdb-dev protobuf-compiler \
     libatlas-base-dev libyaml-dev 
   apt-get install --no-install-recommends libboost-all-dev

   git clone https://github.com/BVLC/caffe.git

   cd caffe/python; pip install -r requirements.txt
   sed "s/# USE_CUDNN := 1/USE_CUDNN := 1/" caffe/Makefile.config.example > caffe/Makefile.config
   cd caffe; make pycaffe -DUSE_CUDNN=1 -j24
   cd caffe; make all -DUSE_CUDNN=1 CUDA_DIR=$CUDA_DIR -j24
fi

echo "Installed Caffe"

####################################
# Lasagne
# https://github.com/Lasagne/Lasagne
####################################
git clone https://github.com/Lasagne/Lasagne.git
cd Lasagne; python setup.py install

echo "Lasagne installed"

####################################
# Nolearn
# asbtractions, mainly around Lasagne
# https://github.com/dnouri/nolearn
####################################
git clone https://github.com/dnouri/nolearn
cd nolearn; pip install -r requirements.txt; python setup.py install

echo "nolearn wrapper installed"

####################################
# Keras
# https://github.com/fchollet/keras
# http://keras.io/
####################################
pip install keras
pip install git+git://github.com/fchollet/keras.git --upgrade --no-deps
echo "Keras installed"

echo "all done."
