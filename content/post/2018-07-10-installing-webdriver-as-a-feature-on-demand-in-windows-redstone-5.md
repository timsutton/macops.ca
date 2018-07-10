---
title: Installing WebDriver as a Feature on Demand in Windows Redstone 5
date: 2018-07-10T08:00:20-07:00
tags:
  - Selenium
  - Microsoft Edge
---

Historically, Microsoft WebDriver, used for supporting automated testing of Microsoft Edge, has been a [separate download](https://developer.microsoft.com/en-us/microsoft-edge/tools/webdriver/) that should be matched to the major Edge version used in the OS.

In [Windows 10 Redstone 5](https://www.techradar.com/news/windows-10-redstone-5-rumors-release-date), WebDriver is [now a Feature on Demand](https://windowsreport.com/microsoft-webdriver-edge/). The details in the linked article are helpful to explain where the binary will end up after it is installed as an optional feature (`%SystemRoot%\system32`), however I was still looking for a way to automatically install the binary without needing to navigate to the Settings app and find the right sub-menu. Windows now has several places where something that could be named an "optional feature" can be added or installed, and as someone who doesn't administer Windows as a full-time job, I never find the right location on my first try.

Features on demand can be added and removed using [DISM](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/what-is-dism), using either the `dism.exe` command line tool, PowerShell cmdlets or the DISM API.

At the CLI, we can get a list of "capabilities" of the online Windows system. Try the following in an elevated command prompt:

```
> dism /Online /Get-Capabilities

Deployment Image Servicing and Management tool
Version: 10.0.17704.1000

Image Version: 10.0.17704.1000

Capability listing:

Capability Identity : Accessibility.Braille~~~~0.0.1.0
State : Not Present

Capability Identity : Analog.Holographic.Desktop~~~~0.0.1.0
State : Not Present


[...]


Capability Identity : Microsoft.WebDriver~~~~0.0.1.0
State : Not Present
```

We can then add WebDriver using the `/Add-Capability` option:

```
> dism /Online /Add-Capability /CapabilityName:Microsoft.WebDriver~~~~0.0.1.0

Deployment Image Servicing and Management tool
Version: 10.0.17704.1000

Image Version: 10.0.17704.1000

[==========================100.0%==========================]
The operation completed successfully.
```

I'd rather use PowerShell, so here is a handy one-liner that will just install any capability matching `Microsoft.WebDriver`, which I'm assuming there would only ever be one of.

```powershell
PS> Get-WindowsCapability -Online |
Where-Object {$_.Name -Match "Microsoft.WebDriver"} |
Add-WindowsCapability -Online


Path          : 
Online        : True
RestartNeeded : False
```

Once this is done, we can see the installed binary at `C:\Windows\system32\MicrosoftWebDriver.exe`, and it's now conveniently also in the PATH. Happy testing!
