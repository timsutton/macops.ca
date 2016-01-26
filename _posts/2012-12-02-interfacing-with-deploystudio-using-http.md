---

comments: true
date: 2012-12-02 23:51:22+00:00
layout: post
slug: interfacing-with-deploystudio-using-http
title: Interfacing with DeployStudio using HTTP
wordpress_id: 159
tags:
- APIs
- curl
- DeployStudio
- PlistBuddy
- Python
- vendor metadata
---

<!-- [![DSAdmin-256](images/2012/12/DSAdmin-256.png)](http://macops.ca/interfacing-with-deploystudio-using-http/dsadmin-256/) -->

[DeployStudio](http://deploystudio.com) is frequently a starting place for deploying and configuring Mac systems. It has a computer database that can store information like computer/host names, default workflows, management settings and custom properties that can be leveraged by workflow scripts and inventory systems.

It's well-known that all this database information is stored in plain XML plist files in the DeployStudio repository, one per computer, named after the value of the computer's primary key (serial number or MAC address). Sometimes people have wanted to manage this data from an external source like a web form or script that can be used by technicians deploying new hardware, but run up against the fact that changes to these files can only be loaded by restarting the DeployStudioServer service. That's by design. These plists are DeployStudio's database, and we don't directly interact with an applications's database if we can ever help it; that's what APIs are for, and DeployStudio has a basic [REST](http://en.wikipedia.org/wiki/Representational_state_transfer)-style API which it uses to perform all its communications between the server, admin client and runtime instances. This post will show some basic examples of how simple it is to interact with DeployStudio via command-line tools, and a Python example for setting arbitrary properties in the computer database.

<!-- more -->
Navigate to http[s]://your.deploystudio.server:port in your browser and fill in your credentials for a user with rights to DeployStudio Admin. You'll see a list of methods, the left-hand column using GET for retrieving values, the right-hand column using POST for setting values.

<table border="0" >
  <tr >
<td >GET methods:
</td>
<td >POST methods:
</td></tr>
  <tr >
<td >/computers/get/all
</td>
<td >/computers/del/entries
</td></tr>
  <tr >
<td >/computers/get/entry
</td>
<td >/computers/del/entry
</td></tr>
  <tr >
<td >/computers/groups/get/all
</td>
<td >/computers/groups/del/default
</td></tr>
  <tr >
<td >...
</td>
<td >...
</td></tr>
</table>

If you use a web debug tool like [Charles](http://www.charlesproxy.com) to inspect your traffic going out to your DeployStudio server, you can pretty quickly get a sense of what's going on. For example, when DeployStudio Admin connects to your repo, one of its requests is to `/computers/get/all`, which will retrieve all computer database information that the Admin app will use to populate its various text fields and table view. This information comes in the same form it's stored, as XML plists, and your Admin client is sending changes back out in that format as well. Only difference is that instead of editing plist files on disk, DeployStudio Admin is making an HTTP request and sending the XML plist data using the POST method. There are some subtleties to account for in the contents of these plists, but it's fairly straightforward.

We can use `curl` to take a look at the structure of what's received. DeployStudio uses HTTP Basic Auth everywhere, so you can have curl encode the appropriate header with the `-u username:password` option, or leave out the `:password` component and it will prompt you. We're also using the `-k` option because in these examples we're connecting using SSL and want to bypass the warning that DeployStudio is using a self-signed certificate. We can fetch all available computer info using the `/computers/get/all` endpoint and save it to a file at `out.plist`:

`curl -u testdsuser -k https://my.ds.repo:60443/computers/get/all > out.plist`

Opening it up, this is how it looks:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>computers</key>
    <dict>
        <key>DOUGLASFIRS</key>
        <dict>
            <key>cn</key>
            <string>diane</string>
            <key>dstudio-auto-disable</key>
            <string>NO</string>
            <key>dstudio-auto-reset-workflow</key>
            <string>NO</string>
            <key>dstudio-custom-properties</key>
            <array>
                <dict>
                    <key>dstudio-custom-property-key</key>
                    <string>ASSET_TAG</string>
                    <key>dstudio-custom-property-label</key>
                    <string>My Great Asset Tag</string>
                    <key>dstudio-custom-property-value</key>
                    <string>BL4CKL0DG3</string>
                </dict>
            </array>
            <key>dstudio-disabled</key>
            <string>NO</string>
            <key>dstudio-host-ard-ignore-empty-fields</key>
            <string>NO</string>
            <key>dstudio-host-delete-other-locations</key>
            <string>NO</string>
            <key>dstudio-host-interfaces</key>
            <dict>
                <key>en0</key>
                <dict>
                    <key>dstudio-dns-ips</key>
                    <string></string>
                    <key>dstudio-host-airport</key>
                    <string>NO</string>
                    <key>dstudio-host-airport-name</key>
                    <string></string>
                    <key>dstudio-host-airport-password</key>
                    <string></string>
                    <key>dstudio-host-auto-config-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-auto-config-proxy-url</key>
                    <string></string>
                    <key>dstudio-host-auto-discovery-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-ftp-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-ftp-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-ftp-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-http-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-http-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-http-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-https-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-https-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-https-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-interfaces</key>
                    <string>en0</string>
                    <key>dstudio-host-ip</key>
                    <string></string>
                    <key>dstudio-router-ip</key>
                    <string></string>
                    <key>dstudio-search-domains</key>
                    <string></string>
                    <key>dstudio-subnet-mask</key>
                    <string></string>
                </dict>
            </dict>
            <key>dstudio-host-new-network-location</key>
            <string>NO</string>
            <key>dstudio-host-primary-key</key>
            <string>dstudio-host-serial-number</string>
            <key>dstudio-host-serial-number</key>
            <string>DOUGLASFIRS</string>
            <key>dstudio-hostname</key>
            <string>diane</string>
        </dict>
        <key>HOWSANNIE</key>
        <dict>
            <key>cn</key>
            <string>my-great-mac</string>
            <key>dstudio-auto-disable</key>
            <string>NO</string>
            <key>dstudio-auto-reset-workflow</key>
            <string>NO</string>
            <key>dstudio-disabled</key>
            <string>NO</string>
            <key>dstudio-host-ard-ignore-empty-fields</key>
            <string>NO</string>
            <key>dstudio-host-delete-other-locations</key>
            <string>NO</string>
            <key>dstudio-host-interfaces</key>
            <dict>
                <key>en0</key>
                <dict>
                    <key>dstudio-dns-ips</key>
                    <string></string>
                    <key>dstudio-host-airport</key>
                    <string>NO</string>
                    <key>dstudio-host-airport-name</key>
                    <string></string>
                    <key>dstudio-host-airport-password</key>
                    <string></string>
                    <key>dstudio-host-auto-config-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-auto-config-proxy-url</key>
                    <string></string>
                    <key>dstudio-host-auto-discovery-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-ftp-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-ftp-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-ftp-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-http-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-http-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-http-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-https-proxy</key>
                    <string>NO</string>
                    <key>dstudio-host-https-proxy-port</key>
                    <string></string>
                    <key>dstudio-host-https-proxy-server</key>
                    <string></string>
                    <key>dstudio-host-interfaces</key>
                    <string>en0</string>
                    <key>dstudio-host-ip</key>
                    <string></string>
                    <key>dstudio-router-ip</key>
                    <string></string>
                    <key>dstudio-search-domains</key>
                    <string></string>
                    <key>dstudio-subnet-mask</key>
                    <string></string>
                </dict>
            </dict>
            <key>dstudio-host-new-network-location</key>
            <string>NO</string>
            <key>dstudio-host-primary-key</key>
            <string>dstudio-host-serial-number</string>
            <key>dstudio-host-serial-number</key>
            <string>HOWSANNIE</string>
            <key>dstudio-hostname</key>
            <string>my-great-mac</string>
        </dict>
    </dict>
    <key>groups</key>
    <dict/>
</dict>
</plist>
```
In the XML returned, the `computers` dictionary contains dictionaries each named by the computer ID, either a serial number or a MAC address. Here we have `DOUGLASFIRS` and `HOWSANNIE`. In this example we'll look mainly at the serial number, computer name and hostname (`dstudio-host-serial-number`, `cn` and `dstudio-hostname`keys, respectively), but there's lots of other empty fields, particularly all the networking-related information.

Say we want to just rename the `DOUGLASFIRS` computer, by changing its computer name and local host name to 'diane'. (While I don't typically use hostnames for anything, the hostname has the privilege of being one of the few columns available in DeployStudio Admin for identifying a computer in the list.) We'll use PlistBuddy to change the `cn` and `dstudio-hostname` keys in the plist we just output:

```bash
/usr/libexec/PlistBuddy -c "Set :computers:DOUGLASFIRS:cn diane" out.plist
/usr/libexec/PlistBuddy -c "Set :computers:DOUGLASFIRS:dstudio-hostname diane" out.plist
```

There's one more detail to take care of. We're going to send this updated computer record plist to the server using POST to the `/computers/set/entry` endpoint, but this endpoint expects to be passed only the contents of a single computer dict, using an `id` parameter to identify the record we're modifying. So in order to simplify our XML slightly and only send the contents of the `DOUGLASFIRS` dict, we'll again use PlistBuddy – this time using the `-x` parameter to output in plist format – to retrieve just the nested `DOUGLASFIRS` dict, and write this out to a new file at `douglasfirs-renamed.plist`:

```
/usr/libexec/PlistBuddy -x -c "Print :computers:DOUGLASFIRS" out.plist > douglasfirs-renamed.plist
```

We could just have easily done all this with a text editor, but I'm using PlistBuddy because it's one way these kinds of changes could be made automatically via a script rather than manually. Now our updated computer info in `douglasfirs-renamed` looks like this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>cn</key>
    <string>diane</string>
    <key>dstudio-auto-disable</key>
    <string>NO</string>
    <key>dstudio-auto-reset-workflow</key>
    <string>NO</string>
    <key>dstudio-custom-properties</key>
    <array>
        <dict>
            <key>dstudio-custom-property-key</key>
            <string>ASSET_TAG</string>
            <key>dstudio-custom-property-label</key>
            <string>My Great Asset Tag</string>
            <key>dstudio-custom-property-value</key>
            <string>BL4CKL0DG3</string>
        </dict>
    </array>
    <key>dstudio-disabled</key>
    <string>NO</string>
    <key>dstudio-host-ard-ignore-empty-fields</key>
    <string>NO</string>
    <key>dstudio-host-delete-other-locations</key>
    <string>NO</string>
    <key>dstudio-host-interfaces</key>
    <dict>
        <key>en0</key>
        <dict>
            <key>dstudio-dns-ips</key>
            <string></string>
            <key>dstudio-host-airport</key>
            <string>NO</string>
            <key>dstudio-host-airport-name</key>
            <string></string>
            <key>dstudio-host-airport-password</key>
            <string></string>
            <key>dstudio-host-auto-config-proxy</key>
            <string>NO</string>
            <key>dstudio-host-auto-config-proxy-url</key>
            <string></string>
            <key>dstudio-host-auto-discovery-proxy</key>
            <string>NO</string>
            <key>dstudio-host-ftp-proxy</key>
            <string>NO</string>
            <key>dstudio-host-ftp-proxy-port</key>
            <string></string>
            <key>dstudio-host-ftp-proxy-server</key>
            <string></string>
            <key>dstudio-host-http-proxy</key>
            <string>NO</string>
            <key>dstudio-host-http-proxy-port</key>
            <string></string>
            <key>dstudio-host-http-proxy-server</key>
            <string></string>
            <key>dstudio-host-https-proxy</key>
            <string>NO</string>
            <key>dstudio-host-https-proxy-port</key>
            <string></string>
            <key>dstudio-host-https-proxy-server</key>
            <string></string>
            <key>dstudio-host-interfaces</key>
            <string>en0</string>
            <key>dstudio-host-ip</key>
            <string></string>
            <key>dstudio-router-ip</key>
            <string></string>
            <key>dstudio-search-domains</key>
            <string></string>
            <key>dstudio-subnet-mask</key>
            <string></string>
        </dict>
    </dict>
    <key>dstudio-host-new-network-location</key>
    <string>NO</string>
    <key>dstudio-host-primary-key</key>
    <string>dstudio-host-serial-number</string>
    <key>dstudio-host-serial-number</key>
    <string>DOUGLASFIRS</string>
    <key>dstudio-hostname</key>
    <string>diane</string>
</dict>
</plist>
```

We're ready to commit these changes back to DeployStudio, so we'll again use curl to POST the data using the `--data` option and prepend the file with an `@` symbol to specify we want to feed it the contents of the file:

`curl -k -u testdsuser --data @douglasfirs-renamed.plist "https://my.ds.repo:60443/computers/set/entry?id=DOUGLASFIRS"`

The same endpoint is used if we want to create a new record - we would just format a new computer plist containing the fields we care about and submit it using the appropriate ID. A new record need not contain all these blank placeholder keys; a new computer record created in DeployStudio Admin will only contain `dstudio-host-primary-key` and one of `dstudio-host-serial-number` or `dstudio-mac-addr`. It's important to know that these other keys can exist (and definitely _will_ if the record has ever been modified in Admin), because a plist sent to this endpoint will completely overwrite the existing plist. Therefore, if one is modifying an existing record and wants to preserve any other values that may be contained in the record, one should always fetch the existing record and make changes. This is why we used PlistBuddy above to copy the individual computer dict from the existing data out to a new plist.

One other thing to note if you're testing this and not seeing the changes in DeployStudio Admin: in order to get the changes to the computer database, DeployStudio Admin needs to do another GET to `/computers/get/all`, which can  be triggered by switching to a different section in the left-hand sidebar. DeployStudio Admin is not refreshing all the computer information periodically, likely because it expects to be the only application editing it and it's already keeping track internally of local edits.

I used curl and PlistBuddy because they're capable tools that any seasoned Mac admin is familiar with. There's certainly nothing wrong with using them in this context, although a higher-level scripting language like Python is particularly well-suited to this task for a couple reasons. It has a built-in module to handle XML plist data as native Python dictionaries, meaning no dealing with PlistBuddy or defaults and their esoteric syntaxes is required. It ships with a great standard library of modules that can perform all this functionality without requiring a shell or external (platform-specific) binaries. This also means any code written in Python using these built-in modules can be ported to a web application running on Linux or Windows with few or no changes.

Here's a short Python example of a couple simple operations using the same endpoints we used above, as well as manipulating a custom property representing an organization's asset tag. The `updateHostProperties()` function allows us to specify a computer ID and a dictionary of properties we'd like to change. It transparently handles creating a new record if one doesn't already exist. There's a lot of room to improve its robustness as it performs no real error handling, but this is omitted to keep the example shorter. The two example operations it performs can be found commented in the `main()` function at the end, and with each invocation it will simply generate a new computer/hostname of the form 'random-id-n'.


```python
#!/usr/bin/python

import urllib2
import plistlib
from random import randrange

host = 'https://my.ds.repo:60443'
adminuser = 'testdsuser'
adminpass = '12345'


def setupAuth():
    """Install an HTTP Basic Authorization header globally so it's used for
every request."""
    auth_handler = urllib2.HTTPBasicAuthHandler()
    auth_handler.add_password(realm='DeployStudioServer',
                              uri=host,
                              user=adminuser,
                              passwd=adminpass)
    opener = urllib2.build_opener(auth_handler)
    urllib2.install_opener(opener)


def getHostData(machine_id):
    """Return the full plist for a computer entry"""
    machine_data = urllib2.urlopen(host + '/computers/get/entry?id=%s' % machine_id)
    plist = plistlib.readPlistFromString(machine_data.read())
    # if id isn't found, result will be an empty plist
    return plist


def updateHostProperties(machine_id, properties, key_mac_addr=False, create_new=False):
    """Update the computer at machine_id with properties, a dict of properties and
values we want to set with new values. Return the full addinfourl object or None
if we found no computer to update and we aren't creating a new one. Set create_new
to True in order to enable creating new entries."""
    found_comp = getHostData(machine_id)

    # If we found no computer and we don't want a new record created
    if not found_comp and not create_new:
        return None

    new_data = {}
    if found_comp:
        # Computer data comes back as plist nested like: {'SERIALNO': {'cn': 'my-name'}}
        # DeployStudioServer expects a /set/entry POST like: {'cn': 'my-new-name'}
        # so we copy the keys up a level
        update = dict((k, v) for (k, v) in found_comp[machine_id].items())
        new_data = update.copy()
    else:
        # No computer exists for this ID, we need to set up two required keys:
        # 'dstudio-host-primary-key' and one of 'dstudio-host-serial-number'
        # or 'dstudio-mac-addr' is required, otherwise request is ignored
        # - IOW: you can't only rely on status codes
        # - primary key is a server-level config, but we seem to need this per-host
        if key_mac_addr:
            new_data['dstudio-host-primary-key'] = 'dstudio-mac-addr'
        else:
            new_data['dstudio-host-primary-key'] = 'dstudio-host-serial-number'
        new_data[new_data['dstudio-host-primary-key']] = machine_id
    
    for (k, v) in properties.items():
        new_data[k] = v
    plist_to_post = plistlib.writePlistToString(new_data)
    result = urllib2.urlopen(host + '/computers/set/entry?id=' + machine_id,
                            plist_to_post)
    return result


def main():
    setupAuth()

    # Update HOWSANNIE with a new computer name (assuming this entry already exists)
    random_name = 'random-id-' + str(randrange(100))
    result = updateHostProperties('HOWSANNIE', {'cn': random_name,
                                            'dstudio-hostname': random_name})

    # Update DOUGLASFIRS with a new computername and custom properties, or create
    # it if it doesn't already exist
    random_name = 'random-id-' + str(randrange(100))
    updateHostProperties('DOUGLASFIRS',
                    {'cn': random_name,
                    'dstudio-hostname': random_name,
                    'dstudio-custom-properties': [{
                        'dstudio-custom-property-key': 'ASSET_TAG',
                        'dstudio-custom-property-label': 'My Great Asset Tag',
                        'dstudio-custom-property-value': 'BL4CKL0DG3'}]
                    },
                    create_new=True)

if __name__ == "__main__":
    main()
```
