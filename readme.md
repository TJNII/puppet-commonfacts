commonfacts
===========

This module provides facter facts for use by other modules.

ipclassifier fact
-----------------

This module provides facts that classify the IPs in a server:
* ipaddress_internal: Internal server IP
* ipaddress_public: Publically routable IP
* interfaces_internal: Interfaces with an internal IP
* interfaces_public: Interfaces with a public IP

Subnet classification is currently coded into the facter module.
At this time the 10.128.0.0 subnet is not classified to exclude Rackspace servicenet.

So for an example of a Rackspace cloud server with a internal Cloud networks connection where
* eth0 is public, 192.250.1.2
* eth1 is Rackspace servicenet, 10.208.3.4
* eth2 is a cloud network, 10.1.2.3

Then:

* ipaddress_internal: 10.1.2.3
* ipaddress_public: 192.250.1.2
* interfaces_internal: eth2
* interfaces_public: eth0

Mounts fact
-----------

This fact reads the fstab and provides facts containing filesystems that should be mounted
on the system.  
(Excluding pseudo and non-filesystems which are in the fstab like devpts, proc, and swap.)

This module provides a mountpoints fact that contains a list of all the filesystems found.
For each filesystem found, a mounttype_${path} fact is created with the filesystem type.

### WARNING
As Ruby requires the fact names to be lowercase, the mounttype facts uses the downcase'd path.
As such there may be colissions if you have mounts like /mnt/foobar and /mnt/FooBar.
Currently only the first mount will be reported, and the failure WILL BE SILENT!
The author currently considers this risk acceptable as it is only an issue with confusingly
named mounts.