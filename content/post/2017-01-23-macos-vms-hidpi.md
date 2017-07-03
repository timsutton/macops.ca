---
title: Enabling HiDPI macOS guest VMs in VMware Fusion
date: 2017-01-23T00:00:00Z
slug: macos-vms-hidpi
---

There are often times when I'd like to take a retina-quality screenshot of something on a macOS system (for this blog, or a presentation, for example), but I'd like to screenshot something that I've got running in a virtual machine. macOS VMs by default run at a standard resolution that's upscaled to the retina screen, making it look blocky by comparison - and more importantly, any screenshots taken within the guest VM will not be retina-resolution.

In this image I've stacked up two views of the General system preference pane, with the VM's on top, and my 5K retina iMac's on the bottom, for comparison (note that this difference will only be easily discernable if you're actually reading this on a retina device):

{{< imgcap
    img="/images/2017/01/retina-compare.png"
    caption="VM on top, native 5K iMac display on the bottom."
>}}

VMware Fusion does however have retina display support, whereby VMs can be enabled to run at the native pixel resolution at the given VM window size, documented [here](https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2034670). Since a picture's worth a thousand words, it looks like this:

{{< imgcap
  img="/images/2017/01/fusion-retina-settings.png"
>}}

That VMware KB includes this note:

> Mac OS X running in a virtual machine is limited to an approximate resolution of 2560 x 1600, and treats the display as a standard DPI device. This makes the text and icons to appear small in the OS X interface.

Indeed, toggling this setting immediately scales back the VM resolution and, while giving us more screen real-estate, makes things look tiny. Here's the Displays preference pane running in this configuration:

{{< imgcap
  img="/images/2017/01/vm-retina-1-to-1.png"
  caption="VM running within a window at 2474x1788 resolution. See icons, menubar and window elements for scale."
>}}

Luckily, Apple also supports this WindowServer preference that will force listing HiDPI-equivalent modes for the available resolution, which I've seen documented several places before like [here](https://www.tekrevue.com/tip/hidpi-mode-os-x/):

`sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true`

You'll need to at least log out and log back in again, but now listing the available resolution modes in the Displays preference pane should now expose a HiDPI version, which will actually render the window elements to look as they do on your native display:

{{< imgcap
  img="/images/2017/01/display-settings-retina.png"
  caption="Display settings window in a HiDPI resolution macOS VM."
>}}

The trick here that prompted me to write this is up is that I needed to set _both_ the guest VM's window server settings _and_ VMware Fusion's support for rendering a retina resolution VM window. It's not enough to just set one or the other. Happy screenshotting!
