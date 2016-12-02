---
comments: true
layout: post
title: Squirrel Updates, the Slack Mac App and User Environment Variables
---

Today in the [Macadmins Slack](https://macadmins.herokuapp.com/) #autopkg channel, my friend [Ben](https://twitter.com/fuzzylogiq) mentioned he was seeing this update prompt for the non-Mac-App-Store version of Slack. It probably looked something like this:

{% include image.html
  img="images/2016/12/slack-helper.png"
%}

### Background

Dialogs like this are all too common for those who manage large numbers of computers, because of at least one of: *1)* Users running the applications aren't administrators and an application assumes they are, *2)* An application assumes a user can modify files or the app bundle in /Applications, and that there may only be, in fact, one user using this application on the computer, or *3)* An application has an auto-updater which is problematic to disable via a configuration profile or script.

Nearly _every one_ of the 100+ applications we install across my org needs some additional configuration to disable a built-in auto-updater.

I use [Munki](https://github.com/munki/munki) to deploy all of our software, and typically one deploys apps to `/Applications` (when copied from disk images) using `root:wheel` ownership, because it's considered a "system" install, not a user install. This can be overridden to another user, but there's an assumption that Munki is "managing" the installation of said application on the system.

This "helper tool" dialog shown above happens when the auto-updater used by Slack knows that it's not going to have the rights to modify the Slack app bundle (because it's owned by `root`), and so it prompts for admin authorization to install a helper tool so that it can do its work with elevated privileges.

### Squirrel, Slack and Sparkle

