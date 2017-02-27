# macops.ca

Source for macops.ca. Built with Jekyll and the [Kiko](https://kiko.gfjaru.com/) theme. Kiko theme content is licensed MIT.

## Running

### Local

Switch to a modern Ruby:

`chruby 2.3.3`

Install gems to an isolated directory:

`bundle install --path .gem`

Run Jekyll to preview the site:

`bundle exec jekyll serve`

### Via Docker

```
docker run --rm --label=jekyll \
--volume=$(pwd):/srv/jekyll \
-it \
-p 127.0.0.1:4000:4000 \
jekyll/jekyll \
jekyll serve --force_polling
```

## Deploying

Currently just doing this locally via `./deploy.sh`.

## Other components used

### [Rakefile boilerplate](https://github.com/gummesson/jekyll-rake-boilerplate)

Not yet modified enough to be usable.

### [jekyll-pages-directory](https://github.com/bbakersmith/jekyll-pages-directory)

Used to move a few post.md files out of the project root.

### jekyll-tags plugin

Can't remember where this came from - it's been modified to not generate index.html files within tag directories, but rather straight index.html files. This caused me to need to do a bit of additional work in my VirtualHost file, though, so may revert back to how it worked before and instead adjust the Vhost to automatically add an index.html to a URL if the file doesn't exist. I think a rule like this is simpler to do in Nginx than Apache :(
