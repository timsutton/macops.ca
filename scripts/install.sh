#!/bin/sh -e

HUGO_VERSION=0.29

curl -Lsf \
    -o hugo.tar.gz \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_Linux-64bit.tar.gz
tar -xzf hugo.tar.gz
