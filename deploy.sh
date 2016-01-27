#!/bin/sh -e

# build the site
bundle exec jekyll build --trace

# rsync params:
# - recursive
# - timestamps
# - compressed
# - prefer checksums to compare sync rather than timestamps
# - delete items on destination that don't exist on source
rsync -rtvz \
    --checksum \
    --delete \
    _site/ \
    root@macops.ca:/var/www/macops.ca/
