# Vagrant + Hadoop + HBase Cluster

Clone this project to create a 4 node [Apache Hadoop](http://hadoop.apache.org)-[Apache HBase](http://hbase.apache.org) VM cluster.


This is a modified and stripped down version of [vagrant-cascading-hadoop-cluster](https://github.com/Cascading/vagrant-cascading-hadoop-cluster)
Hadoop-2.8.5 and HBase-2.2.5 are installed using 'openjdk-8-jdk' on 'ubuntu/bionic64' Vagrant boxes.
The original README has been modified below to account only for what is installed.

## Deploying the cluster

First install either [Virtual Box](http://virtualbox.org) and [Vagrant](http://vagrantup.com/) for your platform.

Then simply clone this repository, change into the directory and bring the cluster up.

    $ vagrant up

This will set up 4 machines - `master`, `hadoop1`, `hadoop2` and `hadoop3`. Each of them will have two CPUs and 1GB of
RAM. If this is too much for your machine, adjust the `Vagrantfile`.

The machines will be provisioned using [Puppet](http://puppetlabs.com/). All of them will have hadoop
(apache-hadoop-2.8.5) installed, ssh will be configured and local name resolution also works.

Hadoop is installed in `/opt/hadoop-2.8.5` and all tools are in the `PATH`.

The `master` machine acts as the namenode and the yarn resource manager, the 3 others are data nodes and run node
managers.

### Networking

The cluster uses [zeroconf](http://en.wikipedia.org/wiki/Zero-configuration_networking) (a.k.a. bonjour) for name
resolution. This means that you never have to remember any IP nor will you have to fiddle with your `/etc/hosts` file.

Name resolution works from the host to all VMs and between all VMs as well.  If you are using linux, make sure you have
`avahi-daemon` installed and it is running. On a Mac everything should just work (TM) witouth doing anything.  Windows
users have to install [Bonjour for Windows](http://support.apple.com/kb/dl999) before starting the cluster.

The network used is `192.168.7.0/24`. If that causes any problems, change the `Vagrantfile` and
`modules/avahi/file/hosts` files to something that works for you. Since everything else is name based, no other change
is required.

### Starting the cluster

This cluster uses the `ssh`-into-all-the-boxes-and-start-things-up-approach, which is fine for testing.

Once all machines are up and provisioned, the cluster can be started. Log into the master, format hdfs and start the
cluster.

     $ vagrant ssh master
     $ (master) sudo su
     $ (root@master) prepare-cluster.sh
     $ (root@master) start-all.sh

After a little while, all daemons will be running and you have a fully working hadoop cluster. Note that the
`prepare-cluster.sh` step is a one time action.

### Stopping the cluster

If you want to shut down your cluster, but want to keep it around for later use, shut down all the services and tell
vagrant to stop the machines like this:

     $ vagrant ssh master
     $ (master) sudo su
     $ (root@master) stop-all.sh
     $ exit or Ctrl-D
     $ vagrant halt

When you want to use your cluster again, simply do this:

     $ vagrant up
     $ vagrant ssh master
     $ (master) sudo su
     $ (root@master) start-all.sh


### Getting rid of the cluster

If you don't need the cluster anymore and want to get your disk-space back do this:

     $ vagrant destroy -f

This will only delete the VMs all local files in the directory stay untouched and can be used again, if you decide to
start up a new cluster.

## Interacting with the cluster

### Webinterface

You can access all services of the cluster with your web-browser.

* namenode: http://master.local:50070/
* application master: http://master.local:8088/
* job history server: http://master.local:19888/

### Command line

To interact with the cluster on the command line, log into the master and use the hadoop command.

    $ vagrant ssh master
    $ (master) hadoop fs -ls /
    $ ...

You can access the host file system from the `/vagrant` directory, which means that you can drop your hadoop job in
there and run it on your own fully distributed hadoop cluster.

## Performance

Since this is a fully virtualized environment running on your computer, it will not be super-fast. This is not the goal
of this setup. The goal is to have a fully distributed cluster for testing and troubleshooting.

To not overload the host machine, has each tasktracker a hard limit of 1 map task and 1 reduce task at a time.

## HBase

This version of the cluster also contains [Apache HBase](http://hbase.apache.org). The layout on disk is similar to
Hadoop. The distributition is in `/opt/hbase-<version>`. 
You can start the HBase cluster after starting Hadoop as root.

    $ (root@master) start-hbase.sh

The Hadoop cluster must be running, before you issue this command, since HBase requires HDFS to be up and running.

To cluster is shut down like so:

    $ (root@master) stop-hbase.sh

The setup is fully distributed. `hadoop1`, `hadoop2` and `hadoop3` are running a
[zookeeper](http://zookeeper.apache.org) instance and a region-server each. The HBase master is running on the `master`
VM.

The webinterface of the HBase master is http://master.local:16010.


## Single Node setup

If your computer is not capable of running 4 VMs at a time, you can still benefit from this setup. The `single-node`
directory contains an alternative `Vagrantfile`, which only starts the `master` and deploys everything on it.

The interaction, the start- and stop sequence work the same ways as in the multi-VM cluster, except that it isn't fully
distributed. This slimmed down version of the setup also does not include HBase.

To run the single node setup, run `vagrant up` in the `single-node` directory instead of the root directory. Everything
else stays the same.

## Hacking & Troubleshooting

### File sharing

Vagrant makes it easy to share files between the vms of the cluster and your host machine. The project directory is
mounted under `/vagrant`, which enables you to get files from or to your host, by simply copying them into that
directory.

### Storage locations

The namenode stores the `fsimage` in `/srv/hadoop/namenode`. The datanodes  are storing all data in
`/srv/hadoop/datanode`.

### Resetting the cluster

Sometimes, when experimenting too much, your cluster might not start anymore. If that is the case, you can easily reset
it like so.

    $ for host in master hadoop1 hadoop2 hadoop3; do vagrant ssh $host --command  'sudo rm -rf /srv/hadoop' ; done
    $ vagrant provision

After those two commands your cluster is in the same state as when you started it for the first time. You can now
reformat the namenode and restart all services.

### Puppet

If you change any of the puppet modules, you can simply apply the changes with vagrants built-in provisioner.

    $ vagrant provision

### Hadoop download

In order to save bandwidth and time we download hadoop only once and store it in the `/vagrant` directory, so that the
other vms can reuse it. If the download fails for some reason, delete the tarball and rerun `vagrant provision`.
