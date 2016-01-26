#!/bin/sh -e

bundle exec jekyll build --trace
rsync -avz \
    --checksum \
    --delete \
    _site/ \
    root@macops.ca:/var/www/macops.ca/
