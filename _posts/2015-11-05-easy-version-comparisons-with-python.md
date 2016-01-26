---
comments: true
date: 2015-11-05 18:52:11+00:00
layout: post
slug: easy-version-comparisons-with-python
title: Easy Version Comparisons with Python
wordpress_id: 1250
tags:
- Python
---

This is just a little taste of why sysadmins find Python so approachable. If you've managed systems for long enough, you've probably had a need to compare two versions of something. For example, you want to do one thing if a given application or package is less than `2.0`, and another thing if it's greater. (For example, upgrade the application or package, or configure it differently in either case.)

If you've ever tried to do this in Bash, it's terrible. And you may have seen various installer scripts that attempt to do this. Or even doing this [within Installer distribution scripts](https://blog.frd.mn/java-7-on-os-x-yosemite/), despite there being [more robust mechanisms](https://developer.apple.com/library/mac/documentation/DeveloperTools/Reference/DistributionDefinitionRef/Chapters/Distribution_XML_Ref.html#//apple_ref/doc/uid/TP40005370-CH100-SW34) already provided by the OS that require no scripting.

Here's an example from a support script that runs as part of installing Blackmagic DaVinci Resolve, where it does a version check to make sure it already has at least their minimum supported version of CUDA:


```bash
if [ -d /Library/Frameworks/CUDA.framework ]
then
    INSTALLED_CUDA_VER=`defaults read /Library/Frameworks/CUDA.framework/Versions/Current/Resources/Info.plist | \grep CFBundleVersion | sed -e 's/"//g' | sed -e 's/;//g' | awk '{print $3}'`
    INSTALLED_CUDA_VER_MAJOR=`echo ${INSTALLED_CUDA_VER} | cut -d\. -f1`
    INSTALLED_CUDA_VER_MINOR=`echo ${INSTALLED_CUDA_VER} | cut -d\. -f2`
    INSTALLED_CUDA_VER_PATCH=`echo ${INSTALLED_CUDA_VER} | cut -d\. -f3`
    if [ "${INSTALLED_CUDA_VER_PATCH}" == "" ]
    then
        INSTALLED_CUDA_VER_PATCH=0
    fi

    INSTALLED_CUDA_VER_NUM=`echo "${INSTALLED_CUDA_VER_MAJOR} * 10000 + ${INSTALLED_CUDA_VER_MINOR} * 100 + ${INSTALLED_CUDA_VER_PATCH}" | bc`
else
    INSTALLED_CUDA_VER_NUM=0
fi



CUDA_VER="6.5.46"
CUDA_VER_MAJOR=`echo ${CUDA_VER} | cut -d\. -f1`
CUDA_VER_MINOR=`echo ${CUDA_VER} | cut -d\. -f2`
CUDA_VER_PATCH=`echo ${CUDA_VER} | cut -d\. -f3`
CUDA_VER_NUM=`echo "${CUDA_VER_MAJOR} * 10000 + ${CUDA_VER_MINOR} * 100 + ${CUDA_VER_PATCH}" | bc`

if [ ${INSTALLED_CUDA_VER_NUM} -ge ${CUDA_VER_NUM} ]
then
    echo "    --- CUDA is already installed - skipping step"
    return
fi
```

This is converting each "component" of the version into some multiple of 10, by putting together an arithmetic expression, and _then_ piping it to the `bc` command (which was new to me), and finally using Bash's `-ge` ("greater or equal than") operator. This might be safer and more portable than doing arithmetic within Bash, I don't know.

Is this readable? Sort of (not really). This one of the more elaborate but perhaps also more "correct" examples I've seen from installer packages in the wild.

If you use the JAMF Casper suite to install software, and would like to create a Smart Group that contains a criteria where some version of something is "less than" a given version, you may have found that there's no built-in way to do this, despite it being an [oft-requested feature](https://jamfnation.jamfsoftware.com/featureRequest.html?id=224). You can do SQL-like comparisons on the versions as strings, but this does not equate to an actual logical comparison of the "a.b.c" format that is often used for versions. In fact, this doesn't even compare a single integer, it's just doing simple string operations, one of "equals," "not equals," or "LIKE" wildcard comparisons.

Getting data like "is the Java plugin installed on a client at least version X.Y" actually requires writing a purpose-built script that can return a value on the client (known as an Extension Attribute in Casper parlance). Casper admins who use it to manage software [tend to do this a lot](https://jamfnation.jamfsoftware.com/search.html?type=file&fileType=1&q=version+is+out+of+date), and have many such nearly-identical scripts. So either for cases like this, or for some other ad-hoc usage like I described earlier, it is sometimes very handy to have a lightweight, readable way of comparing versions of things, using tools that are available on every shipping version of OS X.

Python's `distutils` package contains a "version" module containing some basic classes for doing version comparisons, like `LooseVersion` and `StrictVersion`. These contain enough logic to know that, for example, "1.0" is less than "1.5", but that "1.10" is greater than "1.9" (even though if you were comparing these as floats or decimals, the latter example would be evaluated differently).

Here's a very simple example. This will simply print the value which is evaluated as the highest version according to `LooseVersion`, or "equal" if they're the same. It's pretty readable, no?

```python
#!/usr/bin/python

import sys
from distutils.version import LooseVersion

# Let's create LooseVersion objects out of the 1st and 2nd arguments
# (sys.argv[0] is our script itself)
a, b = LooseVersion(sys.argv[1]), LooseVersion(sys.argv[2])

if a > b:
    print a
elif b > a:
    print b
elif a == b:
    print 'equal'
```

Save this script to some file, make it executable, and give it two arguments:

```bash
➜ ./highest_version.py 1.10 1.9
1.10
```

One thing to note about this `distutils.version` module is that it may not be present in all Python distributions. And going forward, this module seems to have been deprecated in favour of [another approach](https://www.python.org/dev/peps/pep-0440/). However, if you're reading this because you need to manage or automate tasks on OS X machines, you can safely rely on this module being part of every system distribution (thus me specifying `#!/usr/bin/python` above) as of at least 10.6, as long as you trust that your systems' Apple-provided Python distributions are safely intact - which from is harder to screw up thanks to [System Integrity Protection](https://en.wikipedia.org/wiki/System_Integrity_Protection).

I highly recommend anyone wrangling shell scripts look at Python (or Ruby, or Swift, or Go, or..) as an empowering tool to help you perform sysadmin tasks more safely and effectively. But if your Bash script in question is working just fine and you just want a better way to compare versions, you can even hack in an example like the one above into its own self-contained Bash function:

```bash
#!/bin/sh

greater_than_or_equal() {
    python - "$1" "$2" << EOF
import sys
from distutils.version import LooseVersion as LV
print LV(sys.argv[1]) >= LV(sys.argv[2])
EOF
}

echo $(greater_than_or_equal 1.2.1 1.2.0)
```

I'm not very proficient at Bash, but in this simple example I've made a function called `greater_than_or_equal` which assumes it gets two arguments, and sends a tiny Python script to the `python` interpreter binary via stdin, and should simply print `True` because 1.2.1 is greater-than-or-equal-to 1.2.0 (and `False` if otherwise).

This is just one example where Python is a great tool for performing actions that may otherwise be painful, and potentially dangerous to your systems, to do using shell scripting and built-in command-line tools.
