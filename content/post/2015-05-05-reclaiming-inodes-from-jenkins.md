---
comments: true
date: 2015-05-05T18:19:58Z
slug: reclaiming-inodes-from-jenkins
tags:
- Jenkins
- Linux
title: Reclaiming inodes from Jenkins

wordpress_id: 950
---

<!-- [![Jenkins.sh-600x600](images/2015/05/Jenkins.sh-600x600-232x300.png)](images/2015/05/Jenkins.sh-600x600.png)
 -->
A pet project I maintain is [ci.autopkg.org](http://ci.autopkg.org), a Jenkins instance that runs all [AutoPkg](https://github.com/autopkg/autopkg) recipes in the [autopkg/recipes](https://github.com/autopkg/recipes) repo on a schedule, and reports any cases where recipes are failing. There are currently 126 jobs, for the 126 recipes in the repo.

These AutoPkg recipes must be run on OS X, so there is always at least one OS X slave connected to by the master, which runs Ubuntu on the [cheapest](https://www.digitalocean.com/pricing/) Digital Ocean droplet available. Every time a job runs on a slave (currently about every eight hours), Jenkins logs the results on the master in a set of files on disk, known as a "build." By default, when a new Jenkins job is created, it is configured for builds to be kept forever, even though they can be deleted manually. Builds may also include "artifacts" - binaries or other output from a job - but in my case a build is mostly just state and console output saved from the build run.

This service ran well enough for a year and a half before it suddenly reported having no free disk. And yet, `df` reported more than 50% of the 20GB volume being available. Using the `-i` option for `df`, however, revealed that while I had space available, I had zero file [inodes](http://en.wikipedia.org/wiki/Inode) left on the system:

```
$ df -i

Filesystem      Inodes   IUsed  IFree IUse% Mounted on
/dev/vda       1310720 1310720      0   65% /
```

Clearly I had way more files on disk than I had any use for, and this would be a good opportunity to prune them. In my case the builds are not useful for much except if one wants to see the history of success and failures of the recipes, and generally we only really care about whether the recipes work today, in their current state.

After a bit of digging in the job configuration, I found where one can restrict the number of builds that are kept - right near the top, "Discard Old Builds":

{{< imgcap
    caption="Discard Old Builds job configuration"
    img="/images/2015/05/jenkins-logrotate.png"
>}}

<!-- [caption id="attachment_954" align="aligncenter" width="540"][![Discard Old Builds job configuration](images/2015/05/jenkins-logrotate-1024x746.png)](images/2015/05/jenkins-logrotate.png) Discard Old Builds job configuration[/caption]
 -->
Since each recipe is its own job and they are numerous, I use the [Jenkins Job DSL plugin](https://wiki.jenkins-ci.org/display/JENKINS/Job+DSL+Plugin) to generate these jobs programmatically. It may seem odd that this plugin gets invoked as a build step of a job - in other words, you run a job that builds other jobs - but it is quite powerful and is very actively developed.

All I really needed to do to configure these jobs to retain only the last 30 days' worth of builds was [add one line](https://github.com/timsutton/autopkg-ci/blob/b0ecde619fb13b9d3c375911cde35bb82c731c9b/seed/seed_dsl.groovy#L12) to my Groovy script invoked by the plugin.

Now that these jobs were all reconfigured to keep builds for a maximum of 30 days, what would happen to all the existing old builds? As documented towards the bottom of [this issue](https://issues.jenkins-ci.org/browse/JENKINS-13039), the log rotation will come into effect the next time a build is run, so each job would prune its old builds as each subsequent build is run. Or, as the original reporter documented, it's possible to run a groovy statement in the console to prune all the jobs' old builds immediately, which I confirmed worked as well.

For more details on how this "AutoPkg CI" jenkins instance is created, check out its configuration [on GitHub](https://github.com/timsutton/autopkg-ci).
