---
date: 2013-09-18T13:56:02Z
slug: java-7-web-plugin-deployment-redux
tags:
- Disabling update checks
- installer scripts
- java
title: 'Java 7 web plugin deployment: redux'

wordpress_id: 536
---

<!-- [![JavaCupLogo-161](images/2013/02/JavaCupLogo-161.png)](images/2013/02/JavaCupLogo-161.png) -->

The Oracle Java 7 JRE (a web plugin) began shipping last year, and has grown a small maze of clever mechanisms to maintain a schedule of checking for updates. It's a sad tale of the misuse and abuse of launchd schedule re-writes and re-loads, the Sparkle Framework, storing Java properties-like prefs in OS X defaults, and having two different systems that actually check for updates implemented in two different languages and runtimes.

I covered this earlier this year in a [couple](http://macops.ca/everything-youll-wish-you-didnt-know-about-disabling-java-7-updates/) [posts](http://macops.ca/java-7-how-not-to-use-launchd-for-your-app/). It also prompted me to write an [overly-opinionated recipe for AutoPkg](https://github.com/autopkg/recipes/blob/78f07357c58142b2732f997d326ec204ee6c4506/OracleJava7/OracleJava7.munki.recipe#L41-L65). 

{{< imgcap
  caption="Update-checking control in the Java Control Panel"
  img="/images/2013/09/j7u40_panel@2x.png"
>}}

The takeaway from those previous two posts is that the plugin has a mechanism triggered by the applet to check for updates, but because this only runs once the plugin is loaded via a browser, there is also a background-check LaunchAgent that prompts the user to install the latest version via a Sparkle dialog (a process which later goes and re-loads LaunchAgents as root instead of you, but read the earlier blog posts if you care.)

Now that Update 40 has been out for over a week, I've taken some time to look at the changes to the installation that should be of interest to anyone deploying it en masse.

<!--more-->

### -bgcheck

The background-check LaunchAgent at `/Library/LaunchAgents/com.oracle.java.Java-Updater.plist` (actually symlinked to a location inside the plugin's bundle) now runs the `Java Updater` binary with a new flag: `-bgupdate`, and this respects a preferences key `JavaAutoUpdateEnabled`. Full credit for picking this up goes to kbotnen in the ##osx-server IRC channel.

We can make use of the `JPI_PLUGIN2_DEBUG` debug environment variable to get some console output to test this assertion:

`export JPI_PLUGIN2_DEBUG=1`

Then set the pref and run the updater:

```bash
sudo defaults write /Library/Preferences/com.oracle.java.Java-Updater JavaAutoUpdateEnabled -bool false

/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/Java\ Updater.app/Contents/MacOS/Java\ Updater -bgcheck
2013-09-17 16:20:58.226 Java Updater[36898:707] Java Update Check is disabled
```

Let's switch it back off to test what happens without the preference set:

```bash
sudo defaults delete /Library/Preferences/com.oracle.java.Java-Updater JavaAutoUpdateEnabled

/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/Java\ Updater.app/Contents/MacOS/Java\ Updater -bgcheck
2013-09-17 16:23:18.534 Java Updater[36968:707] Java Update Check is enabled by default
2013-09-17 16:23:18.559 Java Updater[36968:707] Found bundle at NSBundle  (not yet loaded)
2013-09-17 16:23:18.559 Java Updater[36968:707] Current bundle version = 1.7.40.43
2013-09-17 16:23:18.924 Java Updater[36968:707] updater:didFinishLoadingAppcast:
2013-09-17 16:23:18.925 Java Updater[36968:707] appcast =
2013-09-17 16:23:18.925 Java Updater[36968:707] updaterDidNotFindValidUpdate:
2013-09-17 16:23:18.925 Java Updater[36968:707] update = JAVAUpdater
```

### com.oracle.*

So this takes care of the background updater. From now on, it should no longer be necessary to do silly tricks like unloading and removing symlinks after every installation just to disable it. But for the Java applet _itself_ performing update checks on loading, we'd like to be able to disable these too.

I'm no Java developer, but as far as I know it typically uses XML or ['properties'](http://en.wikipedia.org/wiki/.properties) files to store data (the latter especially for configurations or ini-like options). If I look at filesystem changes when unchecking the "Check for Updates Automatically", I eventually see a change show up in my user's folder at `~/Library/Preferences/com.oracle.javadeployment.plist`. This is essentially a plist representation of a the properties file, and the key of interest is `deployment.macosx.check.update` located within the `/com/java/deployment/` dict key.

Going back a step, this key also gets set automatically when the Java Control Panel loads and there are 1) no prefs yet in the `com.oracle.javadeployment` domain but 2) the `JavaAutoUpdateEnabled` key is set in `com.oracle.java.Java-Updater`. So it's possible that it's no longer needed to manage anything in `com.oracle.javadeployment`. However, it only gets populated if the Control Panel is launched, not on a regular loading of the web applet. It's hard to tell whether this matters, because testing this on the latest release obviously won't prompt about a new update being available.

