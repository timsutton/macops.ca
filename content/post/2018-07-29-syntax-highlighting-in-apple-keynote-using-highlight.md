---
title: Syntax highlighting in Apple Keynote Using highlight
date: 2018-07-29T08:00:20-07:00
tags:
  - Keynote
  - presentations
---

My presentations often include code examples where having fixed-width fonts and code syntax highlighting is desirable, and Apple Keynote remains my presentation tool of choice for a variety of reasons. I'm still interested to give some other presentation tools a try, but I often find that tools which are Markdown-centric (and seem commonly used for showing code in presentations) lack a lot of the traditional editing, layout, and animation features I use in Keynote. So, I continue to use (and love using) Keynote.

One way to lose an audience's interest is to make it hard for them to read or follow code you show in the slides, so I want to make sure any code is clear and readable. Having syntax highlighting one of several things one can do to improve code readability, so here's a simple technique I've been using since my [first talk]({{< relref "/post/2014-09-17-autopkg-crowd-sourcing-mac-packaging-and-deployment.md" >}}) for getting syntax-highlighted text into code snippets in Keynote slides, using the `highlight` program.


You'll need the [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php) command-line program. I install it using homebrew:

```
brew install highlight
```

`highlight` takes text as input and can apply syntax highlighting for different languages to a variety of output formats, including RTF (Rich Text Format). Keynote will accept RTF content from your system's clipboard, meaning all we need to do is get the RTF buffer copied _to_ the clipboard, then we can simply paste it into Keynote, which will insert our syntax-highlighted version of the text into a new text object.

I add a bash one-liner function called `keycode` to my shell RC file (in my case, `~/.zshrc`) which will grab the clipboard contents, pipe it to `highlight` with my desired parameters and copy the result back to the clipboard.

```bash
# highlight
# args: 1: size, 2: lang
function keycode() {
  pbpaste | \
    highlight \
    	--font Inconsolata \
    	--font-size $1 \
    	--style fine_blue_darker \
    	--src-lang $2 \
    	--out-format rtf | \
    pbcopy
}
```

### Usage

So my process looks like this:

1. Select the desired code sample in a plain-text editor, hit `Command-C` to copy it to the clipboard.
1. Run `keycode <size> <lang>` in a terminal window.
1. Switch to Keynote and hit `Command-V`, and a new text object appears with the highlighted/sized version.

In this version of the `keycode` function I use two positional arguments so that I can easily set the font size and the source text's language. `highlight` can attempt to infer language from the content but as I am often posting small snippets of code it is often easier to specify the language myself, i.e.

```
$ keycode 44 python
```

If I need to adjust the size later I can still easily tweak that in the text object's properties in Keynote, or re-copy/paste the text through this `keycode` function with a different size argument.


This would be a pretty easy command to convert into an [Alfred](https://www.alfredapp.com/workflows/) workflow, [FastScripts](https://red-sweater.com/fastscripts/) shortcut or similar, so that it could be trigged by a keyboard shortcut rather than typing a terminal command.

This example also uses a custom style file I liked for showing on white background slides. I used to always need to look up where this custom theme file had to be installed on my system, so I've now published a really simple [setup script](https://github.com/timsutton/presentation-tools/blob/master/setup_highlight.bash) which should be able to automatically copy any custom themes into the directory where highlight will search.

