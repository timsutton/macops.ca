---

comments: true
date: 2013-03-15 22:03:06+00:00
layout: post
slug: java-7-how-not-to-use-launchd-for-your-app
title: 'Java 7: How not to use launchd for your app'
wordpress_id: 418
tags:
- java
- launchd
- Sparkle
---

<!-- [![JavaCupLogo-161_tint](images/2013/03/JavaCupLogo-161.png)](images/2013/03/JavaCupLogo-161.png) -->

The Oracle Java 7 package contains launchd items to support its Sparkle-based background update check app that I complained about previously. In this post we'll go through its logic exhaustively and use it as an example of how to not deploy a LaunchAgent, and issues when trying clever things in LaunchDaemon scripts.

For some, there should be new information about how launchd works in general, as I think for many admins its behavior is somewhat opaque. Along the way I also learned some new launchctl command options.

<!-- more -->



### Introducing 'Helper-Tool'

First, let's paste the entire `Helper-Tool` script, and go through it. This is called by the `com.oracle.java.Helper-Tool` LaunchDaemon, and is triggered whenever the `com.oracle.java.Java-Plugin` LaunchAgent plist (which is actually a symlink to a plist in the plugin's `Contents/Resources` directory) is modified.

```bash
#!/bin/bash
# This is a specialized randomizer function
# that will randomize when AU will be triggered
# for sceduled updates for a Mac
rand(){
  local max_value="$1"
  n=$RANDOM
  var=$[ 1 + $n % $max_value ]
  retValue=$var
}

# Make the appropriate Changes to plist file post-AU if the com.oracle.java.Java-Updater.plist is changed
#Get the stored value of preferences
HTHOUR=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTHour 2> /dev/null`
HTMINUTE=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTMinute 2> /dev/null`
HTWEEKDAY=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTWeekday 2> /dev/null`
# Constants
LAUNCHD_PLIST_SRC=/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/com.oracle.java.Java-Updater.plist
LAUNCHD_PLIST_DEST=/Library/LaunchAgents/
LAUNCHD_PLIST_NAME=com.oracle.java.Java-Updater.plist
# Commands
PLISTBUDDY=/usr/libexec/PListBuddy
SED=`which sed`
CHMOD=`which chmod`
LAUNCHCTL=`which launchctl`

# Values
HOUR_VALUE=`date +%H`
MINUTE_VALUE=`date +%M`

# If defaults are already set then over-write with defaults. Else Randomize
if [ -z "${HTHOUR}" ] || [ -z "${HTMINUTE}" ] || [ -z "${HTWEEKDAY}" ]; then
	rand 7
        ${SED} -i "" -e "s/2/${retValue}/g" -e "s/00/${MINUTE_VALUE}/g" -e "s/09/${HOUR_VALUE}/g" "${LAUNCHD_PLIST_SRC}"
else
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Hour '${HTHOUR}'" "${LAUNCHD_PLIST_SRC}"
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Minute '${HTMINUTE}'" "${LAUNCHD_PLIST_SRC}"
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Weekday '${HTWEEKDAY}'" "${LAUNCHD_PLIST_SRC}"
fi
${CHMOD} 644 "${LAUNCHD_PLIST_SRC}"
${LAUNCHCTL} unload "${LAUNCHD_PLIST_DEST}/${LAUNCHD_PLIST_NAME}"
${LAUNCHCTL} load "${LAUNCHD_PLIST_DEST}/${LAUNCHD_PLIST_NAME}"[/ccen_bash]

According to the comments, as we suspected, the purpose of this is to "Make the appropriate Changes" to the LaunchAgent plist following an update.

[cce_bash]HTHOUR=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTHour 2> /dev/null`
HTMINUTE=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTMinute 2> /dev/null`
HTWEEKDAY=`defaults read /Library/Preferences/com.oracle.java.Helper-Tool HTWeekday 2> /dev/null`
```

Reading some preference values that were set by the installer postinstall script, suppressing error output in case the keys didn't exist. Ok.

```bash
# Commands
PLISTBUDDY=/usr/libexec/PListBuddy
SED=`which sed`
CHMOD=`which chmod`
LAUNCHCTL=`which launchctl`
```

Two problems. One, '/usr/libexec/PListbuddy' is a typo. It just goes unchecked because probably 99.9% of OS X systems are on a case-insensitive HFS+ filesystem, but OS X fully supports installation onto case-sensitive filesystems.

Two, defining commands' absolute paths using `which command` is useless. The `which` command works by searching the PATH environment variable for the executable. If you depend on being able to locate an executable by `which` in your script, you can skip pretending you're using absolute paths, because you've already assumed they'll be located in your PATH. You can get the default PATH used by launchd with the command: `launchctl getenv PATH`.

```bash
# Values
HOUR_VALUE=`date +%H`
MINUTE_VALUE=`date +%M`

# If defaults are already set then over-write with defaults. Else Randomize
if [ -z "${HTHOUR}" ] || [ -z "${HTMINUTE}" ] || [ -z "${HTWEEKDAY}" ]; then
	rand 7
        ${SED} -i "" -e "s/2/${retValue}/g" -e "s/00/${MINUTE_VALUE}/g" -e "s/09/${HOUR_VALUE}/g" "${LAUNCHD_PLIST_SRC}"
