---
date: 2012-08-26T15:32:59Z
slug: disabling-updates-in-acrobat-pro-x
tags:
- Acrobat
- Adobe
- Disabling update checks
- preferences
title: 'Disabling updates in Acrobat Pro X: A case study in wasted effort'
---

<!-- [![](images/2012/11/aprox-updater_128x128.png)](images/2012/11/aprox-updater_128x128.png) -->

Adobe's Acrobat family of products has been historically painful for IT to distribute and manage. While this article focuses on a simple management setting – suppressing update checks and notifications for all users – it's an example of how configuring even the simplest, arguably most universally required management setting for an Acrobat-deploying IT department is an exercise in frustration at every turn, largely due to Adobe's Acrobat team insisting on reinventing the wheel for basic functionality already provided by native OS APIs and frameworks, compounded by many technical errors in their documentation.

On OS X, Acrobat Pro X and Reader 10 became distributable in the standard Apple pkg format, and this was generally a huge improvement for the deployment and update process. Acrobat Pro 9 currently requires _twenty_ sequential patches required to bring Acrobat Pro 9 to an up-to-date version.

{{< imgcap
  caption="Too many updates."
  img="/images/2012/11/acropro9-20updates.png"
>}}


Things are much better now, but configuring a common setting such as disabling update checks for all users has remained unnecessarily complicated, for despite Adobe using a property list to store these parameters, they were per-user only, requiring these to be managed either using MCX/Profiles or a manual script to apply the appropriate preference in every user's Library folder (ie. at login time with a LaunchAgent).

<!--more-->

Adobe has alluded to built-in functionality for disabling updates in Pro X in the past, so we'll summarize what's been presented to date:

**Adobe Provisioning Tool**

