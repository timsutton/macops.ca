---
title: Using VMware Fusion 10 on "old" Mac Pro Intel CPUs
date: 2018-09-12T16:18:35-04:00
slug: using-vmware-fusion-10-on-old-mac-pro-intel-cpus
tags:
  - vmware
---

VMware Fusion 10 was released in August 2017. One interesting change is that its [minimum system hardware requirements](https://kb.vmware.com/s/article/2005196) are more discerning in terms of the Intel CPU families supported. Notably, Mac Pro models from earlier than 2010 (i.e. earlier than `MacPro5,1`) are not supported. Attempting to start a VM on such Mac hardware results in the following dialog (screenshot is of version 10.1.2):

{{< imgcap
  img="/images/2018/09/fusion-macpro41.png"
  title="VMware Fusion 10"
>}}

### Unrestricted guest

Earlier versions had a more ambiguous dialog wording which didn't explain the incompatible features, however it seems as though currently they seem to be providing more detailed info, mentioning the "unrestricted guest" capability.

Originally I discovered this issue the hard way when VMware Fusion 8.5 on my MacPro4,1 system (dual 6-core X5550 CPUs) advertised the 10.0 upgrade, and happily let me run the upgrade on this system without any mention of this CPU feature requirement. I learned only of the system's incompatibility to show me the above notification after I was attempted to start an existing macOS VM from my VM library.

Luckily, this has been discussed already on VMware Fusion forums and the solution was quick at hand. There is a VMX config parameter, `monitor.allowLegacyCPU`, which can be set either directly within the VM's VMX file, or as a system-wide default in VMware's config file at `/Library/Preferences/VMware Fusion/config`. This file can simply be edited to set this value to `true`. For example:

```bash
$ cat '/Library/Preferences/VMware Fusion/config' 
monitor.allowLegacyCPU = "true"
```

Once this is set, VMs seem to happily run on these older generations of CPUs. Today, this MacPro4,1 machine is worth a tiny fraction of my 2017 MacBook Pro 13" with Touch Bar, but it handles the workloads of VMs not only much better than the MacBook Pro, but it also boasts many more cores, ideal for running more in parallel.


### Hypervisor.framework

This unrestricted guest feature happens is also required for the use of applications leveraging Apple's Hypervisor framework which was added in OS X 10.10. A few notable such applications:

* Docker for Mac (using Docker's [HyperKit](https://github.com/moby/hyperkit) project, derived from [xhyve](https://github.com/mist64/xhyve), in turn derived from [bhyve](http://www.bhyve.org/))
* [Parallels Desktop Lite](https://kb.parallels.com/en/123796) (available via the [Mac App Store](https://itunes.apple.com/us/app/parallels-desktop-lite/id1085114709)) - notably, the only free solution other than VirtualBox for running macOS guest VMs
* Veertu Hypervisor and [Anka](https://veertu.com/anka-technology/). The hypervisor used to be available on GitHub, but it would seem now I can only find [Google's cache of it](https://webcache.googleusercontent.com/search?q=cache:3oW4nskpXaoJ:https://github.com/veertuinc/vdhh/blob/master/README.md).

As Apple [documents](https://developer.apple.com/documentation/hypervisor?language=objc), one way to check if your hardware supports Apple's Hypervisor is to use `sysctl` and check for the value of `kern.hv_support` - if it is `1`, your machine should support using the Hypervisor framework. Here's the output from my MacPro4,1 to confirm that this framework is _not_ supported:

```
$ sysctl kern.hv_support
kern.hv_support: 0
```


### Unsupported

Of course, as enabling this `monitor.allowLegacyCPU` VMX option on Fusion 10 simply restores functionality on hardware that no longer meets the minimum system requirements, the usual caveats about unsupported software configurations apply. I also haven't yet noticed any instability or performance regressions in running macOS VMs on this hardware using this VMX option.
