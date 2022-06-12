---
title: Apple Silicon macOS Guest Virtualization Updates, June 2022
date: 2022-06-11T10:03:24-05:00
slug: virtualization-updates-2022-06
tags:
  - virtualization
  - monterey
  - ventura
  - anka
  - tart
  - apple-silicon
comments: false
---

It's been eight months since I published a [post]({{< relref "/post/2021-10-14-macos-monterey-apple-silicon-vms.md" >}}) with some early experiments and digging into the capabilities of Apple's new macOS guest VM support on Apple Silicon as of Monterey.

Since then, we've seen:

  * Improved documentation and a sample project from Apple
  * Lots of new developments in both commercial and open source projects using the framework
  * New APIs revealed during WWDC week with macOS 13 Ventura and Xcode 14

As with the previous post, since my interest in macOS virtualization is always in the context of continuous integration and ephemeral build/test environments, this article is framed around that particular use case. Let's dive in!


## Updated documentation

Apple updated their documentation in early 2022 to include a [fully-functional sample Xcode project](https://developer.apple.com/documentation/virtualization/running_macos_in_a_virtual_machine_on_apple_silicon_macs). Having a working example directly from Apple is nice because:

* It illustrates how little code is actually required to achieve the full functionality of a macOS guest VM. It does not require any detailed knowledge about hypervisors or hardware development, in the same way that would be required if implementing a hypervisor using the Hypervisor framework, for example.
* For filing feedback/radars to Apple for issues with the Virtualization framework, this can be used as a starting point for a reference project.
* It indicates that Apple is well-aware of external interest in these new APIs, such that they were willing to (relatively quickly) publish follow-up sample documentation. We can see Apple's interested in iterating further on this framework.

## New support in multiple virtualization products/projects

At the time of the last post, Parallels was the only commercial product which had already shipped basic macOS guest support on Apple Silicon using the new API features. I'm not sure we've seen notable improvements from them since, or any new developments from VMware Fusion.

But, we have seen many *other* products and open source projects adopting this framework! We'll go through some here:

### Anka

In late October, [Veertu](https://veertu.com/) announced a preview of their 3.0 version of Anka, their hypervisor and CI/CD tooling product, which uses the new framework on Apple Silicon, and several months later the 3.0 version reached a GA release. It already offers an impressive amount of parity with the existing featureset of the Intel-based version:

* The CLI interface to create, query, and otherwise manage the lifecycle of these VMs works the same. Creating a new VM from an archived copy of the macOS IPSW is as straightforward as: `ankacreate -a ~/UniversalMac_12.3_21E230_Restore.ipsw macos-12-3`
* It supports their [Packer builder plugin](https://github.com/veertuincpacker-plugin-veertu-anka) for creating new images using Packer
* It includes a guest tools package which prepares the VM for functionality enabling the rest ofAnka's intended CI/CD use-case. It:
  * Enables the functionality to copy files in and out of the VM, to enable easy automated provisioning of new VMs from a source repo
  * Adds clipboard sync to/from the host, useful when doing anything interactively with the VM via the Anka GUI app
  * Configures passwordless sudo (typical for a CI image and to enable proper automated provisioning through Packer)
  * Fixes other common issues in the OS for CI use-cases: disabling the screensaver, reconfiguring spotlight to run at a lower prioritiy, turning CrashReporter diagnostics submissions, enabling auto-login for the default user. It's really nice to have a single package just handling all of these as sane defaults for the use case. These are the sorts of things that nearly everyone running such machines for CI has to tweak, and keep up with changes to them over the years.
  * Keeps these tools' versions in sync with the Anka distribution version

Both bridged and shared network interfaces are possible. Since Anka was also designed to offer a similar user experience as Docker, it also has the notion of layered images. Given how large macOS CI images need to be (30GB+ with one Xcode version), the possibility to have a base image shared across multiple different image variants makes better space optimization possible.


### UTM

[UTM](https://github.com/utmapp/UTM) is an established open-source virtualization project for macOS and iOS to enable "traditional" virtualization of PC hardware and guest OSes based on Qemu. In the 3.0 release, support for macOS guest VMs on Apple Silicon using the Virtualization framework was added. It "just works" in the same way as with Parallels, but the GUI interface actually allows for more configuration, such as using both shared (NAT-based) and bridged network interfaces. UTM is under active development.

One notable new feature in the [3.2.4 version released in May](https://github.com/utmapp/UTM/releases/tag/v3.2.4) is that is can run a VM "disposably," where changes are only written to an ephemeral disk device that is discarded when the VM is stopped. There is a [PR open](https://github.com/utmapp/UTM/pull/3893) adding this functionality to macOS VMs, where the new VM disk is copied using NSFileManager's default APIs and are expected to result in an APFS clone operation under the hood (so that the VM's disk is cloned without needing to actually duplicate block data on underlying storage.)

As far as I'm aware, UTM doesn't yet offer a command-line interface for managing the VMs.


### Tart

In early May, CirrusLabs open-sourced [Tart](https://github.com/cirruslabs/tart), a CLI-based tool for Apple Silicon VMs specifically for the CI use-case. Currently this comprises:

* CLI-based operation (no GUI besides the actual GUI rendering of a VM's screen, if desired)
* Packer automated builds via a [builder plugin](https://github.com/cirruslabs/packer-plugin-tart)
* Support for pushing to / pulling from OCI-compliant image registries

Much like the other solutions above, it's in active development.


### MacStadium Orka 2.0

MacStadium's Orka product [now in their 2.0 version](https://www.macstadium.com/blog/orka-2.0-has-arrived) supports Apple Silicon using the Virtualization framework in a "beta" state. Their [documentation](https://orkadocs.macstadium.com/v2.0/docs/apple-arm-based-support-beta) lists some of the known limitations where Apple Silicon VMs aren't at parity with the Intel-based platform images.



### VirtualApple

An open-source project by [Saagar Jha](https://saagarjha.com/) was published after the previous article. What was particularly cool about this project at the time he released it, was that via a Framework-internal API it allows [explicitly configuring](https://github.com/saagarjha/VirtualApple/blob/c737f41dae24c40996ded7dccb222b160c857de8/VirtualApple/VirtualMachine.swift#L135-L145) a VM to boot to DFU or to the [Recovery environment](https://support.apple.com/en-ca/guide/mac-help/mchl82829c17/mac) (which allows us to reconfigure security settings such as System Integrity Protection, for example), and also to boot to earlier phases of the boot process and attach a debugger. Tart also [borrowed](https://github.com/cirruslabs/tart/pull/91) the same internal API to offer `--recovery` as a startup option for VMs.

Notably, the macOS 13 beta documentation for Virtualization [indicates](https://developer.apple.com/documentation/virtualization/vzmacosvirtualmachinestartoptions/4013558-startupfrommacosrecovery) there's a new `VZMacOSVirtualMachineStartOptions` subclass with a single property: `startUpFromMacOSRecovery`. This means there is now a public API for booting the VM into the recovery environment, new in macOS Ventura.

## New APIs in macOS Ventura

With WWDC week having just ended, Apple's published a [dedicated video session](https://developer.apple.com/videos/play/wwdc2022/10002/) on the Virtualization framework, including some of the new features intended for supporting Linux guest VMs.

[Apple's documentation delta viewer](https://developer.apple.com/documentation/virtualization?changes=latest_minor) is a nice way to see all the modifications. There's a lot changed:

* Boot-from-recovery feature mentioned above
* VirtIO console device support
* [SPICE](https://www.spice-space.org/) agent support for clipboard sharing
* USB mass storage support
* Mac trackpad (with full multi-touch events) support
* Generic unique machine identifier support
* More features to support Linux VMs: directory sharing, VirtIO graphics, Rosetta support

## What's left?

From talking with others interested in this framework, some other desired features tend to come up in conversation:

### Support for Automated Device Enrolment testing

Macs owned by an organization often provision them for staff via Automated Device Enrolment, whereby a Mac comes online and is able to automatically enroll into the organization's MDM by association through Apple Business (or School) Manager. Administrators routinely need to perform end-to-end testing of this enrollment process, and typically have several test machines expressly dedicated for this purpose. But, this requires more physical machines that need a desk, power, network connectivity and peripherals, and may also be more difficult to intentionally reset to a known baseline state. ([Erase all Contents and Settings](https://tombridge.com/2022/01/31/obliteration-behavior-and-the-mac-admin/) in Monterey makes this situation better).

With Intel-based VMs, administrators have for years been able to override/hardcode the serial number of the VM to mimic a serial number of a physical Mac, and this has allows them to emulate much of the same machine bootstrapping process on their own machines (in a VM) for development and testing purposes.

Many folks have expressed interest in being able to do the same using this new generation of VMs. Some have expressed this in the form of "I'd like to be able to set my VM's serial number," although the end goal is for it to be possible for an Apple Silicon VM to be able to behave as a physical machine would when it performs its initial provisioning and is associated with an MDM endpoint in Apple's DEP environment.

Apple folks, I'm aware of at least these FBs from companies interested in this: FB9947609, FB9948459, FB10025718, FB10026549, FB10027549, FB10076121.

### Snapshots

When users refer to snapshots as a functionality of a hypervisor, they may be referring to at least one of:

* Disk states
* The entire VM configuration including memory, CPU configuration, etc.
* 'live' OS snapshots, so that a VM could be restored to a particular point in time while booted

I think we see already there's some OS-level primitives of how to do the first one. Qemu QCOW2 disk formats offer this with the notion of a "backing file," where one base disk image can be used for all reads and all writes are directed to a new disk image (which could, for example, be discarded, as in the above-linked new feature in UTM). APFS file cloning allows us to make an independent "lazy" copy of the file that would change only once a new VM has been booted using that new cloned file. There's a slight caveat there that APFS cloning requires the source and destination to be part of the same logical volume.

A dedicated API for snapshots of the entire VM state including some or all of the above could certainly be interesting, as this is historically something that commercial hypervisor products have had to provide themselves.

## Wrap-up

To wrap up, a few other thoughts and addenda that don't fit above, but are worth mentioning and thinking about as we see the first major iteration on this framework from Apple:

### CacaoCast

CacaoCast, a French (both as-in of France *and* as-in Canadian!) podcast about Mac and Apple development, discussed macOS VMs for a few episodes and gave a shout-out to the previous post in their [episode here](https://cacaocast.com/episodes/248/). Merci les gars!

### Continued development for cloud-native use-cases

Will we see Xcode Cloud begin to use environments powered by Apple Silicon-based VMs? It seems they currently use commodity Xeon hardware to power these VMs, which must also afford a much higher VM-per-host density than the allowed 2 (as per the EULA and as is enforced for consumers of the new framework APIs). At *some* point we won't be seeing Intel-based OSes in use at all, but will we begin to see ARM-based macOS VMs possible on commodity hardware as we have seen done on Qemu/KVM for many years?

### Host-guest OS independence

One of the wins of using virtualization for server workloads is that the system OS version used to run tasks can be decoupled from the OS version running on the underlying hosts. For example, today in order to test and validate a new beta OS and its tools, iOS simulators, automation, etc. on a "bare-metal" macOS installation, I need to upgrade a small segment of my Mac CI machines to that beta OS, and lose some capacity in the meantime. I should (in theory) be able to instead just build a new image of the beta OS and selectively run it on certain workloads, allowing me to reserve my full capacity for regular use, and then gradually upgrade hosts to newer macOS versions at my convenience.

But, as much of the macOS VM support in this framework is delivered by paravirtualized VirtIO drivers, there *is* some more tight coupling still to the hosts. For example, we can see renderer communication and version negotiation information in the OS log in this example of a Montery 12.4 host and a Ventura 13.0 (beta 1) GPU client:

```
com.apple.Virtualization.VirtualMachine: (ParavirtualizedGraphics) [com.apple.gpusw.ParavirtualizedGraphics:renderer] Guest requested binary version: 43, setting binary version to: 31
```

We can see from the API docs that certain VM functionality will be supported only with newer macOS host versions, as they rely on functionality provided by the host's paravirtualization support. It is also possible that we also observe different performance or bugs. For example, while today I can successfully boot and run UI tests in an iOS 16 simulator in a Monterey VM running Xcode 14 (on a Monterey host), I can't do the same in Ventura VM (beta 1, mind) on the same Monterey host. I *do* have success doing the same on a Ventura host.

All this being said, I was never able to get a macOS Ventura beta VM up and running faster than this year's WWDC. Previously, there would be some fumbling with VMware Fusion and some tribal knowledge shared around on forums for either how to get the new beta OS to boot, or simply how to upgrade an existing VM to the new beta version, and there'd often be odd performance or UI bugs that might never be addressed. *This* year, with a built copy of Apple's sample documentation project and the IPSW I'd downloaded from the developer portal, I was running through Ventura's Setup Assistant in a VM in under 5 minutes. It took longer for me to *download the OS image* than to install it and boot into a new functioning VM. A huge 👏 to everyone at Apple who has worked on the underlying functionality that makes this possible.

### Performance parity

Having much of this VM functionality "hinged" on Apple's API implementation and host/guest OS support in some ways introduces some restrictions (the API's implementation is private). The upside however – besides this excellent integration and driver acceleration at the OS level – is that virtualization projects (both commercial and open-source) can differentiate on things *other* than the hypervisor performance or grahpics acceleration: development/testing workflows, custom host<->guest integrations, user interface, etc. We see this already in some of the different tools I've outlined above.

I can download Apple's sample documentation project, compile it and expect the same baseline performance as with commercial offerings, and this hasn't been possible before. As I mentioned earlier, this also makes it possible to partner with Apple engineering on virtualization support in general, reproducing issues in feedback, etc. in a way that was difficult in the prior time of having no official macOS guest VM support APIs from Apple.
