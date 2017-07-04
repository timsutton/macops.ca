---
date: 2012-12-07T02:19:03Z
slug: customizing-hardware-model-filters-for-netboot
tags:
- DeployStudio
- NetBoot
- VMware Fusion
title: Customizing hardware model filters for NetBoot

wordpress_id: 198
---

<!-- [![](images/2012/12/XSNetInstall_256_crush.png)](images/2012/12/XSNetInstall_256_crush.png) -->

Until the release of Lion, differentiating NetBoot images for DeployStudio Runtime to support different models was fairly simple. You'd have a Universal 10.5 image for booting PowerPC machines, and a 10.6 Intel image for Intel machines.

Then Lion was released, and supported _nearly_ every Intel Mac, leaving only the first generation models with [32-bit Core](http://en.wikipedia.org/wiki/Intel_Core#Enhanced_Pentium_M_based) processors behind. Then Mountain Lion was released, and the compatibility matrix became more complex. With Apple announcing at the same time that they would be releasing a major new version of OS X every year, we can expect this trend to continue, and that we'll need to know exactly which models can boot which versions of OS X. We'll take a look at how we can offload this decision to the NetBoot server to make the process as simple as possible on the client end.

<!--more-->


### Enter model filtering

NetBoot has had support for model filtering for some time, which allows you to filter what models of Mac will be allowed to boot a given image via the NetBoot service. The goal is that you can maintain multiple OS versions of an installation or utility NetBoot image (like DeployStudio's Runtime image) and let the server handle offering the version that a client can actually boot. NetBoot allows you to specify a 'default' image, which can be useful for older Intel Macs whose EFI firmware doesn't support selecting from multiple NetBoot images, but the end goal is that someone can hold the 'N' key to NetBoot a machine and not need to know what OS they need to boot what hardware.

DeployStudio recently added a new feature in its Assistant application (which effectively drives the `sys_builder.sh` script contained within its application bundle) for configuring NetBoot Runtime images to support hardware model filtering. Specifically, they needed to add the `DisabledSystemIdentifiers` and `EnabledSystemIdentifiers` arrays to the `NBImageInfo.plist` which resides at the root of the resulting `.nbi` folder. Even if these are empty arrays, the Server GUI will enable the editing of model filtering once these keys are present.

One downside to Apple's provided GUI for the NetBoot service is that this database of Mac models is only kept up to date for the lifespan of that version of Server. For example, if you are still hosting NetBoot on Snow Leopard Server, you can't instruct the service via the GUI to whitelist a 10.8 image to a 2012 MacBook Pro, because this model metadata was never backported to Server Admin for 10.6. In fact, it's the last month of 2012 and I can't find metadata pertaining to _any_ 2012 Mac in the most recent versions of OS X Server for both Lion and Mountain Lion (and as of Mountain Lion Server, NetBoot is now NetInstall).

{{< imgcap
	caption="As of December 2012, no hardware more recent than \"Early 2011\""
	img="/images/2012/12/netinstall-modelfilter_crush.png"
>}}

### Configuration


The model filtering selections are stored using hardware model identifiers (in the familiar style 'iMac10,1', 'MacBookAir4,1') in the `NBImageInfo.plist` file. You can edit this file directly as it's in XML format, though you should probably work off a copy for safety. You may also need to restart the NetBoot service in order for it to reload the changes.

For my environment, I decided to offer two NetBoot Runtime images: one for 10.6 to cover all older hardware, and a 10.8 image for all other Macs. Here's my current `NBImageInfo.plist` for the 10.8 image:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Architectures</key>
    <array>
        <string>i386</string>
    </array>
    <key>BackwardCompatible</key>
    <false/>
    <key>BootFile</key>
    <string>booter</string>
    <key>Description</key>
    <string>DStudio-R134</string>
    <key>DisabledSystemIdentifiers</key>
    <array>
        <string>iMac4,1</string>
        <string>iMac4,2</string>
        <string>iMac5,1</string>
        <string>iMac5,2</string>
        <string>iMac6,1</string>
        <string>iMac7,1</string>
        <string>iMac8,1</string>
        <string>MacBookAir1,1</string>
        <string>MacBookPro1,1</string>
        <string>MacBookPro2,1</string>
        <string>MacBookPro3,1</string>
        <string>MacBookPro4,1</string>
        <string>MacBook1,1</string>
        <string>MacBook2,1</string>
        <string>MacBook3,1</string>
        <string>MacBook4,1</string>
        <string>Macmini1,1</string>
        <string>Macmini2,1</string>
        <string>MacPro1,1</string>
        <string>MacPro2,1</string>
    </array>
    <key>EnabledSystemIdentifiers</key>
    <array>
        <string>iMac9,1</string>
        <string>iMac10,1</string>
        <string>iMac11,1</string>
        <string>iMac11,2</string>
        <string>iMac11,3</string>
        <string>iMac12,1</string>
        <string>iMac12,2</string>
        <string>MacBook5,1</string>
        <string>MacBook5,2</string>
        <string>MacBook6,1</string>
        <string>MacBook7,1</string>
        <string>MacBookAir2,1</string>
        <string>MacBookAir3,1</string>
        <string>MacBookAir3,2</string>
        <string>MacBookAir4,1</string>
        <string>MacBookAir4,2</string>
        <string>MacBookAir5,1</string>
        <string>MacBookAir5,2</string>
        <string>MacBookPro5,1</string>
        <string>MacBookPro5,2</string>
        <string>MacBookPro5,3</string>
        <string>MacBookPro5,4</string>
        <string>MacBookPro5,5</string>
        <string>MacBookPro6,1</string>
        <string>MacBookPro6,2</string>
        <string>MacBookPro7,1</string>
        <string>MacBookPro8,1</string>
        <string>MacBookPro8,2</string>
        <string>MacBookPro8,3</string>
        <string>MacBookPro9,1</string>
        <string>MacBookPro9,2</string>
        <string>MacBookPro10,1</string>
        <string>MacBookPro10,2</string>
        <string>Macmini3,1</string>
        <string>Macmini4,1</string>
        <string>Macmini5,1</string>
        <string>Macmini5,2</string>
        <string>Macmini5,3</string>
        <string>MacPro3,1</string>
        <string>MacPro4,1</string>
        <string>MacPro5,1</string>
    </array>
    <key>Index</key>
    <integer>1082</integer>
    <key>IsDefault</key>
    <false/>
    <key>IsEnabled</key>
    <true/>
    <key>IsInstall</key>
    <true/>
    <key>Kind</key>
    <integer>2</integer>
    <key>Language</key>
    <string>English</string>
    <key>Name</key>
    <string>DeployStudio-10.8</string>
    <key>RootPath</key>
    <string>NetInstall.dmg</string>
    <key>SupportsDiskless</key>
    <false/>
    <key>Type</key>
    <string>NFS</string>
    <key>osVersion</key>
    <string>10.8</string>
</dict>
</plist>
```

My goal was to offer only one image for any given model I want to support, so here I've put each model in either one of `DisabledSystemIdentifiers` or `EnabledSystemIdentifiers` arrays (I've skipped Xserves, but I don't think I've missed any others). The contents of these arrays are reversed in the 10.6 image, so that every model identifier is only enabled for one image. In the near future when we have 10.9-based images, it's likely that we'll still only require two generations of NetBoot images, but using this method we could have more if we desired.

Because this plist is per-image and it's labour-intensive to build the lists of system identifiers, it would be a good idea to have backups of these lists to use as new versions of NetBoot sets are built for new versions of OS X and DeployStudio. Or, script adding them automatically after calling sys_builder.sh with pre-defined arguments.


### Sources of truth

Apple makes use of the 'board-id' to determine whether a version of OS X 10.7 or 10.8 can be installed on a given machine. This can be retrieved via the ioreg command (ie. `ioreg -l | grep board-id`) and looks something like `Mac-F4208CA9`. Lists of these board-ids are in the Distribution files for the OS installers, and are also in a plist at `/System/Library/CoreServices/PlatformSupport.plist` within an `InstallESD.dmg`. What's also interesting is that as of OS X 10.7.5 and 10.8.1, this plist contains a second array called `SupportedModelProperties`, which is a list of model identifiers. It would seem at first that perhaps this list could be directly mapped to the arrays we're managing in the `NBImageInfo.plist`. However, there are several hardware models missing from `SupportedModelProperties` that I know are supported versions of the OS on those models, so unfortunately it looks like this isn't a definitive list of models that's used by installer, or at least not for determining eligibility for installation. A Mac will send its board-id and serial number to Apple via HTTP during [Internet Recovery](http://support.apple.com/kb/HT4718), but I'm not aware of a model-to-board-id mapping source anywhere. It's possible that an organization with enough Macs could compile one itself.

For the many models that can boot both 10.6 and 10.8, there's no systematic reason I had for choosing one OS version over another for a given model. You might have your own reasons – newer OS versions of Runtime NBIs have sometimes taken longer to support all workflow features, for example live package installs were not working for some time on Lion-based Runtime images.


### Testing with VMs

Lastly, if you do implement this method and use VMware Fusion to test your NetBoot environment, your OS X VMs will not boot without a minor change. In Fusion 4.1, VMware added a [new configuration option](http://communities.vmware.com/message/1865986) for VMs: **hw.model.reflectHost**. This option can be set in the VM's `.vmx` file located at the root of its `.vmwarevm` folder, and passes the host's hardware model string through to the VM. [Pepijn Bruienne](http://enterprisemac.bruienne.com) also [pointed out on Twitter](https://twitter.com/bruienne/status/263455723864875008) the **hw.model** configuration option, which is even better: it allows arbitrary model strings, which allows you to test that a specific model will boot the image you intend it to. You could also use this to test any installer or script logic that depends on hardware model identifiers (for example, hardware-specific Apple Software Updates).
