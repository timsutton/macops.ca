#!/bin/sh -e

# Deploy the site using rsync.

# rsync params:
# - recursive
# - timestamps
# - compressed
# - double verbosity
# - prefer checksums to compare sync rather than timestamps
# - delete items on destination that don't exist on source
rsync -rtzvv \
    --checksum \
    --delete \
    public/ \
    macops-ca-deploy@macops.ca:/var/www/macops.ca/
