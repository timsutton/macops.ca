---
date: 2015-05-28T14:45:36Z
slug: adobe-creative-cloud-deployment-packaging-a-license-file
tags:
- Adobe
- adobe_prtk
- creative-cloud
- packaging
title: Adobe Creative Cloud Deployment - Packaging a License File

wordpress_id: 1016
---

In the [previous post]({{< relref "post/2015-05-27-adobe-creative-cloud-licensing-and-deployment.md" >}}), we covered the scenarios in which you might want to deploy a Creative Cloud device license or serial number separate from the actual applications, as a "License File Package". Although the [Creative Cloud Packager app](https://helpx.adobe.com/creative-cloud/packager.html) supports this as a workflow, the problem is that it doesn't help you out much with regards to the files it outputs.

{{< imgcap
    img="/images/2015/05/ccp_create_license_file.png"
>}}

Adobe has had the APTEE tool around for a while, as a command-line interface to the Creative Suite licensing tools, to aid with deployment automation - it's a single executable which confusingly does not include "APTEE" anywhere in the name of the binary: `adobe_prtk`.

This tool is still around, and has been [updated for Creative Cloud](https://helpx.adobe.com/creative-cloud/packager/provisioning-toolkit-enterprise.html). It's also claimed to be installed as part of Creative Cloud Packager, which is true, but its location is not documented anywhere I could find, so I'll save you the trouble looking for it: `/Applications/Utilities/Adobe Application Manager/CCP/utilities/APTEE/adobe_prtk`.

According to the official documentation for the ["Create License File"](https://helpx.adobe.com/creative-cloud/packager/create-license-file.html) option in CCP, that outputs four files:

  * AdobeSerialization
  * RemoveVolumeSerial
  * helper.bin
  * prov.xml


..there's no `adobe_prtk` among those. But it turns out, if we take a look at the strings of `AdobeSerialization` - which the docs say we can run with "admin privileges" to license the software - some of the first strings found in the binary look an awful lot like [flags](https://helpx.adobe.com/creative-cloud/packager/provisioning-toolkit-enterprise.html) to `adobe_prtk`:

```
com.apple.PackageMaker
3.0.3
AdobeSerialization
AdobeSerialization.log
CreativeCloudPackager
Utilities
##################################################
Launching the AdobeSerialization in elevated mode ...
helper.bin
prov.xml
/Provisioning/EnigmaData
type
DBCS
--tool=GetPackagePools
--tool=VolumeSerialize
--stream
--provfile=
```

`AdobeSerialization` seems to be a purpose-built version of `adobe_prtk` with options baked in. This tool loads your authenticated data and license details stored in an opaque format from the `prov.xml` file to perform a transaction with Adobe's licensing servers and commit the results to the local machine's Adobe licensing database.

Along with `AdobeSerialization` there's the `RemoveVolumeSerial` tool. Unfortunately, as mentioned [previously]({{< relref "post/2015-05-27-adobe-creative-cloud-licensing-and-deployment.md" >}}) and in [Adobe's official CCP documentation](https://helpx.adobe.com/creative-cloud/packager/create-license-file.html) this tool is supported for "Enterprise and EEA customers only" - which means it can't be used to deactivate a machine that is using a Device license in a Teams-based agreement. In fact, it has an [LEID](https://helpx.adobe.com/creative-cloud/packager/creative-cloud-licensing-identifiers.html) baked in along with the adobe_prtk options: `V7{}CreativeCloudEnt-1.0-Mac-GM`. (For reference, the current LEID for the Creative Cloud Teams "Complete" product is `V6{}CreativeCloudTeam-1.0-Mac-GM`.)

We've got enough hints in these two binaries to figure out that we can pass flags to `adobe_prtk`. From my examination, these roughly boil down to using the `--tool=GetPackagePools` flag for a device (Teams) license (see references to "DBCS" [throughout the code](https://gist.github.com/timsutton/fa65268f2c813039f706#file-adobeserialization_dbcs_flags-m-L80-L90), `~/Library/Logs/oobelib.log` file and the `prov.xml` file), and `--tool=VolumeSerialize` for a serial number (Enterprise) license.

Using the `adobe_prtk` tool and knowing the LEID of the product we want to deactivate, we can also do what the `RemoveVolumeSerial` tool cannot do: deactivate a teams-based device. The tool options don't seem to be different depending on a device or serial license, the issue is simply that `RemoveVolumeSerial` has a hardcoded LEID, whereas we can know ours by looking up the list, or even better, retrieving this automatically from the `prov.xml` file.

Based on this examination, it looks like `adobe_prtk` can perform a superset of the functions these two special binaries output from CCP can do, using a single binary. So in order to build a "licensing package" that can be installed as a native OS X installer package (and deployed with Munki, Imagr, DeployStudio, Casper, etc.) we have our necessary ingredients: we need the `adobe_prtk` (or "APTEE") tool, the `prov.xml` file corresponding to our license, and we know the commands to install and remove the license. Still, we need to know which command flags go with which license type, and we need to set the correct LEID if we want to ever be able to deactivate the license. Why not instead use the binaries that are output by CCP? As I described above, the removal tool will not work for all license agreements. I'd rather not have to keep track of multiple different binaries if one can do all the work.

Since investigating all this I decided this would be useful to encapsulate into a script that removes the guesswork from this, and so it has been put on GitHub here: [make-adobe-cc-license-pkg](https://github.com/timsutton/make-adobe-cc-license-pkg).

It only requires a copy of `adobe_prtk`, which will be discovered automatically if you've already installed CCP on the system running the script, and your `prov.xml` file output from your "Create License File" workflow. Everything else should be figured out for you, and a package will be output given the package parameters you specify:

```bash
$ ./make-adobe-cc-license-pkg --name AdobeCC_Complete --reverse-domain ca.macops prov.xml

** Found DBCS (device) license type in prov.xml
** Found LEID 'V6{}CreativeCloudTeam-1.0-Mac-GM' in prov.xml
** Extracted version 8.0.0.160 from adobe_prtk Info.plist section
** Wrote uninstall script to /Users/tsutton/AdobeCC_Complete-2015.05.27.uninstall
pkgbuild: Inferring bundle components from contents of /var/folders/8t/5trmslfj2cnd5gxkbmkbn5fj38qb2l/T/tmprvCGEI
pkgbuild: Adding top-level postinstall script
pkgbuild: Wrote package to /Users/tsutton/AdobeCC_Complete-2015.05.27.pkg
** Built package at /Users/tsutton/AdobeCC_Complete-2015.05.27.pkg
** Done.
```

Since I use Munki, and this package can only really be properly "removed" using an uninstall script, this tool can also import the resultant package into Munki and set the appropriate `uninstall_script` key with an uninstall script that will be populated with the appropriate LEID. Either way the uninstall script will be saved to the package's output directory for your own use in other systems.

See the repo's [GitHub page](https://github.com/timsutton/make-adobe-cc-license-pkg) for more details and documentation about how the package is built.

One of the Mac sysadmin community's biggest peeves with Adobe's AAM installer framework is that when failures occur (and they happen a lot), useful error codes are rarely printed in the context in which one normally monitors package installations (for example `/var/log/install.log`). Adobe documents their error codes on their website, and so the install/uninstall scripts generated by this package actually _report this info to standard output/error_ so you can at least immediately get a short description of why any failures might have occurred. There will always be full debug output in the various AAM logs, but the locations of these files are rarely easily discoverable or well-named (for example, `~/Library/Logs/oobelib.log`).

This tool hasn't been widely tested (thanks to Patrick Fergus again for his help testing the functionality with an Enterprise license), and it will probably be getting some tweaks or fixes over time.

Moving on, if you were using Munki or some other software management system (and hopefully you are using one of these), how would you "scope" how these licenses get deployed to machines? We'll look at a short example using Munki in the next post.
