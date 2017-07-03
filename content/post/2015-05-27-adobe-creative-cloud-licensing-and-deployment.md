---
comments: true
date: 2015-05-27T05:42:23Z
slug: adobe-creative-cloud-licensing-and-deployment
tags:
- Adobe
- creative-cloud
- Licensing
title: Adobe Creative Cloud Deployment - Overview

wordpress_id: 980
---

<!-- [![EnterpriseApp_256.png](images/2015/05/EnterpriseApp_256.png)](images/2015/05/EnterpriseApp_256.png) -->

Adobe's Creative Cloud licensing models add some new layers of complexity surrounding large-scale deployment in organizations.  As I've been planning and testing our rollout in areas with managed, shared workstations I'm routinely uncovering new information, and the parts of this I think might be useful to others I will cover in several posts. There are several aspects here: 1) simply wrapping one's head around the different licensing models, 2) understanding differences in the mechanisms with which these licenses can be deployed to machines, and 3) how to maintain all of all this using a software management system such as Munki or Casper. While I can only speak with experience with a subset of the licensing types and my management tool of choice (Munki), this may be useful if you have some of these in common, or you may also be able to port some specifics to another management system.

An additional preface to these posts: Having been looking into this for quite some time I still regularly feel like I'm stumbling in the dark, I cannot keep any of the license agreement acronyms in my head for more than several minutes and in general I usually feel like I'm doing this wrong. Lacking any better guidance, however, I'm documenting some of my findings. I expect to need to revise these strategies over time.

