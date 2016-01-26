---

comments: true
date: 2013-01-29 20:15:10+00:00
layout: post
slug: introducing-brigadier-a-tool-for-automated-boot-camp-driver-download-and-installation
title: Introducing Brigadier, a tool for automated Boot Camp driver download and installation
wordpress_id: 330
tags:
- Boot Camp
- Python
- Windows
---

<!-- [![bootcamp_drives_128.png](images/2013/01/bootcamp_drives_128.png)](http://macops.ca/introducing-brigadier-a-tool-for-automated-boot-camp-driver-download-and-installation/bootcamp_drives_128-png/) -->

Anyone doing Windows deployment on Macs, and dealing with getting and installing the Boot Camp drivers, has probably found it to be a pain point. I recently wrote a small tool called Brigadier that I'm now testing in my environment, that will fetch Boot Camp ESD packages for any model from either OS X or Windows.. and even install them automatically on Windows. You can point it to your internal SUS for fast download speeds.

It's written in Python, but if you want to run it on Windows, there's a single-file executable available as well, so that Python isn't required to be installed.

This might be interesting to you if you are doing an automated install of the drivers as a post-imaging task for deploying Windows images, because it handles downloading the correct package for the hardware running it. It's also a convenient way to get the right install package for a particular model (if, for example, you support other technicians setting up Boot Camp, but for whatever reason they're having problems getting the drivers.)

It can be downloaded from its GitHub repo [here](https://github.com/timsutton/brigadier).