If we did want to pre-set this properties-style pref anyway, it seems we can put this plist into the any-user domain at `/Library/Preferences/com.oracle.javadeployment.plist` instead of the user's, and we can whittle it down to the essential key:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>/com/oracle/javadeployment/</key>
    <dict>
        <key>deployment.macosx.check.update</key>
        <string>false</string>
    </dict>
</dict>
</plist>
```

It's possible that without adding some of the [version-specific properties settings](https://github.com/autopkg/recipes/blob/78f07357c58142b2732f997d326ec204ee6c4506/OracleJava7/OracleJava7.munki.recipe#L50-L51) the applet may still warn about outdated versions, but I really prefer to not add version-specific tweaks with every update, even if those tweaks can be automated - they're just one more thing to break and keep track of.

### Surprise! The installer has gotten worse

The bad news is, the postinstall script has grown some new warts. Here's the last section of the postinstall script that's new:

```bash
# Set Web Java and Security Level settings from config file
JAVA=${PLUGIN_FILEPATH}/Contents/Home/bin/java
DEPLOY_JAR=${PLUGIN_FILEPATH}/Contents/Home/lib/deploy.jar
CONFIG_FILE=/Library/Application\ Support/Oracle/Java/java.settings.cfg

"${JAVA}" -cp .:"${DEPLOY_JAR}":"install.jar" com.oracle.install.InstallOptions -f "${CONFIG_FILE}"

OPEN=`which open`
PLISTBUDDY="/usr/libexec/PlistBuddy"

# function to get default browser for current user
function GetDefaultBrowser() {
  LAUNCHSERVICES_PLIST="${HOME}/Library/Preferences/com.apple.LaunchServices.plist"
  NUM_DICT=`${PLISTBUDDY} -c "Print :LSHandlers:" ${LAUNCHSERVICES_PLIST} | grep "Dict"| wc -l`
  NUM_DICT=`expr ${NUM_DICT} '-' '1'`
  for i in `seq 0 ${NUM_DICT}`
  do
    LSHANDLERS=`${PLISTBUDDY} -c "Print :LSHandlers:${i}" ${LAUNCHSERVICES_PLIST} | grep "LSHandlerURLScheme"`
    if [ "${LSHANDLERS}" != "" ]; then
      LSHANDLERURLSCHEME=`${PLISTBUDDY} -c "Print :LSHandlers:${i}:LSHandlerURLScheme" ${LAUNCHSERVICES_PLIST}`
      if [ "${LSHANDLERURLSCHEME}" = "http" ]; then
        echo `${PLISTBUDDY} -c "Print :LSHandlers:${i}:LSHandlerRoleAll" ${LAUNCHSERVICES_PLIST}`
        return
      fi
    fi
  done
  echo "com.apple.safari"
}

# Launch verify Java URL, this script must be at the end of this file
if [ "$COMMAND_LINE_INSTALL" = "" ]; then
  DEFAULT_BROWSER=$(GetDefaultBrowser)
  `${OPEN} -gb ${DEFAULT_BROWSER} 'http://java.com/verify/?src=install'`
fi
```

Note the `install.jar` file referenced up on line 6, which is executed by the newly-installed Java runtime. The `java.settings.cfg` file doesn't get installed by the installer payload, but is assumed to exist when invoking this command. Maybe this is optional support for a deployment configuration file that can customize the installation. Either way, the script doesn't care to check whether it exists, and so this command will spit out a Java traceback in your install.log and happily continue on. Lucky for us this, isn't the last command executed in the script. Speaking of, what _is_ the last command in this script? It used to be launchctl commands that naively assumed they would always succeed in loading a LaunchDaemon. See the line at the end beginning with ``${OPEN}`.

We all love installers that call `open` after the installation run has finished, but they've at least done the right thing of checking for the existence of the `COMMAND_LINE_INSTALL` environment variable set by the installer framework when doing command-line installs.

But nested within that is the baffling `GetDefaultBrowser` function that seems to try to figure out your user's default browser setting by combing through the LaunchServices plist and defaulting back to `com.apple.safari`. My immediate reaction that this function would exist for handling something like Google Chrome, which has no support for the Java plugin as it's not yet 64-bit. But no, it just wants to know the bundle ID associated with the `http` URL scheme, so that it can pass it over to `open -b`, rather than trusting that `open` would do the right thing (use the default URL handler) with the `http://` URL being given to it.

On my system, where I don't install packages as my own user (because I'm not an admin), this failed when it managed to find a downloaded Chrome app bundle in my admin user's Downloads folder and tried to open the URL with _that_. This could similarly fail if you happen to do one-off installs by a local admin user on a desktop support call, if your admin user happens to have some history on the computer. Because this command on line 33 is the last command run in the script, the postinstall command exist non-zero and the install fails with no evident reason why, until I check the install log, see the first traceback error and realize I can safely ignore it, and then find the real cause of the error.

Deploying Java via a management utility like ARD, Casper or Munki should luckily always bypass this function invocation in the script altogether via setting `COMMAND_LINE_INSTALL`, but this is simply extremely poor form. No one should be putting scripts like this in a plugin installer that's widely used. Rich Trouton has [helpfully documented](http://derflounder.wordpress.com/2013/02/23/filing-bugreports-with-oracle-for-mac-os-xs-java-7/) where you can go to file a bug report to Oracle.