Thanks to [Patrick Fergus](https://foigus.wordpress.com/), who provided some additional details and clarifications about the different license types. Some of the points below are his words verbatim. Patrick has also written a [number](https://foigus.wordpress.com/2014/12/05/packaging-adobe-cc-2014-applications/) of [very](https://foigus.wordpress.com/2014/12/05/distributing-adobe-cc-2014-via-munki/) [detailed](https://foigus.wordpress.com/2014/12/15/distributing-dps-desktop-tools-for-indesign-cc-2014-with-munki/) [posts](https://foigus.wordpress.com/2015/05/07/packaging-adobe-rapid-release-updates-with-ccp-or-aamee/) on subjects I'm covering in these posts.

First, let's review some of the new subscription-based licensing models and how that affects the mechanisms used to deploy Creative Cloud.

There are two new axes along which we can categorize licenses:

  * A license agreement type of either Teams (including education-focused licenses) or Enterprise
  * A type of license, including "Named" and "Device" (for education) or "Serial Number" (for enterprise)

Named licenses require sign-in to use the software, and these sign-ins come in three [different flavors](https://helpx.adobe.com/enterprise/help/identity.html):

  * Adobe IDs, which are owned by the user and authenticated by Adobe
  * Enterprise IDs, which are owned by the organization and authenticated by Adobe
  * Federated IDs, which are owned by the organization and authenticated by the organization via SAML

Non-sign-in licenses include:

  * Device licenses are "activated" to a machine and consume a license from a "pool" for as long as that machine is activated. Different pools will exist for different product collections.
  * Serial Number Licenses "activated" to a machine and do not report back to Adobe when they are used

**Caveat:** Because my organization doesn't have an Enterprise agreement, I cannot speak with actual experience with that licensing model. The approaches I talk about with respect to the "Device License" should mostly apply to the "Serial Number" model used by Enterprise agreements, however.

Here's a screenshot borrowed from one of Adobe's [help pages](https://helpx.adobe.com/creative-cloud/packager/create-license-file.html) on the subject. Note how Education categories can be found in the Teams (top) and Enterprise (bottom) agreements:

{{< imgcap
    img="/images/2015/05/cc_select_product.png"
>}}

<!-- [![cc_select_product](images/2015/05/cc_select_product.png)](images/2015/05/cc_select_product.png) -->

Enterprise agreements have the benefit, besides apparently greatly reduced cost per license, of not needing to track individual device "activations" due to Adobe allowing "anonymous" serialized activation.

If you'll be deploying device/serial licenses, you need some way to automate the installation of the license. Adobe offers two approaches, built around their Creative Cloud Packager application

  1. Create a [device-licensed](https://helpx.adobe.com/creative-cloud/packager/device-based-licenses.html) package, which will contain one or more apps and also deploy the activation when the package is installed. This process also creates an uninstaller that will remove the apps and deactivate that license.
  2. Create a [license file](https://helpx.adobe.com/creative-cloud/packager/create-license-file.html), which allows us to "migrate previously deployed named user or trial packages to serial number licenses or device licenses": This outputs four files, which Adobe calls a "package." It is not - it is four files, created in a directory, with no accompanying explanation. Presumably we can use this to activate and deactivate a license? (Keep reading to find out!)

{{< imgcap
    img="/images/2015/05/cc_create_package.png"
>}}

The first seems like a sane option; the application(s) and license are included as a single package bundled together. Munki even supports importing these in a single step along with the accompanying uninstaller package, and has special logic tailored to support uninstalling these, while still using Adobe's provided uninstallers. This works well if you don't anticipating mixing Named and Device/Serial licenses, and are doing all licenses from the same pool, or a small, manageable number of them.

If however, your org will also be using Named licenses, or you expect to find yourself handling device licenses in various pools and want to just treat the device license or serial separate from the actual application installers and manage them independently, option **(2)** (creating a device license file independent of the application) seems to make more sense.

[Nick McSpadden](https://osxdominion.wordpress.com/) and [Patrick Fergus](https://foigus.wordpress.com/) also discovered a critical problem with **(1)**, if one creates multiple device license packages from the same pool, for example creating a separate Photoshop and After Effects package both from a "Complete" pool, or multiple serial number packages with the same serial number, removing _any one_ of these licensed application packages will uninstall the license as well.

This is not an issue that would affect everyone - despite moving away from the "Creative Suite [X] Premium" product model, the "pools" (or serial numbers) are still logical collections of applications, so it's possible that one might just build packages containing all the applications from a pool and not consider a need to add or remove individual applications from this pool on an ongoing basis.

It affects me, however: with many subscriptions to the Complete pool while still not needing half of the applications for many of our workstations, I'm instead opting to build individual application installers that I'd still like to be able to manage atomically without needing to worry that removing one product will cause another to cease functioning. An unlicensed Creative Cloud installation prompts a user with a completely hostile dialog prompt:

{{< imgcap
    img="/images/2015/05/ccp_signin.png"
>}}

Karl Gibson of the Adobe IT Toolkit team has acknowledged that this is a bug, and it's scheduled to be addressed in an upcoming update. Also, Nick McSpadden has documented [his solution](https://osxdominion.wordpress.com/2015/04/23/fixing-adobe-ccps-broken-uninstallers/) to this "overlapping" install/uninstall issue, which is to combine the licensed installer with the "Named" (ie. unlicensed) uninstaller, so that if a product is removed using the uninstall pkg, the machine remains licensed. For serial number installations this is perhaps more feasible because serial number installations are "anonymous," and an active installation doesn't consume a license from an (expensive) pool of licenses.

So, solution **(2)** it is for me, at least as of today. This is partly to mitigate this bug, and partly to offer a more flexible workflow as the deployment of Creative Cloud pans out. In my environment we'll most likely be seeing use of both Named and Device licenses, so it is also helpful to be not building and tracking duplicate packages for the same applications.

**Update (Jul 2, 2015):** Unfortunately, (2) doesn't currently work in my testing of deploying license files for use with the 2015 apps. The apps install, but I immediately see a "Sign In Required" prompt on launch. They seem to work fine when deployed as part of an all-in-one device/serialized installer. I'm awaiting confirmation from the Adobe team responsible for CCP about this issue. Nick McSpadden has written a [2015 version](https://osxdominion.wordpress.com/2015/06/18/adobe-cc-2015-another-circle-around-the-drain/) of the blog post above covering his use of the method linked to just above.

**Update (Jul 15, 2015):** A new minor release of CCP came out recently, and I used it to rebuild another licensing file. I noted that the `adobe_prtk` that comes with this one is a newer (9.x) version. A licensing file from this build seems to work for both 2014 and 2015 applications. Adobe was never able to reproduce the issue, but I can reliably reproduce that a license file built from a CCP two weeks after the 2015 apps were released doesn't work, while one built with the very latest build of CCP works. This doesn't further inspire confidence..

In posts which will soon follow, I’ll cover the steps involved to build an OS X installer package from CCP’s “Device File Package [sic]”, a couple simple approaches to managing this license package using Munki, and some odds and ends.
