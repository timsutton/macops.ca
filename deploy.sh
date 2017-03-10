#!/bin/sh -e

# Deploy the site using rsync.

# rsync params:
# - specify a private key
# - recursive
# - timestamps
# - compressed
# - prefer checksums to compare sync rather than timestamps
# - delete items on destination that don't exist on source
rsync -rtvz \
    --checksum \
    --delete \
    _site/ \
    macops-ca-deploy@macops.ca:/var/www/macops.ca/
