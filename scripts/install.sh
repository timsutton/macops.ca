#!/bin/sh -e

HUGO_VERSION=0.30.2

platform=Linux
if [ $(uname) = "Darwin" ]; then
	platform=macOS
fi

tmpfile=$(mktemp)
curl -Lsf \
    -o "${tmpfile}" \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_${platform}-64bit.tar.gz
tar -xzf \
	"${tmpfile}" \
	hugo
rm "${tmpfile}"