else
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Hour '${HTHOUR}'" "${LAUNCHD_PLIST_SRC}"
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Minute '${HTMINUTE}'" "${LAUNCHD_PLIST_SRC}"
        ${PLISTBUDDY} -c "Set :StartCalendarInterval:Weekday '${HTWEEKDAY}'" "${LAUNCHD_PLIST_SRC}"
fi
```

If any of the `HT` variables are undefined (`-z` tests for a zero-length string), then store a random value in `retValue`, and use the sed command to perform an inline replace it in the plist.

One might ask, if this system is designed specifically to "reset" the LaunchAgent schedule after an update, why not simply put this logic into a postinstall script instead, and set the schedule to something like once per day?

Using sed to modify a plist is just silly. Plists are structured data, and there are tools, like PlistBuddy used in the following three lines, that were made for exactly this. The `00` minute and `09` hour values correspond to the values that were already in the LaunchAgent plist delivered by the installer payload. This sed command is also already performed by the installer script.

Despite all of these silly workarounds to update a schedule plist, there are also weak assumptions in the if statement:

  * If any of the HT* variables stored in `com.oracle.java.Helper-Tool` by the installer don't exist, then it must be able to find exactly these stock `StartCalendarInterval` times in the `com.oracle.java.Java-Updater` plist, and that these wouldn't somehow conflict with numerical values elsewhere in the plist (we'll see later that if one enables debugging for this LaunchAgent, it will).
  * Two, PlistBuddy's 'Set' command requires the key to already exist - it does not add a missing key as with the 'defaults' command. The logic used by this if statement is vague, because it's assuming that if any one key in one domain `com.oracle.java.Helper-Tool` is missing, then we must be able to find all three of some other key in a different plist `com.oracle.java.Java-Updater`.

What's worse, is that by littering these various preference domains with various keys that all seem to be related to a schedule but only coupled by flawed scripts, admins that may poke at these values attempting to shortcircuit its update check behaviour may just further confuse the roundabout logic used in these scripts. Of course, vendors don't design their packages with poking in mind, but given that this concerns behaviour that most system administrators will immediately want to _disable_, it doesn't help to make it as difficult as possible to disable something that's usually trivial with other software, something even _Adobe_ can document and support.

Continuing on...

`${CHMOD} 644 "${LAUNCHD_PLIST_SRC}"`

Why would this be necessary? Permissions should be normally only handled by the installer payload, except in very particular circumstances that can usually be avoided. Maybe it's here because the permissions are actually _wrong_ (mode 664, when they should be mode 644) in the installer's payloads for both launchd plists.

### launchd and Session Types


```bash
${LAUNCHCTL} unload "${LAUNCHD_PLIST_DEST}/${LAUNCHD_PLIST_NAME}"
${LAUNCHCTL} load "${LAUNCHD_PLIST_DEST}/${LAUNCHD_PLIST_NAME}"
```

This brings us to the topic of launchd and "Session Types". LaunchDaemons and LaunchAgents can run in several different Session Types - for example, the 'Aqua' Session Type is run in the context of a user that is currently logged in at the GUI. You may have noticed before that when manually loading and unloading jobs, that you need to be root in order to manage jobs that are running at the system level, for example LaunchDaemons located in `/Library/LaunchDaemons`.

'LoginWindow' is another Session Type that can be specified if a job should be loaded only while the system is at the login window. The `LimitLoadToSessionType` key can be specified in a launchd plist to restrict in which Session Types it would normally be loaded, but using the 'launchctl' command permits the job to be loaded in other contexts. If `LimitLoadToSessionType` is omitted, then the default of `Aqua` is used. So in a normal scenario:
  
  1. Machine boots up, and loads the loginwindow.
  1. LaunchAgents that are able to run in the LoginWindow context are loaded.
  1. User logs in.
  1. Jobs running in the LoginWindow Session Type are unloaded, and the jobs available to run in the Aqua Session Type as the regular user are loaded.


There's a lot more in-depth and lower-level detail available in Apple's [Daemons and Agents Tech Note](http://developer.apple.com/library/mac/#technotes/tn2083/_index.html#//apple_ref/doc/uid/DTS10003794-CH1-SUBSECTION10). It's over five years old, however.

In most if not all cases, if the machine was asleep when the `StartCalendarInterval` time arrived, the job will run immediately upon waking. Even if the LaunchAgent job was somehow being loaded at the loginwindow (remember, this is to launch the Java Updater app), it would simply die and complain that no connection to the window server was possible. Actually, for this package, it _won't_, because the job's `StandardErrorPath` is set to `/dev/null`. More on that later.

But since Helper-Tool is running as root, its invocation of launchctl will load the job as root, and now, guess what? We have two separate instances of the LaunchAgent running. What do you think happens when the `StartCalendarInterval` time arrives?

{% include image.html
  caption="LSMultipleInstancesProhibited doesn't prevent it the app from running as multiple users!"
  img="images/2013/02/multiple-java-updaters.png"
%}

So now Java Updater is being run _twice_, once as you and once as root. The `LSMultipleInstancesProhibited` would prevent it from launching twice as a user (perhaps to prevent runs over weeks on an idle system from spawning the alert multiple times?), but it won't help here, when the alert is being launched as different users. Moreover, depending on how long the machine has been running without a reboot, there may be some time during which the job is running with two different times set in `StartCalendarInterval`.

Because Java Updater uses Sparkle, selecting "Skip this version" will set the `SUSkippedVersion` key in the app domain being used, which in this case is `com.oracle.java.JavaAppletPlugin`. The version is as it is defined in the Sparkle XML feed (which may or may not be equal to a bundle version key). Because it's running as two different users, these Sparkle-related preference keys are now defined in two different user homes. In other words, skipping a version as a normal user means that it will still run again as root, until it's skipped when it launches as root. (For what it's worth, these Sparkle preferences can be defined at the system level, but managing `SUSkippedVersion` keys for this application gets to be a very tedious game of catch-up, and is not at all how the key is intended to be used).

Just to be sure that this is really happening, here's the output of [`execsnoop`](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/execsnoop.1m.html), a DTrace utility that logs new processes as they occur. Notice the first execution is UID 0 (root) with a PPID (parent process ID) of 1, and the second is 501 (me) and a PPID of 329. The PPIDs correspond to the launchd manager process for the System and my user's bootstrap namespace. (You can check these yourself with the `launchctl managerpid` command.)

```
sudo execsnoop -a

