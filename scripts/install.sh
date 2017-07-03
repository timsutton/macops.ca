#!/bin/sh -e

HUGO_VERSION=0.24.1
PYGMENTS_VERSION=2.2.0

wget -q https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.deb
sudo dpkg -i hugo_${HUGO_VERSION}_Linux-64bit.deb

pip install pygments==${PYGMENTS_VERSION}
