# amazee.io cachalot

Local OS X Drupal Hosting based on Docker with batteries included, aimed at making a more pleasant local development experience.
Based on the very awesome [dinghy](https://github.com/codekitchen/dinghy) by codekitchen.
Runs on top of [docker-machine](https://github.com/docker/machine).

Why should you use cachalot instead of the regular docker-machine?
  * Faster volume sharing using NFS rather than built-in virtualbox/vmware file shares.
  * Filesystem events work on mounted volumes. Edit files on your host, and see gulp/grunt pick up the changes immediately.
  * Easy access to running containers using built-in DNS proxy.

Cachalot creates its own VM using `docker-machine`, it will not modify your existing `docker-machine` VMs.

## FAQ and solutions to common problems

Before filing an issue, see the [FAQ](FAQ.md).

## install

First the prerequisites:

1. OS X Yosemite (10.10) or higher
1. [Homebrew](https://github.com/Homebrew/homebrew)
1. Docker and Docker Machine. These can either be installed with Homebrew (`brew install docker docker-machine`), or using a package such as the Docker Toolbox.
1. A Virtual Machine provider for Docker Machine. Currently supported options are:
    * [xhyve](http://www.xhyve.org/) installed with [docker-machine-driver-xhyve](https://github.com/zchee/docker-machine-driver-xhyve#install).
    * [VirtualBox](https://www.virtualbox.org). Version 5.0+ is strongly recommended, and you'll need the [VirtualBox Extension Pack](https://www.virtualbox.org/wiki/Downloads) installed.
    * [VMware Fusion](http://www.vmware.com/products/fusion).
    * [Parallels](https://www.parallels.com/products/desktop/) installed with [docker-machine-parallels](https://github.com/Parallels/docker-machine-parallels).

Then:

    $ brew tap amazeeio/cachalot
    $ brew install cachalot

You will need to install `docker` and `docker-machine` as well, either via Homebrew or the official Docker package downloads. To install with Homebrew:

    $ brew install docker docker-machine

You can specify provider (`virtualbox`, `vmware`, `xhyve` or `parallels`), memory and CPU options when creating the VM. See available options:

    $ amazeeio-cachalot help create

Then create the VM and start services with:

    $ amazeeio-cachalot create --provider virtualbox

Once the VM is up, you'll get instructions to add some Docker-related
environment variables, so that your Docker client can contact the Docker
server inside the VM. I'd suggest adding these to your .bashrc or
equivalent.

Sanity check!

    $ docker run hello-world

## CLI Usage

```bash
$ amazeeio-cachalot help
Commands:
  amazeeio-cachalot create          # create the docker-machine VM
  amazeeio-cachalot destroy         # stop and delete all traces of the VM
  amazeeio-cachalot halt            # stop the VM and services
  amazeeio-cachalot help [COMMAND]  # Describe available commands or one specific command
  amazeeio-cachalot ip              # get the VM's IP address
  amazeeio-cachalot restart         # restart the VM and services
  amazeeio-cachalot env             # returns env variables to set, should be run like $(amazeeio-cachalot env)
  amazeeio-cachalot ssh [args...]   # ssh to the VM
  amazeeio-cachalot status          # get VM and services status
  amazeeio-cachalot up              # start the Docker VM and services
  amazeeio-cachalot upgrade         # upgrade the boot2docker VM to the newest available
  amazeeio-cachalot version         # display amazeeio-cachalot version
```

## DNS

Cachalot installs a DNS server listening on the private interface, which
resolves \*.docker.amazee.io to the Cachalot VM.


## Preferences

Dinghy creates a preferences file under ```HOME/.amazeeio-cachalot/preferences.yml```, which can be used to override default options. This is an example of the default generated preferenes:

```
:preferences:
  :fsevents_disabled: false
  :create:
    provider: virtualbox
```

If you want to override the amazeeio-cachalot machine name (e.g. to change it to 'default' so it can work with Kitematic), it can be changed here. First, destroy your current amazeeio-cachalot VM and then add the following to your preferences.yml file:

```
:preferences:
.
.
.
  :machine_name: default
```

## Problems?

check the [FAQ](FAQ.md).

## a note on NFS sharing

Cachalot shares your home directory (`/Users/<you>`) over NFS, using a
private network interface between your host machine and the Dinghy
Docker Host. This sharing is done using a separate NFS daemon, not the
system NFS daemon.

Be aware that there isn't a lot of security around NFSv3 file shares.
We've tried to lock things down as much as possible (this NFS daemon
doesn't even listen on other interfaces, for example).

## upgrading

If you didn't originally install Dinghy as a tap, you'll need to switch to the
tap to pull in the latest release:

    $ brew tap amazeeio/cachalot

To update Dinghy itself, run:

    $ amazeeio-cachalot halt
    $ brew update
    $ brew upgrade amazeeio-cachalot
    $ amazeeio-cachalot up

To update the Docker VM, run:

    $ amazeeio-cachalot upgrade

This will run `docker-machine upgrade` and then restart the amazeeio-cachalot services.

## forked from

 - https://github.com/codekitchen/dinghy

## built on

 - https://github.com/docker/machine
 - https://github.com/markusn/unfs3
 - https://github.com/Homebrew/homebrew
 - http://www.thekelleys.org.uk/dnsmasq/doc.html
 - https://github.com/jwilder/nginx-proxy
