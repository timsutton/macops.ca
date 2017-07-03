---
comments: true
date: 2015-08-26T14:19:19Z
slug: whats-wrong-with-the-office-2016-volume-license-installer
tags:
- Office 2016
- packaging
title: What's Wrong with the Office 2016 Volume License Installer?

wordpress_id: 1155
---

Office 2016 for Mac comes in an installer package that has been causing several issues for Mac sysadmins deploying it in their organizations. At least a [couple](https://derflounder.wordpress.com/2015/08/05/creating-an-office-2016-15-12-3-installer) [posts](http://www.richard-purves.com/?p=79) exist already for how to "fix" the installer and deploy the software, but I haven't seen anyone actually detail some of these issues publicly. The best way to "fix" the installer is to have Microsoft fix it so that it can be deployed the same way we deploy any other software. Office is probably the most common software suite deployed in organizations, and so it's a very bad sign that 2016 for Mac has begun its life as an installer that cannot be deployed without workarounds and/or repackaging.

In this post, as usual I'll go into some detail about this installer's problems, review some known workarounds and propose some solutions.

<!--more-->

### Client software deployment tools

Microsoft provides Office 2016 for Mac in two flavors: one for Office365 subscribers which users can "activate" by signing into their O365 accounts, and one for organizations entitled to a volume license through some agreement. The volume license is activated during the install process, very similar to Office 2011. Volume licensed copies of software are often installed within organizations using automated deployment tools like [Munki](https://www.munki.org/munki/) or [Casper](http://www.jamfsoftware.com/products/casper-suite/). These tools make it possible for IT to deploy the software without numerous manual steps on each client, and control when the software is made available and in what context (i.e. do users install on their own via a self-service system, is it installed automatically at the time the machine is deployed to a user, or later on a schedule, etc.).

There are several ways in which the context of such deployment tools install software is different than that of a user manually installing software onto his or her own personal machine (where the user also has admin privileges), but two important ones are:

  * If installing a standard OS X installer package (.pkg, .mpkg), the installation will take place by some invocation of the `installer` command-line tool. This happens to set an environment variable, `COMMAND_LINE_INSTALL`, which is not present if an installer package is double-clicked and run using the standard Installer UI. Installer scripts may make use of this to adjust their behavior accordingly.
  * The installation may take place while no user is logged in, and the machine is waiting at the login window. This may be so because a machine has just had its OS installed or re-imaged, and the deployment tools are now automatically installing all the other software destined for this machine. A software may also _require_ a logout or restart, and therefore the deployment tools may opt to first log the user out so that the software can be installed.

### Office 2016's licensing packages

The volume license installer is provided as a Distribution installer package, which includes two components that specifically pertain to licensing: 1) com.microsoft.pkg.licensing, and 2) com.microsoft.pkg.licensing.volume. You can inspect these packages yourself using a GUI tool like [Pacifist](https://www.charlessoft.com/) or the [Suspicious Package QuickLook plugin](http://www.mothersruin.com/software/SuspiciousPackage/), or even simpler by using the `pkgutil` tool that's built-in to OS X, and just expand the flat package to a temporary directory:

`pkgutil --expand "/Volumes/Office 2016 VL/Microsoft_Office_2016_Volume_Installer.pkg" /tmp/office2016`

The com.microsoft.pkg.licensing package installs a LaunchDaemon and PrivilegedHelperTool, which provides infrastructure necessary to allow an application to perform the license activation without needing to ask for administrative privileges. This allows the licensing to be performed by any user on the system, and to store an "activation status" in a location that would normally required admin or root privileges. The package also runs a postinstall script that loads the LaunchDaemon, and if the installer was run within the GUI, the [bundled dockutil](https://github.com/kcrawford/dockutil) is invoked to add items to the user's dock.

The com.microsoft.pkg.licensing.volume package installs an application, "Microsoft Office Setup Assistant.app," to `/private/tmp`, and runs a postinstall script that runs the binary within this application bundle using `sudo`, so as to run the command _as the user who is logged in_. Finally, it removes this application bundle it just installed and exits 0, so that the installation will not be aborted if this process fails (even though the `rm` command, given the `-f` flag, should not exit anything other than 0). To know what user is logged in - or the user the script assumes is logged in - it reads the `USER` environment variable.

### Installing Office at the login window

In a command-line install, `$USER` will be the user running the `installer` command, and this will likely be `root`. But this is a side detail. Remember the earlier point about installations not necessarily being performed while a user is logged in? Here is what we see in `/var/log/install.log` if we invoke the installer while no user is logged in, via SSH, using a command like `installer -pkg /path/to/Office2016.pkg -tgt /`:

```
Aug 25 10:45:41 test-vm-yos.local installd[863]: PackageKit: Executing script "./postinstall" in /private/tmp/PKInstallSandbox.lNRt00/Scripts/com.microsoft.package.Microsoft_Word.app.nSM43R
Aug 25 10:45:41 test-vm-yos.local installd[863]: PackageKit: Executing script "./postinstall" in /private/tmp/PKInstallSandbox.lNRt00/Scripts/com.microsoft.package.Microsoft_AutoUpdate.app.eiUGrA
Aug 25 10:45:41 test-vm-yos.local installd[863]: PackageKit: Executing script "./postinstall" in /private/tmp/PKInstallSandbox.lNRt00/Scripts/com.microsoft.pkg.licensing.qL6FmB
Aug 25 10:45:41 test-vm-yos.local installd[863]: PackageKit: Executing script "./postinstall" in /private/tmp/PKInstallSandbox.lNRt00/Scripts/com.microsoft.pkg.licensing.volume.uqxBIt
Aug 25 10:45:42 test-vm-yos.local installd[863]: ./postinstall: _RegisterApplication(), FAILED TO establish the default connection to the WindowServer, _CGSDefaultConnection() is NULL.
```

The last line, `FAILED TO establish the default connection to the WindowServer, _CGSDefaultConnection() is NULL`, tells us that the application being run by the com.microsoft.pkg.licensing.volume package, Microsoft Office Setup Assistant, is an application that assumes it will be able to access a GUI login session, despite it not actually having any window elements that are normally shown to the user. If you run the Office 2016 installer normally in a GUI installer, you may notice this item bounce up in the dock ever so briefly in order to validate and write out a license file to disk. But in an automated installation at the loginwindow, this process starts and then stalls forever, with a process you can find yourself from running `ps auxwww`, a line which looks like:

`/usr/bin/sudo -u root /private/tmp/Microsoft Office Setup Assistant.app/Contents/MacOS/Microsoft Office Setup Assistant`

If I retry the above using Apple Remote Desktop as the package installation tool rather than SSH and `installer`, the process stalls but I see no error about the failure to connect to the WindowServer, presumably because the installation through ARD causes `USER` to be considered `nobody`:

`/usr/bin/sudo -u nobody /private/tmp/Microsoft Office Setup Assistant.app/Contents/MacOS/Microsoft Office Setup Assistant`

So if the Microsoft Office Setup Assistant tool is hanging during the installation, one might be prompted to use [choiceChangesXML](https://foigus.wordpress.com/2015/04/04/choicechangesxml-and-office-2011/) with installer so that the problematic package component can be skipped, and the installation can complete successfully.

### Office 2011

Office 2011 had a similar issue with its license subsystem, where if Office was installed _and updated_ at the loginwindow (say, on any fresh machine install) without a manual launch in between to at least "initialize" the activation, applications would behave as if Office was not activated at all. The solution, which [many](http://blog.michael.kuron-germany.de/2012/10/fixing-microsoft-office-2011-sp2-volume-licensing/) [organizations](https://derflounder.wordpress.com/category/office-2011/) employed, was to capture the license storage plist from `/Library/Preferences` on a known good machine, and redeploy this _same license file_ along with an installation of Office 2011, either a new install or one with the broken licensing issue. Many people have already found that this same approach - capturing the license file in `/Library/Preferences/com.microsoft.office.licensingV2.plist` and deploying this as a separate package is enough for Office 2016 to consider itself volume-licensed.

I've had to implement this solution for Office 2011 before, but it seems ridiculous that an application so widespread, with so much engineering behind it, can't be installed at the loginwindow without having its licensing data severed - especially given that the licensing procedure doesn't actually require any user input. The licensing tool runs, and the machine is now licensed. However, with a functioning, standard install, the licensing data is unique per machine. I dislike the idea of messing with (and repackaging, and redeploying) data that normally I should not need to know or care about, for which the application should be responsible, and which if something goes wrong the consequences are serious: Office ceases to function, or instead prompts users to sign in with O365 credentials to activate Office.

### More issues

Oh, but this is not even the only issue with the Office 2016 installer. There is also an auto-update daemon that Microsoft adds to the LaunchServices database using an undocumented `-register` flag to the `lsregister` binary. This command is also run using `sudo -u $USER`, but _only if_ not doing a command line install. It looks like the install script is trying to do the right thing by not doing some user-specific tasks (this lsregister command performs a change to the LaunchServices database for the user running the command) during a CLI install, however if this auto-update daemon is not manually registered in LaunchServices, the user will see a confusing dialog the first time they open any Office application and it checks for updates (as it does by default):

{{< imgcap
    img="/images/2015/08/Screenshot-2015-08-25-15.58.25.png"
>}}

This is another roadblock that a sysadmin will definitely want to avoid, and yet what is the solution? The postinstall script for the com.microsoft.package.Microsoft_AutoUpdate.app component package contains this in the postinstall script:

```bash
#!/bin/sh

if ! [[ $COMMAND_LINE_INSTALL && $COMMAND_LINE_INSTALL != 0 ]]
then
    register_trusted_cmd="/usr/bin/sudo -u $USER /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted"
    application="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
    if /bin/test -d "$application"
    then
        $register_trusted_cmd "$application"
    fi
fi
exit 0
```

One possible workaround is oddly appealing: don't install the volume license combined install package at all! Office 2016 updates are actually full application installers, one for each application update. These don't contain any of the licensing or auto-update related infrastructure that is included in the VL installer. Office 2016 applications will either use the Microsoft Auto-Update (MAU) tool that might be on the system already with Office 2011 if it exists, or if MAU doesn't seem to exist on the system, the applications will simply not offer any interface with which to check for updates. Most sysadmins that deploy software might like this option anyway, while others might prefer that there is still a means to perform updates ad-hoc, or expect users to all the applications to update on their own.

Some experimenting with the `lsregister` command hints at other options for trusting other "domains," references to which I can find only on [Charles Edge's blog](http://krypted.com/mac-security/lsregister-associating-file-types-in-mac-os-x/):

`sudo /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -domain system -domain user -domain local -trusted /Library/Application\ Support/Microsoft/MAU2.0/Microsoft\ AutoUpdate.app/Contents/MacOS/Microsoft\ AU\ Daemon.app`

Perhaps it is possible to "globally" register this daemon in these various domains so that a user doesn't need to individually register the daemon. Or perhaps a login script might be required to invoke this command at login time for every user, using a tool like [outset](https://github.com/chilcote/outset). Or perhaps admins will simply opt to not install MAU at all, so as to avoid this whole mess.

Patrick Fergus even [posted this exact issue](http://answers.microsoft.com/en-us/mac/forum/macinstall/office-preview-prompts-to-run-microsoft-au-daemon/3dbec2ed-6b04-4817-b5db-34205d3a1c35) to Microsoft's community forums four months ago, with no response.


### Complain More

I've quickly skimmed over two issues with the Office 2016 for Mac volume license installer, and have alluded to various workarounds that all involve some kind advanced trickery: using obtuse Installer choiceChangesXML overrides to avoid problematic packages, copying licensing plists from one machine to another, and modifying scripts that invoke under-documented OS X command-line tools with undocumented options. Others online who have posted about these issues have incorporated these into repackaging and custom scripts.

If you wrote the installer packages and scripts for a product like Microsoft Office, how would you feel if you found out that your product was non-deployable in its factory state, and that potentially thousands of sysadmins were breaking apart your packages and putting them back together in ways you never expected, making guesses about how your updates will be structured in the future, and bypassing your licensing creation mechanism altogether? Would you want to support an installation like this?

It's important to understand the mechanisms being used when installer scripts are involved in software you deploy and support in your organization. It's unfortunate that some of the most widely-used software also happens to be challenging to deploy, and the amount of effort required to convince vendors that there are issues - even just to get in contact with an actual release engineer - can be maddening at times. But if admins continue to quietly work around major issues like this, we cannot expect the situation to change.

So, escalate the issue through whatever supported channels are available to you. If you are a Microsoft Enterprise customer and have a Technical Account Manager, this seems to be the recommended route. If you're paying for support, make it worth it. Tweet at and e-mail people who might care and may be in a position to effect change.

Provide hard data about why it impedes your ability to install the software in a supported manner, and the scope of the impact, including the number of machines. Demonstrate that you cannot use supported tools like Apple Remote Desktop, or a paid management tool like Casper, to deploy their software without needing to perform destructive changes to their packages, or deploy "updates" as the base installation and copy a "golden master" licensing plist to all machines just to have the software function. Give specific examples about where the issues lie: suggest that their Setup Assistant tool be fixed so that it may be run purely at the command-line with no GUI login session required; suggest they devise a more robust way of handling the AU Daemon trust issue, so that a command-line install can result in an installation that's functionally the same as a manual GUI-driven installation.
