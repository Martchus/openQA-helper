# openQA helper
Scripts and (a little bit) documentation to ease openQA development.

Note that this aims to get a development setup where everything is started as your regular
user. The openQA packages are only installed to pull runtime dependencies.

## Setup guide
### Create PostgreSQL user, maybe import some data
* See https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#setup-postgresql

* Note that you'll have to migrate your database when upgrading major or minor PostgreSQL release.
  See https://www.postgresql.org/docs/8.1/static/backup.html

### Clone and configure all required repos
* Add to `~/.bashrc`:
  ```
  export OPENQA_BASEDIR=/hdd/openqa-devel
  export OPENQA_CONFIG=$OPENQA_BASEDIR/config
  export OPENQA_LIBPATH=$OPENQA_BASEDIR/repos/openQA/lib # for foursixnine's way to let os-autoinst find openQA libs
  export DBUS_STARTER_BUS_TYPE=session
  export PATH="$PATH:/usr/lib64/chromium:$OPENQA_BASEDIR/repos/openQA-helper/scripts"
  #export OPENQA_SQL_DEBUG=true
  export OPENQA_KEY=set_later
  export OPENQA_SECRET=set_later
  export OPENQA_SCHEDULER_WAKEUP_ON_REQUEST=1
  export OPENQA_SCHEDULER_SCHEDULE_TICK_MS=1000
  alias openqa-cd='source openqa-cd'
  ```
  Replace `/hdd/openqa-devel` with the location you want to have all your openQA stuff. Consider that
  it will need a considerably amount of disk space. The key and secret must be adjusted later when
  created via the web UI.
* `mkdir -p $OPENQA_BASEDIR/repos; cd $OPENQA_BASEDIR/repos; git checkout https://github.com/Martchus/openQA-helper.git`
* Install all packages required for openQA development via `openqa-install-devel-deps`.
* Fork all required repos on GitHub under your name: `os-autoinst/os-autoinst`, `os-autoinst/openQA`,
  `os-autoinst/os-autoinst-distri-opensuse` and `os-autoinst/os-autoinst-needles-opensuse`.
* Execute `openqa-devel-setup your_github_name` to clone all required repos. This also adds your
  forks.

## Switching between databases conveniently
* Create files similar to the ones found under `example-config`.
* Don't change the pattern used for the filenames.
* Use eg. `openqa-switchdb osd` to activate the configuration `database-osd.ini`.

## Keeping repos up-to-date
Just execute `openqa-devel-maintain`. If the local master is checked out in a repository, the
script automatically resets it to the latest state on `origin`. So It is assumed that you'll never
ever use the local master to do modifications! Configure and make are for os-autoinst are run
automatically.

## Run tests with Docker
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
# build the docker image
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

## More scripts
* https://github.com/okurz/scripts
