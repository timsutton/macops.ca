---

comments: true
date: 2014-04-15 16:22:36+00:00
layout: post
slug: building-native-extensions-since-llvm-5-1
title: Building native extensions since LLVM 5.1
wordpress_id: 667
tags:
- Command Line tools
- LLVM
- Python
- Xcode
---

With LLVM / clang 5.1, Apple introduced a change where any unrecognized command option causes a hard failure. Unfortunately, there are many packages in the [Python package index](https://pypi.python.org) that have not yet adapted to this change when building on OS X and include unsupported flags (in my experience it's usually been `-mno-fused-madd`). I first started running into this frequently when installing some Python packages using `pip`. This can also be an issue for other package managers like [RubyGems](http://rubygems.org/).

Output like this is common:

```
➜ pip install lxml

building 'lxml.etree' extension
creating build/temp.macosx-10.9-intel-2.7
creating build/temp.macosx-10.9-intel-2.7/src
creating build/temp.macosx-10.9-intel-2.7/src/lxml
cc -fno-strict-aliasing -fno-common -dynamic -arch x86_64 -arch i386 -g -Os -pipe -fno-common -fno-strict-aliasing -fwrapv -mno-fused-madd -DENABLE_DTRACE -DMACOSX -DNDEBUG -Wall -Wstrict-prototypes -Wshorten-64-to-32 -DNDEBUG -g -fwrapv -Os -Wall -Wstrict-prototypes -DENABLE_DTRACE -arch x86_64 -arch i386 -pipe -I/usr/include/libxml2 -I/Users/tsutton/venv/lxml-test/build/lxml/src/lxml/includes -I/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7 -c src/lxml/lxml.etree.c -o build/temp.macosx-10.9-intel-2.7/src/lxml/lxml.etree.o -w -flat_namespace

clang: error: unknown argument: '-mno-fused-madd' [-Wunused-command-line-argument-hard-error-in-future]
clang: note: this will be a hard error (cannot be downgraded to a warning) in the future
error: command 'cc' failed with exit status 1
```

Sometimes packages will still install and fall back to slower, non-native packages. Some packages, like `lxml`, simply won't install.

Luckily there is a straightforward workaround: define the `CFLAGS` environment variable and pass it the compatibility option `-Wunused-command-line-argument-hard-error-in-future` when we execute the command. The C compilers look for this and include these additional arguments. Like this:

```
➜ CFLAGS="-Wunused-command-line-argument-hard-error-in-future" pip install lxml

...

cc -DNDEBUG -g -fwrapv -Os -Wall -Wstrict-prototypes -Wunused-command-line-argument-hard-error-in-future -arch x86_64 -arch i386 -pipe -I/usr/include/libxml2 -I/Users/tsutton/venv/lxml-test/build/lxml/src/lxml/includes -I/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7 -c src/lxml/lxml.etree.c -o build/temp.macosx-10.9-intel-2.7/src/lxml/lxml.etree.o -w -flat_namespace
cc -bundle -undefined dynamic_lookup -arch x86_64 -arch i386 -Wl,-F. -Wunused-command-line-argument-hard-error-in-future build/temp.macosx-10.9-intel-2.7/src/lxml/lxml.etree.o -lxslt -lexslt -lxml2 -lz -lm -o build/lib.macosx-10.9-intel-2.7/lxml/etree.so
building 'lxml.objectify' extension
cc -DNDEBUG -g -fwrapv -Os -Wall -Wstrict-prototypes -Wunused-command-line-argument-hard-error-in-future -arch x86_64 -arch i386 -pipe -I/usr/include/libxml2 -I/Users/tsutton/venv/lxml-test/build/lxml/src/lxml/includes -I/System/Library/Frameworks/Python.framework/Versions/2.7/include/python2.7 -c src/lxml/lxml.objectify.c -o build/temp.macosx-10.9-intel-2.7/src/lxml/lxml.objectify.o -w -flat_namespace
cc -bundle -undefined dynamic_lookup -arch x86_64 -arch i386 -Wl,-F. -Wunused-command-line-argument-hard-error-in-future build/temp.macosx-10.9-intel-2.7/src/lxml/lxml.objectify.o -lxslt -lexslt -lxml2 -lz -lm -o build/lib.macosx-10.9-intel-2.7/lxml/objectify.so

Successfully installed lxml
```
