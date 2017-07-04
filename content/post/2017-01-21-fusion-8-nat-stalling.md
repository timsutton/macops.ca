---
date: 2017-01-21T00:00:00Z
title: Stalling HTTP(S) downloads with VMware Fusion 8 and NAT
slug: fusion-8-nat-stalling
---

**Update**: This issue has been resolved in the VMware Fusion 8.5.7 update, [released in May 2017](http://pubs.vmware.com/Release_Notes/en/fusion/8/fusion-857-release-notes.html). The workaround below is no longer necessary. The release notes linked above don't sufficiently scope the issue, however: it's not only `git clone` commands which stall, it's any HTTPS transfer. `git clone` just happened to be an easy way to reproduce this with large repositories such as [CocoaPods](http://blog.cocoapods.org/Master-Spec-Repo-Rate-Limiting-Post-Mortem/).

VMware Fusion 8 is a great general-purpose virtual machine hypervisor which shares a lot of the same infrastructure as the VMware ESX platform, and is my preferred choice for running macOS guest VMs (on Apple hardware). It has great support for NetBoot, FileVault 2, and some additional advanced configuration support useful for testing Mac-based infrastructure projects.

I often use macOS guest VMs with Fusion in situations where large amounts of data need to be downloaded from either a local network or the Internet. Testing software installations using [Munki](https://github.com/munki/munki) is one of them, but so is testing CI worker bootstraps which involve things like running Apple's `softwareupdate` binary, or initializing a [CocoaPods](https://cocoapods.org/) installation, which involves a [very large initial Git clone](http://blog.cocoapods.org/Master-Spec-Repo-Rate-Limiting-Post-Mortem/) over HTTPS.

I noticed after updating Fusion to 8.1.0 (from 8.0.2), that my install tests that involved downloading large files over HTTPS (at speeds appropriate for a gigabit LAN) kept stalling somewhere in the middle of the transfer, indefinitely.

Eventually I noticed others reporting this issue as well, and I noticed it on machines running Fusion in different networks. It seemed like having at least a decently fast downstream connection was required to trigger the bug, possibly at least 40Mbps. It wasn't predictable where the stall would occur, but it _was_ pretty easy to reproduce.

Switching the VM to bridged networking instead of the default NAT would immediately resolve the issue, and I think most of the Mac admins I spoke with who ran into this issue simply did this as a workaround. (Many admins also just use bridged networking _anyway_, and so don't encounter this.)

Just to illustrate how easy it is to trigger, I [recorded a video](https://www.dropbox.com/s/du8m71hc6zthkho/VMware%20Fusion%20NAT%20bug.mp4?dl=0) in which I download the Office 2016 installer pkg (over a GB in size), and it stalls in 3 out of the 4 tries.

My strategy was to just stick with Fusion 8.0.2 for a while. But as time went on, and then macOS Sierra was released, I wanted to run newer releases (we're now at 8.5.3). So, I arrived at my current workaround for cases when I want (or need) to use a NAT configuration: replace the binary included with VMware Fusion that's (at least partially) responsible for handling NAT, with the older one that doesn't exhibit this bug. That file is located at `/Applications/VMware Fusion.app/Contents/Library/vmnet-natd`.

I've found that I can take either the binary from 8.0.2, or conveniently enough, VMware is currently [hosting](https://blogs.vmware.com/teamfusion/2016/01/workaround-of-nat-port-forwarding-issue-in-fusion-8-1.html) a drop-in replacement `vmnet-natd` binary that was provided as a workaround for a NAT-related port forwarding bug that surfaced for a while in the 8.1.x timeframe. So you can actually follow VMware's instructions on that workaround post to resolve this issue. That binary isn't identical to the one from 8.0.2, and is likely newer.

Here's a [custom Homebrew Cask](https://gist.github.com/timsutton/71d19da07f7e4a091c37fedcbd5cb9a1) file with an additional patching step for fetching and installing this old binary as part of a newer installation.

Of course, upgrading VMware Fusion means replacing this binary every time, and it's also quite possible that the newer verisons of `vmnet-natd` contain other fixes or improvements that you're discarding by not using the current version. And, it's a hack.

Just as I finished writing this post, I checked up on a recently-opened [VMware communities thread](https://communities.vmware.com/message/2644636), and I see a response that VMware's been able to reproduce the issue and that they expect to ship a fix in the next release. I'll leave this post here as a possible workaround, but hopefully in the next release this should no longer be necessary.
