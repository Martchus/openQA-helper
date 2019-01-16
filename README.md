# openQA helper
Scripts and (a little bit) documentation to ease openQA development.

Note that this aims to get a development setup where everything is cloned and started as your regular
user. The openQA packages are only installed to pull runtime dependencies.

## Setup guide
To get an idea what's going on, have a look at [openQA's architecture](architecture.pdf).

### Create PostgreSQL user, maybe import some data
* See https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#setup-postgresql

* Note that you'll have to migrate your database when upgrading major or minor PostgreSQL release.
  See https://www.postgresql.org/docs/8.1/static/backup.html

### Clone and configure all required repos
1. Add to `~/.bashrc` (or however I would like to add environment variables for the current user):
   ```
   export OPENQA_BASEDIR=/hdd/openqa-devel
   export OPENQA_CONFIG=$OPENQA_BASEDIR/config
   export OPENQA_LIBPATH=$OPENQA_BASEDIR/repos/openQA/lib # for foursixnine's way to let os-autoinst find openQA libs
   export DBUS_STARTER_BUS_TYPE=session
   export PATH="$PATH:/usr/lib64/chromium:$OPENQA_BASEDIR/repos/openQA-helper/scripts"
   export OPENQA_KEY=set_later
   export OPENQA_SECRET=set_later
   export OPENQA_SCHEDULER_WAKEUP_ON_REQUEST=1
   export OPENQA_SCHEDULER_SCHEDULE_TICK_MS=1000
   #export OPENQA_SQL_DEBUG=true # enables debug printin of SQL statements
   alias openqa-cd='source openqa-cd' # allows to type openqa-cd to cd into the openQA repository
   ```
   Replace `/hdd/openqa-devel` with the location you want to have all your openQA stuff. Consider that
   it will need a considerably amount of disk space. The key and secret must be adjusted later when
   created via the web UI.
2. `mkdir -p $OPENQA_BASEDIR/repos; cd $OPENQA_BASEDIR/repos; git clone https://github.com/Martchus/openQA-helper.git`
3. Install all packages required for openQA development via `openqa-install-devel-deps`. This script will work only for
   openSUSE. It will also add some required repositories. Maybe you better open the script before just running it to
   be aware what it does and prevent eg. duplicated repositories.
