---
comments: true
date: 2015-05-29T16:11:09Z
slug: adobe-creative-cloud-licensing-and-deployment-managing-licenses-with-munki
tags:
- creative-cloud
- munki
title: Adobe Creative Cloud Deployment - Managing Licenses with Munki

wordpress_id: 1019
---

<!-- [![munki_transparent](images/2015/05/munki_transparent.png)](images/2015/05/munki_transparent.png) -->

[Previously]({{< relref "post/2015-05-27-adobe-creative-cloud-licensing-and-deployment.md" >}}) we covered some boring details about Adobe Creative Cloud licensing and how this impacts deploying it to managed clients. We [also covered]({{< relref "post/2015-05-28-adobe-creative-cloud-deployment-packaging-a-license-file.md" >}}) a process and script I came up with that makes it slightly less painful to package up device and serial licenses for distribution to clients. Now, how to we manage these in a software management system? Since I use Munki, I'll use that as a model for how you might manage this license from an administrative standpoint. This is Munki-specific, but the principles should apply elsewhere.



### Munki

With Munki we use "manifests" as our instructions for what clients should do with the software in our repository. We can list items that _will_ be installed or uninstalled, or items that the user can install themselves via a self service app,"Managed Software Center." We can also use "conditional items," which let us restrict these rules within conditions that need to be satisfied based on certain criteria scavenged from the client (which themselves can be extended by the admin). Any manifest may represent a single machine or it might be shared across a group of machines. For more details on these concepts in Munki, here are links to [manifests](https://github.com/munki/munki/wiki/Manifests) and [conditional items](https://github.com/munki/munki/wiki/Conditional-Items) on the [Munki wiki](https://github.com/munki/munki/wiki).

Note that I'll be using the word "pool" a lot here, but those with enterprise license agreement types should be able to substitute "pool" with "serial number."

### Manifest/pkginfo structure

Here are a couple simple ways that Munki could handle managing the apps and licenses: we could add device file installers as separate items and add these to a manifest alongside the actual applications included in (or a subset of) that device file's corresponding pool. Here's an example of a Munki manifest with some CC 2014 applications, and notice in the last item I've added the licensing package to be installed independently of the applications. These application items are all packages built as Named licensed packages, which means they are effectively unlicensed. See our [first post]({{< relref "post/2015-05-27-adobe-creative-cloud-licensing-and-deployment.md" >}}) for more brain-meltingly boring background information on this.

```xml
<plist version="1.0">
<dict>
    <key>catalogs</key>
    <array>
        <string>production</string>
    </array>
    <key>managed_installs</key>
    <array>
        <string>AdobePhotoshopCC2014</string>
        <string>AdobePremiereProCC2014</string>
        <string>AdobeSpeedGradeCC2014</string>
        <string>AdobeCC_License_Complete</string>
    </array>
</dict>
</plist>
```

Were we to leave out the `AdobeCC_License_Complete` item above, these applications would successfully install but a user would need to first sign in to use the software. In this way we can think of the installs as "unlicensed by default" and then we add a device/serial license on top if it's appropriate. Alternatively users could install the device licenses themselves as optional software, if that would make sense in your environment. In this example above, the Munki admin or help desk would be manually adding the license for a given manifest. If one later wanted to remove and deactivate the license, one would just move the item to a `managed_uninstalls` array in the same manifest.

Here's an abbreviated pkginfo for `AdobeCC_License_Complete`, just to show some important bits.

```xml
<plist version="1.0">
<dict>
    [...]
    <key>catalogs</key>
    <array>
        <string>production</string>
    </array>
    [...]
    <key>name</key>
    <string>AdobeCC_License_Complete</string>
    <key>version</key>
    <string>2015.05.19</string>
</dict>
</plist>
```

The manifest we saw above looks at a single catalog: `production`, and the license pkginfo belongs to only this catalog. This is a simple example.

For a slightly more sophisticated example, this license package could instead be set as an update for any products we have that would be "licensable" using that license, and be limited to a specific catalog. Our manifest, slightly modified, looks like:

```xml
<plist version="1.0">
<dict>
    <key>catalogs</key>
    <array>
        <string>adobe-cc-license-pool-complete</string>
        <string>production</string>
    </array>
    <key>managed_installs</key>
    <array>
        <string>AdobePhotoshopCC2014</string>
        <string>AdobePremiereProCC2014</string>
        <string>AdobeSpeedGradeCC2014</string>
    </array>
</dict>
</plist>
```

Notice we've taken the license as a separate installer "item" out of the manifest's installs list, and instead just made this manifest look at another catalog named after this pool. Our pkginfo for this license installer is part of this same special catalog, and is an `update_for` all items we have in our system that are part of the "Complete" pool:

```xml
<plist version="1.0">
<dict>
    [...]
    <key>catalogs</key>
    <array>
        <string>adobe-cc-license-pool-complete</string>
    </array>
    [...]
    <key>name</key>
    <string>AdobeCC_License_Complete</string>
    <key>update_for</key>
    <array>
        <string>AdobeAuditionCC2014</string>
        <string>AdobeIllustratorCC2014</string>
        <string>AdobePhotoshopCC2014</string>
        <string>AdobePremiereProCC2014</string>
        <string>AdobeSpeedGradeCC2014</string>
    </array>
    <key>version</key>
    <string>2015.05.19</string>
</dict>
</plist>
```

Note how we have other items in our `update_for` list like Audition CC, which could be referenced in other manifests. In this specific example I'm only deploying up to five different apps, but since this device license package belongs to a "Complete" pool, any Adobe app I package later could then be added as an `update_for` this Complete device license package.

The elegance of the second approach is that Munki can actually handle automatic activation and deactivation _for us_. If I would decide later to move SpeedGrade to the manifests's `managed_uninstalls` list, Munki would check if in addition it can _also_ remove the `AdobeCC_License_Complete` item, but determine that it cannot because other items in our `managed_installs` list are still installed. If we were to remove _all_ the applications for which this license is an update, Munki would then go and remove the license, deactivating the machine and freeing up a license.

You might think, That's fine for this example with a Complete pool, but what if we also purchase a pool that's just Photoshop? You don't want to consume a Complete pool license if someone only has Photoshop - but this is why each license installer would be limited to a special-purpose Munki catalog. If we had a "Video apps" pool, for example, we'd just add another catalog named `adobe-cc-license-pool-video` and make it an update for all the apps we have that could be in that pool.

I've rarely used catalogs as a mechanism to separate out licenses for individual business units, but it seems like this could be a use case where it might provide a useful layer of abstraction. On the other hand, managing the license as a separate line item also makes it easier to "convert" a machine back to a Named license model, if manifests are per-machine and the machine changes users, or as budget dictates the allocation of ongoing subscription licenses. In the second example above (using catalogs), if we later remove the special license catalog from a manifest's `catalogs` array, this does not mean that Munki will then automatically remove the license pkg from the client. It's only by actually placing a license in a `managed_uninstalls` array that Munki actively goes out to ensure the item is removed. So, there are pros and cons to both approaches.

### License and application usage tracking

So, those are a couple examples of how you one might approach managing these licenses in your Munki repo and among your clients. Another approach that might be worth considering is to have a more intelligent license-tracking mechanism help manage this for you. Luckily, Munki even [has one built in](https://github.com/munki/munki/wiki/License-Seat-Tracking)! At this time of writing, MunkiWebAdmin is the only public Munki web-based reporting application that has support for tracking the licenses, but the client uses a simple enough mechanism to determine based on data it receives from a server whether or not it will offer a given item to a user.

Recently Greg Batye gave a talk at the monthly [Macbrained meetup](http://macbrained.org/), covering how Facebook uses Munki. One interesting thing he covered was how they use a combination of [Crankd](https://github.com/google/macops/tree/master/crankd) and Munki conditional items to keep a list of applications that haven't recently been used, and remove these automatically. This allows them to offer expensive software to a much wider user audience because in many cases the software will be automatically uninstalled after it's not in use for some length of time. See a [video recording](http://www.ustream.tv/recorded/62281076) of the talk starting around 34:10 minutes in, and the [recap](http://macbrained.org/recap-may-quantcast) with a link to slides.

### Next

We're still not done! We haven't detailed anything about the actual _installation process_, we've only covered licensing in three dense posts. If you're not bored yet, stay tuned for some odds and ends about importing these applications and updates using Munki and [aamporter](https://github.com/timsutton/aamporter).