The [Adobe Provisioning Tool](http://ftp.adobe.com/pub/adobe/acrobat/mac/10.x/10.0.0/misc) would have you believe, going by its usage statement, that there is a `-M` option to suppress updates. There is no such functionality anywhere in the `adobe_prtk` binary on OS X.

**FeatureLockDown file**

The [AAMEE Technical Note](http://www.adobe.com/content/dam/Adobe/en/devnet/creativesuite/pdfs/AAMEE_Exception/en_us/AAMEE_Exceptions.pdf) on "Installing and Configuring Exception Payloads" suggests you can configure the FeatureLockdown system. It says to just modify a file inside the Acrobat Pro X .app bundle at `Contents/MacOS/Preferences/FeatureLockDown` and change this 822-character line:

```
<< /DefaultLaunchAttachmentPerms [ /c << /BuiltInPermList [ /t ()version:1|.ade:3|.adp:3|.app:3|.arc:3|.arj:3|.asp:3|.bas:3|.bat:3|.bz:3|.bz2:3|.cab:3|.chm:3|.class:3|.cmd:3|.com:3|.command:3|.cpl:3|.crt:3|.csh:3|.desktop:3|.dll:3|.exe:3|.fxp:3|.gz:3|.hex:3|.hlp:3|.hqx:3|.hta:3|.inf:3|.ini:3|.ins:3|.isp:3|.its:3|.jar:3|.job:3|.js:3|.jse:3|.ksh:3|.lnk:3|.lzh:3|.mad:3|.maf:3|.mag:3|.mam:3|.maq:3|.mar:3|.mas:3|.mat:3|.mau:3|.mav:3|.maw:3|.mda:3|.mdb:3|.mde:3|.mdt:3|.mdw:3|.mdz:3|.msc:3|.msi:3|.msp:3|.mst:3|.ocx:3|.ops:3|.pcd:3|.pi:3|.pif:3|.pkg:3|.prf:3|.prg:3|.pst:3|.rar:3|.reg:3|.scf:3|.scr:3|.sct:3|.sea:3|.shb:3|.shs:3|.sit:3|.tar:3|.taz:3|.tgz:3|.tmp:3|.url:3|.vb:3|.vbe:3|.vbs:3|.vsmacros:3|.vss:3|.vst:3|.vsw:3|.webloc:3|.ws:3|.wsc:3|.wsf:3|.wsh:3|.z:3|.zip:3|.zlo:3|.zoo:3|.term:3|.tool:3|.pdf:2|.fdf:2) ] >> ]
```

to this 843-character line:

```
<< /Updater [ /b false ] /DefaultLaunchAttachmentPerms [ /c << /BuiltInPermList [ /t (version:1|.ade:3|.adp:3|.app:3|.arc:3|.arj:3|.asp:3|.bas:3|.bat:3|.bz:3|.bz2:3|.cab:3|.chm:3|.class:3|.cmd:3|.com:3|.command:3|.cpl:3|.crt:3|.csh:3|.desktop:3|.dll:3|.exe:3|.fxp:3|.gz:3|.hex:3|.hlp:3|.hqx:3|.hta:3|.inf:3|.ini:3|.ins:3|.isp:3|.its:3|.jar:3|.job:3|.js:3|.jse:3|.ksh:3|.lnk:3|.lzh:3|.mad:3|.maf:3|.mag:3|.mam:3|.maq:3|.mar:3|.mas:3|.mat:3|.mau:3|.mav:3|.maw:3|.mda:3|.mdb:3|.mde:3|.mdt:3|.mdw:3|.mdz:3|.msc:3|.msi:3|.msp:3|.mst:3|.ocx:3|.ops:3|.pcd:3|.pi:3|.pif:3|.pkg:3|.prf:3|.prg:3|.pst:3|.rar:3|.reg:3|.scf:3|.scr:3|.sct:3|.sea:3|.shb:3|.shs:3|.sit:3|.tar:3|.taz:3|.tgz:3|.tmp:3|.url:3|.vb:3|.vbe:3|.vbs:3|.vsmacros:3|.vss:3|.vst:3|.vsw:3|.webloc:3|.ws:3|.wsc:3|.wsf:3|.wsh:3|.z:3|.zip:3|.zlo:3|.zoo:3|.term:3|.tool:3|.pdf:2|.fdf:2) ] >> ]
```

I did not find this method to work reliably.

You might also come across the topic of updates in the [Enterprise Administration Guide for Acrobat](http://helpx.adobe.com/content/dam/kb/en/837/cpsid_83709/attachments/Acrobat_Enterprise_Administration.pdf), and see a few options there (Section 15.6, page 139). We'll examine these in reverse order, because up until recently this would have been my order of preference (given that the first option was broken until very recently.)

**Option 15.6.3: Remove the Updater plugin itself**

This option is looking pretty good at this point, which is to remove the Updater plugin entirely to prevent it from checking for updates. However, we would need to make a point of doing this every time we run an updater pkg for Acrobat.

It's clear that we've reached a less read-over section of the guide, as there are ambiguous terms and incorrect filenames/paths in nearly _every written line_ of this section. Because Adobe so rarely follows system conventions in these implementations, I didn't feel like could easily gloss over an error and assume the writer meant to write something else.

**Option 15.6.2: Set the update mode to manual**

"The update mode is set on a per user basis as follows: (…)"

We can skip this – this is what we're already having to do, set per-user preferences with MCX, a Profile or script. In this case, we _can_ assume the writer meant to use the correct path to the plist file, and not one that doesn't normally exist on an OS X system.

**Option 15.6.1: Disabling and locking the Updater**

This sounds familiar to that FeatureLockdown no-line-break mess we're still trying to forget we were ever desperate enough to try in the first place. And in fact, it does seem to be using the same FeatureLockDown subsystem to disable the plugin, except it's writing the `bUpdater` boolean value in a plist. The documentation doesn't say at all _where_ this plist is, but we can take a good guess.

The obvious one to try is the system default preferences folder at `/Library/Preferences`. We can use these plist contents for both Acrobat Pro X and Reader, using the plist names `com.adobe.Acrobat.Pro.plist` and `com.adobe.Reader.plist`, respectively:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>10</key>
    <dict>
        <key>FeatureLockdown</key>
        <dict>
            <key>bUpdater</key>
            <false/>
        </dict>
    </dict>
</dict>
</plist>
```

It's documented to work as of 10.1.1, but it only works as of version 10.1.4 of Acrobat and Reader. Adobe was [pretty responsive](http://forums.adobe.com/message/4640192) in fixing the broken functionality once it was reported.

So now, the answer is pretty simple. Push a simple-enough plist to a system location or manage the preference as you would most others that work with the defaults system. I went through the previous options just as a demonstration of how Adobe manages to, in duplicating their own efforts in software implementations, effectively duplicate efforts by many orders of magnitude across IT organizations worldwide, who simply need to deploy a common application without resorting to scripted hacks and workarounds to manage very trivial behaviour.

It's great that Acrobat Pro X and Reader are getting easier to deploy and configure on OS X, but it's been a [long road](https://github.com/munki/munki/blob/master/code/client/munkilib/adobeutils.py) getting there.