Slack recently did a [big rewrite](http://thenextweb.com/apps/2016/09/14/slack-beta-app/) using [Electron](http://electron.atom.io/), and it looks like they also adopted [Squirrel](https://github.com/Squirrel/Squirrel.Mac) for the auto-update component on both Mac and Windows. This stands to reason, as Squirrel is a companion project to the [Atom editor](https://atom.io/), out of which the Electron project was born.

Squirrel is a bit like the next generation of [Sparkle](https://sparkle-project.org/), supports Windows, and works using more server-side logic than Sparkle, which uses a simple RSS feed (which can still be generated using any server-side logic one wishes). But one nice thing about Sparkle is that there are [documented preference keys](https://sparkle-project.org/documentation/customization/) which can be used to control its behaviour, and while this has to be done for each individual app, the behaviour and methodology of doing this is understood and predictable.

We've supported Atom in our computer labs for a while, and have been deploying a supported configuration option in Atom itself to disable update checks. Atom still leverages Squirrel, but uses the configuration to decide whether it will even bother to check for updates at all. I could not easily find any such setting in the Slack Mac app.

### Continuous Updates

Some of these apps get updated a lot. Atom has had _seven_ [stable releases](https://atom.io/releases) over a three-week period last month (November). Yesterday I could open Slack and Atom on a managed desktop and get to work, but today it looks like this within a few seconds of opening the apps:

{% include image.html
  img="images/2016/12/slack-atom-helper-tools.png"
  title="All the helper tools"
  caption="Atom and Slack apps both prompting for admin rights to install a helper tool."
%}

Despite having great ease of automation thanks to tools like Munki and AutoPkg, we can never match pace with the upstream updates. We might turn around very quickly to get these updates out, but we can't predict the future.

You also can't easily test this if you've _only_ got the latest version of an app. You've got to go find an out-of-date version (which apparently doesn't take long) and install that to a test machine using the same tools. For example, using an admin user to just copy that old version to `/Applications` and then launch it won't necessarily trigger the dialog, because its auto-updater will already have the rights to overwrite the app bundle, provided `/Applications` still has the default group ownership of `admin`.

### Use the Source

Squirrel's [open source](https://github.com/Squirrel/Squirrel.Mac), so that's usually a good place to start looking. Typically in this case I'll see if they have any open issues or pull requests that have to do with "update check" or something of that nature, and search the wiki (if there is one) or documentation. GitHub's interface to immediately search the repo you're currently browsing is very convenient.

In the end, I found [this line](https://github.com/Squirrel/Squirrel.Mac/blob/bde5ff2983e91e7310c4139223ed04870e14a5b1/Squirrel/SQRLUpdater.m#L175) - which was very easy, just searching for the word "disable." This looks like an undocumented flag for debugging purposes. Apple's APIs provide `getenv()` as part of the standard C library, so here they're just checking for this `DISABLE_UPDATE_CHECK` environment variable to be set (to anything) as a master disable switch.

This is good enough for our purposes to see if we can disable the update check, at least for now.

### Environment Variables and LaunchServices

Most of us are familiar with how to set an environment variable via the shell, but how do we set this on macOS so that it will be understood in the context of a GUI app? There are a few ways, although perhaps fewer ways than were possible in earlier versions of the OS, which have been removed for [security reasons](https://www.virusbulletin.com/virusbulletin/2015/03/dylib-hijacking-os-x) - and some [other approaches](http://superuser.com/questions/476752/setting-environment-variables-in-os-x-for-gui-applications) have been documented but none of which look appealing.

LaunchServices [supports adding environment variables](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/20001431-106825) within the context of a bundle, however. It's possible to dig into the Slack Helper app, at:

`/Applications/Slack.app/Contents/Frameworks/Slack Helper.app`

and add the `LSEnvironment` key to its `Info.plist` file, like so:

```xml
<key>LSEnvironment</key>
<dict>
  <key>DISABLE_UPDATE_CHECK</key>
  <string>1</string>
</dict>
```

I shy away from editing `Info.plist` files for "released" software if at possible – even though it would be trivial to do this on each install using a post-install script – mostly because I worry that it could at some point break signing, if the developers sufficiently tighten the code signature requirements for the relevant app bundle.

### launchctl setenv

Another potentially more interesting option that also doesn't require us to modify any installation files, is to set this for any user as they log into the system, using `launchctl`. Again, the variable only needs to be set:

`/bin/launchctl setenv DISABLE_UPDATE_CHECK 1`

After setting this in the terminal _as the user launching the app_, we can see whether it will try and initiate an update (and it doesn't).

We can also check the state of these variables using `launchctl getenv <variable>` and unset them using (surprise) `launchctl unsetenv <variable>`.

To make this setting apply for all users (all the time), it must be done in the user's context on every login. To manage running automatic login scripts on a system, we have tools like [outset](https://github.com/chilcote/outset) or [LoginScriptPlugin](https://github.com/MagerValp/LoginScriptPlugin). Managing login and startup scripts is such a common pattern for administering desktop computers that it's something everyone should have in their toolkit anyway.

Setting this environment variable for a user will of course affect _all_ apps using Squirrel (or at least this publicly-available verion), which may or may not be what you want.

### Other methods?

I was hoping there might also be a way to set an environment variable as a user or managed preference in the context of the application itself, but still without modifying the bundle `Info.plist`, for example:

`defaults write com.tinyspeck.slackmacgap.helper LSEnvironment -dict-add DISABLE_UPDATE_CHECK -string 1`

But no such luck. Apple has some [overview documentation](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPRuntimeConfig/Articles/EnvironmentVars.html#//apple_ref/doc/uid/20002093-BCIJIJBH) about what options are available for setting an envionment variable, but it's from 2009 and doesn't seem to mention `launchctl`. The `launchctl *env` commands seem to be available going back at least as far as OS X Mavericks.

### Get Involved

What's great about products using open-source components like Electron and Squirrel, is that someone like me can go look at the source code and learn how it works, and propose or submit my own improvements. I've done that [here](https://github.com/Squirrel/Squirrel.Mac/issues/192), because I don't like the idea of relying on an undocumented flag like what I've shown above.

This idea about pitching in goes for _any_ issues you find with software you want to support in your environment but something about the application's design poses a problem. Mac installer packaging and versioning is a common problem area, and often you don't need to know how to write code in a "real" programming language to help an open source project fix that.

I'd encourage any Mac sysadmin who's eager to get some coding practice or learn an unfamiliar language or framework, and to participate in an open source project, to consider offering up such improvements yourself or at least begin the discussion with software developers, who often aren't aware that these issues exist for larger environments.
