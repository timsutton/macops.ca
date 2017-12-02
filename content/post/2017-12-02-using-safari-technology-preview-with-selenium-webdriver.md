---
title: Using Safari Technology Preview with Selenium WebDriver
date: 2017-12-02T12:08:30-08:00
slug: using-safari-technology-preview-with-selenium-webdriver
tags:
  - selenium
  - safaridriver
---

I recently was attempting to diagnose an issue with the [Safari Driver](https://webkit.org/blog/6900/webdriver-support-in-safari-10/), the component of Safari which allows remote automation using the [WebDriver protocol](https://www.w3.org/TR/webdriver/). In order to confirm whether my issue was a bug, I wanted to run the same test using a current Safari Technology Preview build and compare the results to Apple's released Safari versions. I wasn't able to find very clear examples or documentation about this, however, and wanted to be able to test it both with a local `safaridriver` as well as via Selenium.

There are at least a couple of ways to do this. First you'll need to install the current Safari Technology Preview, via either:

  * Apple's official [download site](https://developer.apple.com/safari/technology-preview/)
  * brew-cask: `brew cask install safari-technology-preview`

The simplest way to test this is directly using the language binding of your choice, using `executable_path`. For example, using the Python selenium package (`pip install selenium`):

```python
from selenium import webdriver
driver = webdriver.Safari(executable_path='/Applications/Safari Technology Preview.app/Contents/MacOS/safaridriver')
```

The [3.8.0 release](http://selenium-release.storage.googleapis.com/index.html?path=3.8/) of Selenium server also supports setting this via `safari.options` in the desired capabilities. To test this locally, start up selenium 3.8.0 standalone:

```shell
java -jar selenium-server-standalone-3.8.0.jar
13:40:25.829 INFO - Selenium build info: version: '3.8.0', revision: '924c4067df'
13:40:25.832 INFO - Launching a standalone Selenium Server
[..more output follows..]
```

Then connect to it, and set `technologyPreview` in the `safari.options` dictionary:

```python
from selenium import webdriver
driver = webdriver.Remote(
    command_executor='http://localhost:4444/wd/hub',
    desired_capabilities={
        'browserName': 'safari',
        'safari.options': {'technologyPreview': True}
    }
)
```

That's it! You should see the purple Technology Preview app icon launch when launching the driver using these options. Thanks to [Brian Burg](http://brrian.org/) for pointing me in the right direction in the [#selenium IRC channel](https://botbot.me/freenode/selenium/).