4. Fork all required repos on GitHub:
     * [os-autoinst/os-autoinst](https://github.com/os-autoinst/os-autoinst) - "backend", the thing that starts/controls the VM)
     * [os-autoinst/openQA](https://github.com/os-autoinst/openQA) - mainly the web UI, scheduler, worker and documentation
     * [os-autoinst/os-autoinst-distri-opensuse](https://github.com/os-autoinst/os-autoinst-distri-opensuse) - the actual tests (for openSUSE)
     * [os-autoinst/os-autoinst-needles-opensuse](https://github.com/os-autoinst/os-autoinst-needles-opensuse) - needles/reference images (for openSUSE)
     * I also encourage you to fork *this* repository because there's still room for improvement.
5. Execute `openqa-devel-setup your_github_name` to clone all required repos to the correct directories inside `$OPENQA_BASEDIR`. This also adds
   your forks.

Now you are done and can try to start openQA's services (see next section). It will initialize the database and pull required assets (eg. jQuery) the
first time you start it (so it might take some time).

Also be aware of the official documentation under https://github.com/os-autoinst/openQA/blob/master/docs
and https://github.com/os-autoinst/os-autoinst/tree/master/doc.

### Notes
Be aware that not everybody is aware of `OPENQA_BASEDIR`. So some code in the test distribution might
rely on things being at the default location under `/var/lib/openqa` (eg. when using svirt backend to
actually connect to a remote host). This can be worked around by creating (at least temporarily)
a symlink.

## Starting the web UI and all required daemons
This repository contains a helper to start all daemons in a consistent way. It also passed required parameters (eg. for API keys) automatically.

To start the particular daemons, run the following commands:

* `openqa-start wu` - starts the web UI
* `openqa-start ws` - starts the websocket server (mainly used by the worker to connect to the web UI)
* `openqa-start ra` - starts the "resource allocator" (required to start jobs)
* `openqa-start sc` - starts the scheduler (required to schedule jobs)
* `openqa-start lv` - starts the live view handler (required for the developer mode)
* `openqa-start wo` - starts the worker
* `openqa-start wo --instance 2` - starts another worker
* `openqa-start all` - starts all daemons listed above, each in its own Konsole tab (only works with Konsole)
* `openqa-start cj --from openqa.opensuse.org 1234` - clones job 1234 from o3

Note that none of these commands need to be run as root. Additional parameters are simply appended to the invocation.

## Switching between databases conveniently
* Create files similar to the ones found under `example-config`.
* Don't change the pattern used for the filenames.
* Use eg. `openqa-switchdb osd` to activate the configuration `database-osd.ini`.

## Keeping repos up-to-date
Just execute `openqa-devel-maintain`. If the local master is checked out in a repository, the
script automatically resets it to the latest state on `origin`. So It is assumed that you'll never
ever use the local master to do modifications! Configure and make are for os-autoinst are run
automatically.

## Run tests of openQA itself
1. Go to the openQA repository (eg. `openqa-cd`).
2. Initialize a separate PostgreSQL database for testing via `openqa-pg`.
3. Run a test with `openqa-test`, eg. `openqa-test t/ui/14-dashboard-parents.t`.

### Notes
* To run Selenium tests *not* headless use eg. `NOT_HEADLESS=1 openqa-test t/ui/14-dashboard-parents.t`.
* Be sure to stop your regular worker, scheduler, ... before starting the one of the fullstack tests.

## Run tests of openQA itself with Docker
See [documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#running-tests-of-openqa-itself).

### Prepare running tests via Docker
```
sudo zypper in docker
```

Customize path for Docker stuff (I don't want it on the SSD):
```
SYSTEMD_EDITOR=/bin/vim sudo -E systemctl edit docker.service

[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --add-runtime oci=/usr/sbin/docker-runc --data-root=/hdd/docker $DOCKER_NETWORK_OPTIONS $DOCKER_OPTS
```

```
sudo systemctl start docker.service
sudo docker pull dasantiago/openqa-tests
```

### Run tests
```
# get latest docker image - here it is openqa**_dev**:latest
docker pull registry.opensuse.org/devel/openqa/containers/openqa_dev:latest

# build the docker image - here we build openqa:latest (without **_dev*)
cd "$OPENQA_BASEDIR/repos/openQA"
make docker-test-build

# run regular tests
openqa-docker-test

# pass env vars, eg. to run fullstack test
openqa-docker-test -e FULLSTACK=1
openqa-docker-test -e DEVELOPER_FULLSTACK=1

# expose ports
# FIXME: not working for me
openqa-docker-test -e MOJO_PORT=12345 -p 12345-12347:12345-12347

# non-headless mode
openqa-docker-test -e NOT_HEADLESS=1

# set custom container name
export CONTAINER_NAME=the-other-testrun

# run custom command
openqa-docker-test -- bash

# use custom os-autoinst
# (assumes there's a clean os-autoinst checkout under "$OPENQA_BASEDIR/repos/os-autoinst-clean")
openqa-docker-test -e DEVELOPER_FULLSTACK=1 -e CUSTOM_OS_AUTOINST=1
```

### Enter running container with Bash
```
openqa-docker-bash
```

### Stop test again, get rid of container
```
sudo docker stop openqa-testsuite
sudo docker container rm openqa-testsuite
```

## Checking for JavaScript errors
```
sudo zypper in npm
openqa-cd
npm install jshint
echo "node_modules/
package-lock.json" >> .git/info/exclude
```

```
node_modules/jshint/bin/jshint assets/javascripts/running.js
```

## Using the worker cache locally
Add the following line to global section of `$OPENQA_CONFIG/workers.ini`:
```
CACHEDIRECTORY = /hdd/openqa-devel/openqa/worker/cache
```

Adjust the path to your needs and be sure it is accessible to your user.

Besides the usual daemons, start:
```
openqa-start workercache
openqa-start workercache-minion
```

## Test/run svirt backend locally
This backend basically connects to another machine via SSH and runs some
`virsh` commands there to start a virtual machine via libvirt from there.

### Configuration
Example config for local testing (add to `$OPENQA_CONFIG/workers.ini`):
```
[2]
BACKEND=svirt
VIRSH_HOSTNAME=127.0.0.1 # use our own machine as svirt host
VIRSH_USERNAME=root # see notes
VIRSH_CMDLINE=ifcfg=dhcp
VIRSH_MAC=52:54:00:12:34:56 # not sure at which point this is used
VIRSH_OPENQA_BASEDIR=/hdd/openqa-devel
WORKER_CLASS=svirt,svirt-kvm
VIRSH_INSTANCE=1
#VIRSH_PASSWORD=# see notes
VIRSH_GUEST=127.0.0.1
VIRSH_VMM_FAMILY=kvm
VIRSH_VMM_TYPE=hvm
```

Packages to install:
```
sudo zypper in libvirt-client libvirt-daemon libvirt-daemon-driver-interface libvirt-daemon-driver-qemu libvirt-daemon-qemu
sudo zypper in virt-manager # for GUI
```

Services to start:
```
sudo systemctl start libvirtd
sudo systemctl start sshd
```

#### Notes
* So this setup for the svirt backend will connect via SSH to the local machine and start qemu via libvirtd/virsh.
* Either put your (root) password in the worker config or even use
 `bash -c "cat /home/$USER/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys"`. Or preferrably allow some other user to use
 `virsh` and manipluate contents of `/var/lib/libvirt/images` and set its name via `VIRSH_USERNAME`.

## Running a job
So far I have just cloned an arbitrary job (opensuse-15.0-KDE-Live-x86_64-Build20.71-kde-live-wayland@64bit_virtio-2G)
which I had usually running via qemu backend and started the previously configured worker instance:

```
openqa-start cj --from http://localhost:9526 280 BACKEND=svirt WORKER_CLASS=svirt
openqa-start wo --instance 2
```

## Test with tap devices locally
Set the worker class, eg. `WORKER_CLASS=qemu_x86_64,qemu_i686,qemu_i586,tap`. Then give yourself permissions to
the required tap devices, eg.:

```
sudo groupadd netdev
sudo usermod -a -G netdev "$USER"
sudo ip tuntap add dev tap6 mode tap group netdev
sudo ip tuntap add dev tap7 mode tap group netdev
```

For Open vSwitch see http://open.qa/docs/#_multi_machine_tests_setup.

## Profiling
1. Install NYTProf, under Tumbleweed: `zypper in perl-Devel-NYTProf perl-Mojolicious-Plugin-NYTProf`
2. Put `profiling_enabled = 1` in  `openqa.ini`.
3. Optionally import production data like described in the official contributers documentation.
4. Restart the web UI, browse some pages. Profiling is done in the background.
5. Access profiling data via `/nytprof` route.

### Note
Profiling data is extensive. Use `openqa-clear-profiling-data` to get rid of it again and disable the
`profiling_enabled` configuration if not needed right now.

Keeping too much profiling data around slows down Docker statup for the testsuite significantly as it
copies all the data of your openQA repository checkout.

## More scripts
* https://github.com/okurz/scripts
