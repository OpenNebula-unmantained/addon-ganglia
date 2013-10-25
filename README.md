# Ganglia Monitoring Drivers

## Description

These monitoring drivers use the Ganglia monitoring infrastructure to gather information about the physical nodes and the VMs.

If you already have ganglia deployed in your cluster you can use the ganglia drivers provided by OpenNebula to get information about hosts and virtual machines from it. These drivers should make the monitoring more performant in a big installation as they don't use ssh connections to the nodes to get the information. On the other side they require more work on the system administrator as ganglia should be properly configured and cron jobs must be installed on the nodes to provide virtual machine information to ganglia system.


## Development

To contribute bug patches or new features, you can use the github Pull Request model. It is assumed that code and documentation are contributed under the Apache License 2.0. 

More info:
* [How to Contribute](http://opennebula.org/software:add-ons#how_to_contribute_to_an_existing_add-on)
* Support: [OpenNebula user mailing list](http://opennebula.org/community:mailinglists)
* Development: [OpenNebula developers mailing list](http://opennebula.org/community:mailinglists)
* Issues Tracking: Github issues

## Authors

* Leader: Javier Fontán (jfontan@opennebula.org)


## Compatibility

This add-on is compatible with OpenNebula 4.2.

## Features

ssh-less monitoring of hosts and VMs

## Limitations

The maximun size of ganglia values is 1400 bytes by default. This limits the total amount of VMs monitored per host.

## Requirements

Ganglia installation running and accessible from the OpenNebula Frontend. Tested with ganglia version 3.1.7.

## Installation

As root user execute `install.sh`. This will copy all the needed files to OpenNebula installation directories.

In case you have a self-contained installation export `ONE_LOCATION` to the correct path and execute `install.sh` as the owner of the OpenNebula installation directory.

After installation execute this command so the new remote files are copied to the hosts:

~~~~
$ onehost sync
~~~~

### Ganglia Probe Installation

Virtual Machine information is not gathered by ganglia so we provide a script to get that information. The same probe that gets information for xen and kvm (`/var/lib/one/remotes/vmm/xen/poll` or `/var/lib/one/remotes/vmm/kvm/poll`) will be used to get this data and push it to ganglia. You have to copy this probe to each of the nodes or put it in a path visible by all the nodes. It will be executed by oneadmin user to take that into account when you decide where to put the file. We will assume that the probe resides in the home of oneadmin user (`~`).

This information needs to be pushed to a metric called `OPENNEBULA_VMS_INFORMATION` and we will be using gmetric command to push this information to ganglia:

~~~~
$ gmetric -n OPENNEBULA_VMS_INFORMATION -t string -v `$HOME/tmp/poll --kvm`
~~~~

To make it refresh automatically you should add this command to cron subsystem. Every minute is nice but is up to you the frequency of its refresh.

## Configuration

### OpenNebula Configuration

To enable ganglia monitoring these lines must be uncommented in `oned.conf`:

~~~~
IM_MAD = [
      name       = "ganglia",
      executable = "one_im_sh",
      arguments  = "ganglia" ]
~~~~

You also need to add the hosts with im_ganglia as its im driver.

To enable ganglia in VMM drivers you mush add a parameter to the driver execution that will tell the driver to use a local script to gather the information. The parameter is `-l poll=poll_ganglia`. For example for kvm you should change in oned.conf this:

~~~~
VM_MAD = [
    name       = "kvm",
    executable = "one_vmm_exec",
    arguments  = "-t 15 -r 0 kvm",
    default    = "vmm_exec/vmm_exec_kvm.conf",
    type       = "kvm" ]
~~~~
        
Into this:

~~~~
VM_MAD = [
    name       = "kvm",
    executable = "one_vmm_exec",
    arguments  = "-t 15 -r 0 kvm -l poll=poll_ganglia",
    default    = "vmm_exec/vmm_exec_kvm.conf",
    type       = "kvm" ]
~~~~

### Probes Configuration

Both im_ganglia and vmm's poll_local have at the start some values that can be changed:

~~~~
# host and port where to get monitoring information
GANGLIA_HOST='localhost'
GANGLIA_PORT=8649

# If this variable is set the the information will be read from that file
# otherwise it will get information from the ganglia endpoint
# defined previously
#GANGLIA_FILE='data.xml'
~~~~
    
`GANGLIA_HOST` and `GANGLIA_PORT` should point to a suitable gmond that holds the information about all the hosts or to a central gmetad. If `GANGLIA_FILE` is defined instead of talking to gmond/gmetad directly the data will be read from there. This is useful for debugging or if you cannot access gmond/gmetad directly from the fronted.

> Take also into account that the names of the hosts in ganglia and the names of the hosts in ONE should match. You can also use IP addresses instead of hosts.

## Usage

### XEN Information

XEN host information can be pushed to ganglia using both the standard XEN probe and a helper script located in `share/scripts/push_ganglia`. Both scripts should be copied to each of the xen hosts and added to cron. The scripts needed:

* `/usr/share/one/scripts/ganglia/push_ganglia`
* `/var/lib/one/remotes/im/xen.d/xen.rb`

Place both scripts in the same directory and use them this way to push the info to ganglia:

~~~~
$ ./xen.rb | ./push_ganglia
~~~~

To automate the information refresh add those commands into `oneadmin` user cron.


### Virtual Machine Manager drivers

This script should be executed adding a parameter that tells what hypervisor it needs to query. `--xen` for xen hypervisor or `--kvm` for kvm hypervisor. Executing it this way we will get something like this:

~~~~
$ ./poll --kvm
.: 1: Can't open ./kvmrc
LS0tIApvbmUtMDogCiAgOnN0YXRlOiBhCiAgOm5ldHR4OiAiOTQ
wMjQiCiAgOnVzZWRjcHU6ICIwLjIiCiAgOm5hbWU6IG9uZS0wCi
AgOnVzZWRtZW1vcnk6IDI2MjE0NAogIDpuZXRyeDogIjQ3MDM5M
CIKb25lLTE6IAogIDpzdGF0ZTogYQogIDpuZXR0eDogIjkzNjMy
IgogIDp1c2VkY3B1OiAiMC4yIgogIDpuYW1lOiBvbmUtMQogIDp
1c2VkbWVtb3J5OiAyNjIxNDQKICA6bmV0cng6ICI0NjgwODQiCm
9uZS0yOiAKICA6c3RhdGU6IGEKICA6bmV0dHg6ICI5MjY4MCIKI
CA6dXNlZGNwdTogIjAuMiIKICA6bmFtZTogb25lLTIKICA6dXNl
ZG1lbW9yeTogMjYyMTQ0CiAgOm5ldHJ4OiAiNDY0MTg2Igo=
~~~~
    
You can safely disregard the message `.: 1: Can't open ./kvmrc` as it is written to `STDERR`. It tries to read `kvmrc` (or `xenrc`) from the same path the script resides to get configuration information on how to query the hypervisor but uses default configuration otherwise. You can put `kvmrc` or `xenrc` in the same directory as poll script to get rid of that message and change the way you want to query the hypervisor. These rc files are the ones located at the vmm remotes directory.

The big string written is the information about the VMs running in that host encoded in base64. In this example decoding it says:

~~~~~
--- 
one-0: 
  :state: a
  :nettx: "94024"
  :usedcpu: "0.2"
  :name: one-0
  :usedmemory: 263.04
  :netrx: "470390"
one-1: 
  :state: a
  :nettx: "93632"
  :usedcpu: "0.2"
  :name: one-1
  :usedmemory: 263.04
  :netrx: "468084"
one-2: 
  :state: a
  :nettx: "92680"
  :usedcpu: "0.2"
  :name: one-2
  :usedmemory: 263.04
  :netrx: "464186"
~~~~

It is encoded as this string will be a value pushed to ganglia so it does not interfere with xml. The format is yaml and can be easily parsed with the multiple libraries available for various languages if you need to do so.

The command that pushes this information to ganglia is:

~~~~
$ gmetric -n OPENNEBULA_VMS_INFORMATION -t string -v `$HOME/tmp/poll --kvm`
~~~~
    
You can check if this information is in ganglia after executing that to be sure that there is no problem. 


## References

* [Ganglia](http://ganglia.sourceforge.net/)

## License

Apache v2.0 license.
