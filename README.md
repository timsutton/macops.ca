# macops.ca

Source for [macops.ca](https://macops.ca). Built with Hugo and a modified [Kiko](https://github.com/gfjaru/Kiko) theme. Kiko theme content is licensed MIT.

## Dependencies

Install the latest [Hugo](https://gohugo.io/) and [Pygments](http://pygments.org/). Hugo just needs `pygmentize` to be available in the current path.

## Running

Just build it with `hugo`:

`hugo`

Or preview it locally:

`hugo server`

## Deploying

Deploying this to my webhost using `rsync` on [Travis CI](https://travis-ci.org/timsutton/macops.ca). Deploy manually using `scripts/deploy.sh`.