TIME           STRTIME               PROJ   UID    PID   PPID ARGS
63549084439    2013 Mar  8 20:14:00     0     0  25320      1 Java Updater
63549107082    2013 Mar  8 20:14:00     0   501  25321    329 Java Updater
```

This relaunching-as-root issue is moot once the Mac reboots, of course, because then the LaunchAgent will load only in the user's Aqua context as usual. But with laptops, it's not uncommon to go for weeks without a reboot, which is about how frequently there have been recent security updates are being released.

### No logging

I mentioned earlier that the LaunchAgent's `StandardOutPath` and `StandardErrorPath` are both set to `/dev/null`. You're free to run the Java Updater binary yourself to mimic what would happen at the time the LaunchAgent job would run, but there's not much useful output. There's also a debug flag you can set in your shell environment if you'd like to see a bit more: set the `JPI_PLUGIN2_DEBUG` flag to something (it can be anything, it just must be set): `export JPI_PLUGIN2_DEBUG=1`. You'll then see some output like this if you run it manually:

```bash
cd /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/Java\ Updater.app/Contents/MacOS
./Java\ Updater

2013-03-08 21:56:08.177 Java Updater[27026:507] Found bundle at NSBundle  (not yet loaded)
2013-03-08 21:56:08.179 Java Updater[27026:507] Current bundle version = 1.7.13.20
2013-03-08 21:56:08.543 Java Updater[27026:507] updater:didFinishLoadingAppcast:
2013-03-08 21:56:08.544 Java Updater[27026:507] appcast = 
2013-03-08 21:56:08.545 Java Updater[27026:507] updater:didFindValidUpdate:
2013-03-08 21:56:08.545 Java Updater[27026:507] item = 
2013-03-08 21:56:08.545 Java Updater[27026:507] URL = http://javadl.sun.com/webapps/download/GetFile/1.7.0_17-b02/unix-i586/jre-7u17-fcs-bin-b02-macosx-x86_64-01_mar_2013_au.dmg
2013-03-08 21:56:08.545 Java Updater[27026:507] title = Version 1.7.0_17 (build b02)
2013-03-08 21:56:10.079 Java Updater[27026:507] Finished update attempt
```

So if we'd like to actually debug and log the behavior of the LaunchAgent itself, we can remove the `StandardOutPath` and `StandardErrorPath` keys (they default to the system log) and define our own environment variables in the job by setting the `EnvironmentVariables` key like so:

```xml
<key>EnvironmentVariables</key>
<dict>
    <key>JPI_PLUGIN2_DEBUG</key>
    <string>1</string>
</dict>
```

Of course, as soon as you modify this LaunchAgent to help you debug this, the Helper-Tool job helpfully runs and resets your modified `StartCalendarInterval` values and mangles your debug flag, because it just so happens to be looking for the string "2" _anywhere_ in the plist and sets it to a random day-of-week integer. When I was originally debugging this, I commented out enough of the Helper-Tool script to prevent it from resetting my changes to the plist. I'd then unload and load the LaunchDaemon.


### Diagnostic self-obfuscation

While Oracle's JRE package was clearly not meant to be consumed and scrutized in this manner by any user (or sane person), one has to seriously wonder why someone thought it helpful to go to such lengths to obfuscate the system's own mechanisms, hiding all traces of useful logging and status info; compare to the verbose output of Google's Keystone daemon during a background Chrome update. Setting aside the bizarre self-healing schedule – for something that probably _should_ be nagging the user once a day to update, since Apple will block it the next anyway – it's amazing how difficult the package even makes it to test and debug its behavior. It seems that the release engineer on this project was not interested in being able to debug and test this easily himself.
