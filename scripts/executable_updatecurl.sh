#!/bin/bash

# Upgrade curl to v8.12.1
sudo apt-get install -y nghttp2 libnghttp2-dev libssl-dev libpsl-dev build-essential wget
wget https://curl.se/download/curl-8.12.1.tar.xz
tar -xvf curl-8.12.1.tar.xz
rm curl-8.12.1.tar.xz
cd curl-8.12.1
./configure --prefix=/usr/local --with-ssl --with-nghttp2 --enable-versioned-symbols
make
sudo make install
sudo ldconfig
cd ..
rm -r curl-8.12.1
curl --version
