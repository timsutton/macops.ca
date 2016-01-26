---
comments: true
date: 2015-03-11 14:33:42+00:00
layout: post
slug: security-updates-leaving-mach_kernel-visible
title: Security Updates leaving mach_kernel visible
wordpress_id: 908
---

In the past, there have been cases where system updates for 10.8.5 (and possibly earlier versions) leave the OS X kernel (at `/mach_kernel`) visible to users in the Finder. This file has since moved to `/System/Library/Kernels/kernel` in OS X Yosemite, but previously to Yosemite it is located at `/`, and included in the package payload for system updates like OS X Combo/Delta and Security Updates.

OS X installers and updaters typically keep this file hidden in the Finder using a tool called `SetFile`, which is able to set miscellaneous file flags including the "hidden" flag. The Security Update 2015-002 for Mavericks, released on March 9, 2015, does not include any of the postinstall "actions" (miscellaneous scripts and tools executed by a master script) in the installer that were present in the 2015-001 update.

{% include image.html
    caption="Comparison of SecUpd2015-001 and -002 installer scripts in <a href='https://www.charlessoft.com/'>Pacifist</a>"
    img="images/2015/03/secupd-actions.jpg"
    url="images/2015/03/secupd-actions.jpg"
%}

We have few admin users at my organization, but it has happened at least once that a curious admin user has wondered what this "mach_kernel" file is and moved it to the trash, only to find that their system volume will no longer boot.

Why does Apple continue to ship this bug when they have a [knowledge base article on it](https://support.apple.com/en-us/HT203829)?

Why does Apple not simply set the hidden flag in the file in the package payload, rather than depend on setting it according to a script? It is possible to set these flags on the file in a payload and not require any scripting to set a hidden attribute on a file.

We can fix this easily by distributing a script to clients that would do something like this:

```bash
if [ -e /mach_kernel ]; then
  if ! /bin/ls -lO /mach_kernel | grep hidden > /dev/null; then
    echo "Un-hidden /mach_kernel found, hiding"
    /usr/bin/chflags hidden /mach_kernel
  fi
fi
```

While Apple's acknowledged this issue given their knowledge base article, I still felt it's worth [opening a bug for](http://www.openradar.me/20120320).
