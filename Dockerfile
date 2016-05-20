############################################################
# Dockerfile for the BachBot project
# Based on Ubuntu
#
# Building, pushing, and running:
#   docker build -f Dockerfile -t bachbot:base .
#   docker tag -f <tag of last container> fliang/bachbot:base
#   docker push fliang/bachbot:base
#   docker run -i -t fliang/bachbot:base
############################################################

FROM ubuntu:14.04
MAINTAINER Feynman Liang "feynman.liang@gmail.com"

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Required packages
RUN apt-get update
RUN apt-get -y install \
    python \
    build-essential \
    python2.7-dev \
    python-pip \
    python-virtualenv \
    git \
    ssh \
    libhdf5-dev \
    software-properties-common

# Torch and luarocks
RUN git clone https://github.com/torch/distro.git /root/torch --recursive && cd /root/torch && \
    bash install-deps && \
    ./install.sh -b

ENV LUA_PATH='/root/.luarocks/share/lua/5.1/?.lua;/root/.luarocks/share/lua/5.1/?/init.lua;/root/torch/install/share/lua/5.1/?.lua;/root/torch/install/share/lua/5.1/?/init.lua;./?.lua;/root/torch/install/share/luajit-2.1.0-beta1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua'
ENV LUA_CPATH='/root/.luarocks/lib/lua/5.1/?.so;/root/torch/install/lib/lua/5.1/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so'
ENV PATH=/root/torch/install/bin:$PATH
ENV LD_LIBRARY_PATH=/root/torch/install/lib:$LD_LIBRARY_PATH
ENV DYLD_LIBRARY_PATH=/root/torch/install/lib:$DYLD_LIBRARY_PATH
ENV LUA_CPATH='/root/torch/install/lib/?.so;'$LUA_CPATH

#torch-rnn and python requirements
WORKDIR /root
RUN git clone https://github.com/jcjohnson/torch-rnn && \
    pip install -r torch-rnn/requirements.txt

#Lua requirements
WORKDIR /root
RUN luarocks install torch
RUN luarocks install nn
RUN luarocks install optim
RUN luarocks install lua-cjson

RUN git clone https://github.com/deepmind/torch-hdf5 /root/torch-hdf5
WORKDIR /root/torch-hdf5
RUN luarocks make hdf5-0-0.rockspec

#BachBot
RUN git clone https://github.com/feynmanliang/bachbot.git /root/bachbot
RUN apt-get -y install \
    libxml2-dev \
    libxslt-dev
RUN cd /root/bachbot && \
	/bin/bash -c "virtualenv -p python2.7 venv/ && \
	source venv/bin/activate && \
	pip install -r requirements.txt"

# Clean tmps
RUN apt-get clean && \
    rm -rf \
	/var/lib/apt/lists/* \
	/tmp/* \
	/var/tmp/* \
	/root/torch-hdf5

##################### INSTALLATION END #####################
WORKDIR /root/
ENTRYPOINT bash