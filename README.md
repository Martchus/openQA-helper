# openQA helper
Scripts and (a little bit) documentation to ease openQA development. The focus lies on developing
openQA (and os-autoinst) itself. This setup might be an overkill if one simply wants to run some
tests. Maybe [openqa-bootstrap](https://github.com/os-autoinst/openQA/blob/master/script/openqa-bootstrap)
or [openqa-bootstrap-container](https://github.com/os-autoinst/openQA/blob/master/script/openqa-bootstrap-container)
are better alternatives for these use-cases.

These helpers and the setup guide aim for a development setup where

* everything is cloned and lives under a single directory-tree owned by your regular user.
* everything is built and started as your regular user.
* os-autoinst's native binaries are built manually.
* all dependencies are installed via zypper (rather than language-specific package managers).
* no containers are used. One can optionally use Docker to run tests, though.
* `sudo` is used explicitly if root privileges are required.

## What about my existing openQA setup
Since all files are installed to a single directory-tree of your choice the interference with other
openQA setups (e.g. the packaged version) is minimal. If you have already installed openQA via a
different method there's no need to uninstall it first - just take care that both versions are not
running at the same time when using the standard ports. You should also consider using a separate
database. To get rid of this openQA setup again, just delete the directory-tree and additional
PostgreSQL databases you might have created (via `dropdb`).

## Further notes
I recommend to use Tumbleweed as development system for openQA - at least when using these helpers.
It has proven to be stable enough for me. Using Leap you might miss some of the required packages.
Besides, the script `openqa-install-devel-deps` only works under Tumbleweed.

Note that the subsequent setup guide is merely a result of me documenting the steps I took when
setting up my own workstation.

## Setup guide
It makes sense to get an idea of the *thing* you're going to install before installing it.

So have a look
at [openQA's architecture](https://github.com/os-autoinst/openQA/blob/master/docs/GettingStarted.asciidoc#architecture)
to see what's going on.

To really get an idea what's going on, have a look
at [the more detailed diagram](https://github.com/os-autoinst/openQA/blob/master/docs/images/architecture.svg).

Especially take care that none of the mentioned ports are already in use.

### Configure environment variables
Add to `~/.bashrc` (or *somehow* add the following environment variables for the current user):
```
export OPENQA_BASEDIR=/hdd/openqa-devel
export OPENQA_CONFIG=$OPENQA_BASEDIR/config
export OPENQA_LIBPATH=$OPENQA_BASEDIR/repos/openQA/lib # for foursixnine's way to let os-autoinst find openQA libs
export OPENQA_LOCAL_CODE=$OPENQA_BASEDIR/repos/openQA
export OPENQA_CGROUP_SLICE=systemd/openqa/$USER
export OPENQA_KEY=set_later
export OPENQA_SECRET=set_later
export OPENQA_SCHEDULER_WAKEUP_ON_REQUEST=1
export OPENQA_SCHEDULER_SCHEDULE_TICK_MS=1000
export PATH="$PATH:/usr/lib64/chromium:$OPENQA_BASEDIR/repos/openQA-helper/scripts"
alias openqa-cd='source openqa-cd' # allows to type openqa-cd to cd into the openQA repository
```

Replace `/hdd/openqa-devel` with the location you want to have all your openQA stuff. Consider that
it will need a considerably amount of disk space. The `OPENQA_KEY` and `OPENQA_SECRET` must be adjusted later when
created via the web UI (see step 6 of subsequent section "Clone and configure all required repos").

### Create PostgreSQL user, maybe import some data
* See https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#setting-up-the-postgresql-database
    * You can of course skip `pg_restore`. Starting with an empty database is likely sufficient for the beginning.
    * It makes sense to use a different name for the database than `openqa`. I usually use `openqa-local` and when
      importing later production data from OSD and o3 `openqa-osd` and `openqa-o3`.
        * You will need to update the database configuration file as the linked instructions say. However, the
          relevant file under `$OPENQA_CONFIG/database.ini` has not been created so far so we will come back to
          this point later.
        * Note that the database configuration file under `/etc/openqa` or the Git checkout are not used by this
          setup and changing it will have no effect.
* Imporing database dumps from our production instances is useful for local testing. The dumps can be
  found on wotan (not publicly accessible).
    * Example using `sshfs`:
      ```
      mkdir -p ~/wotan && sshfs ${WOTAN_USER_NAME}@wotan.suse.de:/ ~/wotan
      ln -s ~/wotan/mounts/work_users/coolo/SQL-DUMPS $OPENQA_BASEDIR/sql-dumps-on-wotan
      ```
    * Example using `rsync`:
      ```
      rsync -aHP \
        "${WOTAN_USER_NAME}@wotan.suse.de:/mounts/work/users/coolo/SQL-DUMPS/openqa.opensuse.org/$(date --date="1 day ago" +%F).dump" \
        "$OPENQA_BASEDIR/sql-dumps/openqa.opensuse.org"
      rsync -aHP \
        "${WOTAN_USER_NAME}@wotan.suse.de:/mounts/work/users/coolo/SQL-DUMPS/openqa.suse.de/$(date --date="1 day ago" +%F).dump" \
        "$OPENQA_BASEDIR/sql-dumps/openqa.suse.de"
      ```
* Note that you'll have to migrate your database when upgrading major or minor PostgreSQL release.
  See https://www.postgresql.org/docs/8.1/static/backup.html

### Clone and configure all required repos
1. `mkdir -p $OPENQA_BASEDIR/repos && cd $OPENQA_BASEDIR/repos && git clone https://github.com/Martchus/openQA-helper.git`
2. Install all packages required for openQA development via `openqa-install-devel-deps`. This script will work only for
   Tumbleweed. It will also add some required repositories. Maybe you better open the script before just running it to
   be aware what it does and prevent e.g. duplicated repositories. When not using Tumbleweed, checkout files within the
   [dist](https://github.com/os-autoinst/openQA/tree/master/dist) directory for required dependencies.
3. Fork all required repos on GitHub:
     * [os-autoinst/os-autoinst](https://github.com/os-autoinst/os-autoinst) - "backend", the thing that starts/controls the VM
     * [os-autoinst/openQA](https://github.com/os-autoinst/openQA) - mainly the web UI, scheduler, worker and documentation
     * [os-autoinst/os-autoinst-distri-opensuse](https://github.com/os-autoinst/os-autoinst-distri-opensuse) - the actual tests (for openSUSE)
     * [os-autoinst/os-autoinst-needles-opensuse](https://github.com/os-autoinst/os-autoinst-needles-opensuse) - needles/reference images (for openSUSE)
     * [scripts](https://github.com/os-autoinst/scripts) - additional scripts (e.g. for monitoring)
     * I also encourage you to fork *this* repository because there's still room for improvement.
4. Execute `openqa-devel-setup your_github_name` to clone all required repos to the correct directories inside `$OPENQA_BASEDIR`. This also adds
   your forks.
5. Now you are almost done and can try to start openQA's services (see next section). Until finishing this guide, only start the web UI. It will
   initialize the database and pull required assets (e.g. jQuery) the first time you start it (so it might take some time).
6. Generate API keys and update the environment variables configured in the previous section "Configure environment variables". To generate API keys
   you need to access the web UI page http://localhost:9526/api_keys, specify an expiration date and click on "Create".
7. The openQA config files will be located under `$OPENQA_BASEDIR/config`.
    * If you've chosen a database name other than `openqa` as suggested, update `$OPENQA_CONFIG/database.ini` accordingly
      (see [official documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Installing.asciidoc#database)).
    * In `worker.ini` you likely want to adjust the `HOST` to `http://localhost:9526` so the worker will directly
      connect to the web UI and websocket server (making it unnessarary to use an HTTP reverse proxy).
    * For this setup it makes most sense to set `WORKER_HOSTNAME` to `127.0.0.1` in `worker.ini`. Note that for remote workers (not covered by this setup
      guide) the variable must be set to an IP or domin which the web UI can use to connect to the worker host
      (see [official documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Pitfalls.asciidoc#steps-to-debug-developer-mode-setup)).
    * Useful adjustments to the config for using the svirt backend, enable caching and profiling
      are given in the subsequent sections.
8. You can now also try to start the other services (as described in the next section) to check whether they're running. In practise I usually
   only start the services which I require right now (to keep things simple).
9. Before you can run a job you also need to build isotovideo from the sources cloned via Git in previous steps.
    To do so, just invoke `openqa-devel-maintain` (see section "Keeping repos up-to-date" for details).
    * These helpers are using the CMake build system.
    * The build directory is `$OPENQA_BASEDIR/build/os-autoinst`. It is of course possible to invoke CMake in that directory manually to tweak
      the configuration, e.g. to use Ninja or to set cache variables.

Also be aware of the official documentation under https://github.com/os-autoinst/openQA/blob/master/docs
and https://github.com/os-autoinst/os-autoinst/tree/master/doc.

### Notes
Be aware that not everybody is aware of `OPENQA_BASEDIR`. So some code in the test distribution might
rely on things being at the default location under `/var/lib/openqa`.
This can be worked around by creating (at least temporarily) a symlink.

To use the openQA instance located under `OPENQA_BASEDIR` with the apache2 reverse proxy one has to adjust the apache2
configuration using `openqa-make-apache2-use-basedir`. Otherwise images won't load.

## Starting the web UI and all required daemons
This repository contains a helper to start all daemons in a consistent way. It also passes required parameters (e.g. for API keys)
automatically.

To start the particular daemons, run the following commands:

* `openqa-start wu` - starts the web UI
* `openqa-start ws` - starts the websocket server (mainly used by the worker to connect to the web UI)
* `openqa-start sc` - starts the scheduler (required to schedule jobs)
* `openqa-start lv` - starts the live view handler (required for the developer mode)
* `openqa-start gru run` - starts the GRU/Minion daemon required to run background tasks (cleanup, needling)
* `openqa-start wo` - starts the worker
* `openqa-start wo --instance 2` - starts another worker
* `openqa-start all` - starts all daemons listed above, each in its own Konsole tab (only works with Konsole)
* `openqa-start cj --from openqa.opensuse.org 1234` - clones job 1234 from o3
* `openqa-start cl ` - invokes the client with the options to connect to the local web UI
* `openqa-start cmd` - invokes the specified command on the web UI app, e.g.:
    * `openqa-start cmd eval -V 'app->schema->resultset("Jobs")->count'` - do *something* with the app/database
    * `openqa-start cmd minion job -e minion_job_name` - enqueue a Minion job
    * `openqa-start cmd eval -V 'print(app->minion->job(297)->info->{result})'` - view e.g. log of Minion job
    * `openqa-start cmd minion job -h` - view other options regarding Minion jobs

Additional parameters are simply appended to the invocation. That works of course also for `--help`.

**Note that none of these commands should to be run as root.**
Running one of these commands accidently as root breaks the setup because then newly created files and directories are
owned by root and you run into permission errors when starting as your regular user again.

It is possible to start multiple web UI instances at the same time by adjusting the ports to be used. In general this works by
setting the environment variable `OPENQA_BASE_PORT`. For convenience the start script also supports `OPENQA_INSTANCE` which
can be set an integer, e.g. to `1`. Then the core web UI will use port `9626`, the web socket server
port `9627`, the live view handler port `9628` and so on. Note that `/$OPENQA_INSTANCE` will be appended to `OPENQA_CONFIG`
so you can (and should) configure different databases for your instances (see 'Copying a database' section).
To start multiple workers, just use `--instance` as shown in the examples above.

To use a custom checkout of Mojo-IOLoop-ReadWriteProcess located under `$OPENQA_BASEDIR/repos/Mojo-IOLoop-ReadWriteProcess`
set the environment variable `CUSTOM_MOJO_IO_LOOP_READ_WRITE_PROCESS`.

To use a different os-autoinst checkout located under `$OPENQA_BASEDIR/repos/directory-of-custom-checkout` set the
environment variable `CUSTOM_OS_AUTOINST_DIR` to `directory-of-custom-checkout`.

### Run a service with systemd
Sometimes it can be useful to run a service with systemd to see how changes behave in this case. Maybe you also want to test
changes within the systemd service file at the same time.

As explaind **none of the services should be run as root**. Hence it is not a good idea to amend your regular systemd service
files. Instead, add a systemd service file to your home directory under `~/.config/systemd/user` and start it as your regular
user via e.g. `systemctl start --user openqa-worker@1` (and follow logs via e.g. `journalctl --user -fu openqa-worker@1`).

An example user unit for the worker can be found within the `example-systemd` directory. It is basically a copy of the regular
service file with everything unwanted removed/replaced (most notably the command, the user and dependencies).

## Keeping repos up-to-date
Just execute `openqa-devel-maintain`. If the local master or a detetched HEAD is checked out in a repository, the
script automatically resets it to the latest state on `origin`. So it is assumed that you'll never ever use the local
master or a detetched HEAD to do modifications! The os-autoinst build is updated automatically (without overriding any
custom CMake cache variables).

## Managing databases
### Switching between databases conveniently
* Create files similar to the ones found under `example-config`.
* Don't change the pattern used for the filenames.
* Use eg. `openqa-switchdb osd` to activate the configuration `database-osd.ini`.

### Copying a database
One can use transactions to roll back changes. However, sometimes it is still useful to copy a database, e.g. for running
multiple web UIs on your host forking the database from your initial web UI.

```
sudo sudo -u postgres createdb -O $USER -T openqa-local openqa-local-copy
```

### Update migration scripts and create a fork of a database
The official documentation describes
[how to update the database schema](https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#how-to-update-the-database-schema).

One can also use `openqa-start` to invoke the scripts the official documentation mentions with `--force`:
```
openqa-start dbup
```

The official documentation also mentiones that you should backup your database before actually running the migration because it is
likely that you need to go back to do further adjustments. To ease this process there's the script `openqa-renewdb`.
It will update the deployment scripts and create a "fork" of the specified database under a different name.
It will also configure openQA to use that database.

There's also `openqa-branchdb` which does the same as `openqa-renewdb` except that `initdb` and `updatedb` are not executed.

#### Remarks
* Be sure to stop all services using the database before running the script.
* A previously created fork is dropped and replaced by a new one.

### Misc
#### Delete database
```
dropdb database-to-drop
```
#### Rename database and switch to it
```
openqa-renamedb old_name new_name
```

## Run tests of openQA itself
1. Go to the openQA repository (eg. `openqa-cd`).
2. Initialize a separate PostgreSQL database for testing via `openqa-pg`.
3. Run a test with `openqa-test`, eg. `openqa-test t/ui/14-dashboard-parents.t`.

## Run tests of os-autoinst itself
* Use the helper `os-autoinst-test`, e.g. `os-autoinst-test 30-mmapi.t`.
    * Run the helper in an arbitrary directory to use the default build.
    * Run the helper in a specific build directory to use that build.
* Read os-autoinst's README for more options.

### Notes
* To run Selenium tests *not* headless use eg. `NOT_HEADLESS=1 openqa-test t/ui/14-dashboard-parents.t`.
* Be sure to stop your regular worker, scheduler, ... before starting the one of the fullstack tests.

## Run tests of openQA itself with Docker
See [documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#running-tests-of-openqa-itself).

### Prepare running tests via Docker
```
sudo zypper in docker
sudo systemctl start docker
```

Customize path for Docker stuff (I don't want it on the SSD):
```
SYSTEMD_EDITOR=/bin/vim sudo -E systemctl edit docker.service

[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --add-runtime oci=/usr/sbin/docker-runc --data-root=/hdd/docker $DOCKER_NETWORK_OPTIONS $DOCKER_OPTS
```

Pull and build the latest image:
```
# get latest Docker image - here it is openqa**_dev**:latest
docker pull registry.opensuse.org/devel/openqa/containers/openqa_dev:latest

# get the docker image used by CircleCI
docker pull registry.opensuse.org/devel/openqa/ci/containers/base:latest

# build the docker image - here we build openqa:latest (without **_dev*)
cd "$OPENQA_BASEDIR/repos/openQA"
make docker-test-build

# build the docker image used by CircleCI according to dependnencies.txt
# note: Adjust dependnencies.txt if the version it wants to install is not available.
.circleci/build_local_docker.sh
```

For convenience, these helper also provide the `openqa-docker-update` commands which executes the commands
above.

### Run tests in the Docker container used by CircleCI
Get a shell within the container:

```
IMAGE_NAME=localtest PATH_INSIDE_CONTAINER=/opt/testing_area openqa-docker-test -- bash
```

Then you can run tests as usual from that shell. You can also try to run e.g. `make test …` directly but it might
not work when `$(PWD)` is used.

To access the database:

```
psql -h /dev/shm/tpg openqa_test
```

It seems like the temporary storage is quite limited. One can adjust `OpenQA::Test::Database` to use always
the same schema and clean the `/tmp` directory.

### Run tests (pre CircleCI)
* To ensure the latest image is used, re-execute the command(s) from the previous section.
* This always appends `bash` so you have a shell for further investigation.
* If it hangs on startup get rid of profiling data using `openqa-clear-profiling-data`.

```
# run regular tests
openqa-docker-test

# pass env vars, eg. to run fullstack test
openqa-docker-test -e FULLSTACK=1
openqa-docker-test -e DEVELOPER_FULLSTACK=1
openqa-docker-test -e SCHEDULER_FULLSTACK=1

# expose ports
# FIXME: not working for me - suggestions are welcome
openqa-docker-test -e MOJO_PORT=12345 -p 12345-12347:12345-12347

# non-headless mode
# FIXME: not working *anymore* - any suggestions are welcome
openqa-docker-test -e NOT_HEADLESS=1

# set custom container name
export CONTAINER_NAME=the-other-testrun

# run custom command
openqa-docker-test -- prove -v t/ui/15-comments.t
# note: Fullstack tests need a special setup so use the environment variables for them instead
#       of trying to run prove directly.

# use custom os-autoinst (mind the caveats mentioned in the documentation linked above!)
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

### Useful commands
* Do something with a container
    1. Find container ID with `docker ps`
    2. Most useful commands: `docker exec/stop/rm $container_id …`
* Monitor traffic within the container
    1. Install `tcpdump` within the container.
    2. Use it like `docker exec $container_id sudo tcpdump -vvAls0 -i lo` to monitor traffic on a certain interface
       within the container.

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

## Installing a custom version of Perl dependencies like Perl::Tidy
This setup aims to install every dependency using the package manager. This is only intended
for exceptional cases like installing multiple versions of `Perl::Tidy`.

Install `cpanm`:
```
sudo zypper in perl-App-cpanminus
```

Install and use the Perl dependency, e.g.:
```
version_number=20191203
openqa-perl-prefix-install perltidy-$version_number Perl::Tidy@$version_number
openqa-perl-prefix-run perltidy-$version_number tools/tidy --only-changed
```

As always, everything is stored under `$OPENQA_BASEDIR` and owned by your regular user.

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
### Using an svirt host from production
One can try to [take out](#useful-systemd-commands) an svirt worker slot from production and configure a local
worker slot to use the production svirt host. For that, just copy the settings found in the worker config on the
production host for the particular worker slot to the local worker config. Note that taking out the production
worker slot is necessary to avoid multiple jobs from using the same svirt host in parallel.

Please inform team members about this before, leave a note in the corresponding ticket and take the production
worker slot back-in when you're done.

### Using QEMU/KVM to test completely locally (might not work)
This backend basically connects to another machine via SSH and runs some
`virsh` commands there to start a virtual machine via libvirt from there.

#### Configuration
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
* Usually QEMU isn't used via svirt so this setup isn't well tested. When I tried it recently, the QEMU line was wrong
  preventing the system to boot from the image.

#### Running a job
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

## Schedule jobs via "isos post" locally to test dependency handling
This example is about creating directly chained dependencies but the same applies to other dependency
types.

Usually I don't care much which exact job is being executed. In these examples I've just downloaded the
lastest TW build from o3 into the `isos` directory and set `BUILD` and `ISO` accordingly. In addition, I
set the `SCHEDULE` variable to reduce the number of test modules.

### Configuration steps

Create a test suite for the parent, e.g.:

```
name: directly-chained-parent
settings:
DESKTOP=minimalx
SCHEDULE=tests/installation/isosize,tests/installation/bootloader_start
```

Create a test suite for the child, e.g.:

```
name: directly-chained-child-01
settings:
DESKTOP=minimalx
SCHEDULE=tests/installation/isosize,tests/installation/bootloader_start
START_DIRECTLY_AFTER_TEST=directly-chained-parent
```

You may create more similar child test suites to create a bigger cluster.

Create a medium type if you don't already have one, e.g.:

```
distri: opensuse
version: *
flavor: DVD
arch: x86_64
settings: ISO_MAXSIZE=4700372992
```

Create a machine if you don't already have one, e.g.:

```
name: 64bit
backend: qemu
settings:
HDDSIZEGB=20
QEMUCPU=qemu64
VIRTIO_CONSOLE=1
WORKER_CLASS=qemu_x86_64
```

Create a new job group or reuse an existing one and add the job template like this:

```
defaults:
  x86_64:
    machine: 64bit
    priority: 50
products:
  opensuse-*-DVD-x86_64:
    distri: opensuse
    flavor: DVD
    version: '*'
scenarios:
  x86_64:
    opensuse-*-DVD-x86_64:
    - directly-chained-parent
    - directly-chained-01-child
```

Schedule the job cluster, e.g.:

```
openqa-start api -X POST isos ISO=openSUSE-Tumbleweed-DVD-x86_64-Snapshot20200803-Media.iso DISTRI=opensuse ARCH=x86_64 FLAVOR=DVD VERSION=Tumbleweed BUILD=20200803
```

### Further notes

Tests with dependencies found in production also sometimes use to use the `YAML_SCHEDULE` variable, e.g.
`YAML_SCHEDULE=schedule/yast/raid/raid0_opensuse_gpt.yaml` is set as schedule for the parent and
`YAML_SCHEDULE=schedule/yast/raid/raid1_opensuse_gpt.yaml` for the child.

## Testing AMQP
1. Follow https://github.com/openSUSE/suse_msg/blob/master/amqp_infra.md#the-amqp-server to
   setup and start the AMQP server. It needs the ports 15672 and 5672.
2. Install RabbitMQ plugin required by openQA to connect to the AMQP server:
   `zypper in perl-Mojo-RabbitMQ-Client`
3. Configure openQA to connect to your AMQP server by putting the following in your `openqa.ini`:
   ```
   [global]
   plugins = AMQP
   [amqp]
   url = amqp://openqa:secret@localhost:5672
   topic_prefix = opensuse
   exchange = pubsub
   ```
FIXME: something is missing here

### Start 'suse_msg' to forward AMQP messages to IRC
1. Clone https://github.com/openSUSE/suse_msg: `git clone https://github.com/openSUSE/suse_msg.git`
2. Follow https://github.com/openSUSE/suse_msg/blob/master/README.md#testing to setup and start the script.
   Beside the mentioned adjustments to `consume.py`, also put `amqp://openqa:secret@localhost:5672` as
   server.
3. See https://github.com/openSUSE/suse_msg/blob/master/amqp_infra.md#publishing-messages for emitting
   test AMQP messages to test AMQP server and IRC forwarding.

## Adding dependencies (Perl modules, JavaScript libs, ...)
Now found within the [official documentation](http://open.qa/docs/#_handling_of_dependencies).

### Further notes regarding asset updates
If the `update-cache.sh` fails this might be due to changes in `osc`s service which the update script relies on
to download the sources. In this case adapt the script to those changes first.

## Monitor currently running job without web UI
Current `QEMU`-line:

```
xargs -0 < "/proc/$(pidof qemu-system-x86_64)/cmdline"
```

View currently running job via VNC:

```
vncviewer localhost:91 -Shared
```

## Monitoring with Telegraf/InfluxDB/Grafana

### Test Telegraf configuration

e.g. `telegraf --test --config "$OPENQA_BASEDIR/repos/openQA-helper/monitoring/telegraf-psql.conf"`

### Local setup preparations for InfluxDB and Grafana

1. Install and start services:
   ```
   sudo zypper in telegraf influxdb grafana
   sudo systemctl start influxdb grafana-server
   ```
2. Run `telegraf` without `--test` to actually populate InfluxDB
    * It will create the database on its own with the name specified in the config
    * See `monitoring/telegraf-psql.conf` for an example config with PostgreSQL
4. Access Grafana under http://localhost:3000
5. Add InfluxDB via Grafana's UI
6. Play around; an example JSON for a PostgreSQL query can be found in the `monitoring` folder
   of this repo

### Fix PostgreSQL authentification problems

If you run into trouble with ident authentification, change it to password in the config
file `/var/lib/pgsql/data/pg_hba.conf`. Be sure your user has a password, e.g. set one
via `ALTER USER user_name WITH PASSWORD 'new_password';`. Specify the password in the Telegraf
config like in the example `monitoring/telegraf-psql.conf`.

### Troubelshooting

Try a minimal config with debugging options, e.g. `telegraf --test --debug --config minimal.conf`.
If there's no error logged you can only guess what's wrong:

* DB authentification doesn't work
* Access for specific table is not granted (can be granted via `grant select on table TABLE_NAME to USER_NAME;`)

## Run aarch64 tests locally on x86_64 machine

1. Install `qemu-arm` and `qemu-uefi-aarch64` (grab the latter from http://download.opensuse.org/ports/aarch64/tumbleweed/repo/oss/noarch)
2. Setup a worker like this:
   ```
   [1234]
   BACKEND=qemu
   WORKER_CLASS=qemu_aarch64
   QEMUCPU=cortex-a57
   QEMUMACHINE=virt
   QEMU_HUGE_PAGES_PATH=
   QEMU_NO_KVM=1
   ```
3. Now simply clone an aarch64 job. When your fan speed increases it works.

---

If it does not pick up the variables ensure the pool directory is cleaned up and has not files
from previous x86_64 jobs in it.

## Test openqa-investigate against local setup

```
export dry_run=1 scheme=http host=localhost:9526
echo '1838' | ./openqa-investigate # where 1838 is a job ID
```

To log client calls, uncomment `>/dev/nul` in the `clone` function.

## Enable support for hugepages
If you get `qemu-system-aarch64: unable to map backing store for guest RAM: Cannot allocate memory`,
add `default_hugepagesz=1G hugepagesz=1G hugepages=64"` to the kernel start parameters.
When using GRUB it goes under `/etc/default/grub` and is applied via
`grub2-mkconfig -o /boot/grub2/grub.cfg`.

If you get `qemu-system-aarch64: can't open backing store /dev/hugepages/ for guest RAM: Permission denied`,
make hugepages accessible to all users, e.g. by creating/enabling a systemd service:

```
/etc/systemd/system/writable-hugepages.service
---
[Unit]
Description=Systemd service to make hugepages accessible by all users
After=dev-hugepages.mount

[Service]
Type=simple
ExecStart=/usr/bin/chmod o+w /dev/hugepages/

[Install]
WantedBy=multi-user.target
```

## Dealing with production setup

### Useful Salt commands
see https://gitlab.suse.de/openqa/salt-states-openqa#common-salt-commands-to-use

### Useful systemd commands

Take out auto-restarting workers without stopping ongoing jobs:

```
# prevent worker services from restarting
systemctl mask openqa-worker-auto-restart@{1..28}
# ensure idling worker services stop now (`--kill-who=main` ensures only the worker receives the signal and *not* isotovideo)
systemctl kill --kill-who=main --signal HUP openqa-worker-auto-restart@{1..28}
```

(see
[official documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Installing.asciidoc#stoppingrestarting-workers-without-interrupting-currently-running-jobs)
for additional info)

### View Minion dashboard from o3 workers locally
```
martchus@ariel:~> ssh -L 9530:localhost:9530 -N root@openqaworker4 # on openqa.opensuse.org (ariel)
ssh -L 9530:localhost:9530 -N openqa.opensuse.org                  # locally
```

### Reboot OSD workers via IPMI in loop
```
for run in {01..10}; do for host in QA-Power8-4-kvm.qa QA-Power8-5-kvm.qa powerqaworker-qam-1 malbec.arch grenache-1.qa; do echo -n "run: $run, $host: ping .. " && timeout -k 5 600 sh -c "until ping -c30 $host >/dev/null; do :; done" && echo -n "ok, ssh .. " && timeout -k 5 600 sh -c "until nc -z -w 1 $host 22; do :; done" && echo -n "ok, salt .. " && timeout -k 5 600 sh -c " until salt --timeout=300 --no-color $host\* test.ping >/dev/null; do :; done" && echo -n "ok, uptime/reboot: " && salt $host\* cmd.run "uptime && systemctl disable --now openqa-worker-cacheservice.service >/dev/null" && salt $host\* system.reboot 1 || break; done || break; done
```

### Show PostgreSQL table sizes

Size per table including indexes:
```
openqa=# select table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))), pg_total_relation_size(quote_ident(table_name)) from information_schema.tables where table_schema = 'public' order by 3 desc;
```

Use `pg_table_size` to exclude indexes. Use `pg_indexes_size` to show only the index size. E.g.:

```
openqa=# select table_name, pg_size_pretty(pg_table_size(quote_ident(table_name))), pg_size_pretty(pg_indexes_size(quote_ident(table_name))), pg_indexes_size(quote_ident(table_name)) from information_schema.tables where table_schema = 'public' order by 4 desc;
```

Total size, e.g. of indexes:

```
openqa=# select pg_size_pretty(sum(pg_indexes_size(quote_ident(table_name)))) from information_schema.tables where table_schema = 'public';
 pg_size_pretty
----------------
 39 GB
(1 Zeile)
```

### Run infrastructure-related scripts like in GitLab pipeline

Example:

```
cd "$OPENQA_BASEDIR/repos/grafana-webhook-actions"
docker pull $image_from_ci_config
docker images # check tag/checksum of image
docker run --rm --env EMAIL=foo --env MACHINE=bar --volume "$PWD:/pwd" a59105e4d071 /pwd/ipmi-recover-worker
```

## More scripts and documentation
* https://github.com/os-autoinst/scripts
* https://github.com/okurz/scripts - e.g.:
    * `time env runs=400 "$OPENQA_BASEDIR/repos/okurz-github-scripts/count_fail_ratio" openqa-test t/full-stack.t`
* https://kalikiana.gitlab.io/post/2021-04-27-working-with-openqa-via-the-command-line

## Environment variables for DBI(x)
* `OPENQA_SQL_DEBUG=1`: enables debug printing for DBIx queries
* `DBI_TRACE=1`: enables debug printing for all DBI queries
* `DBIC_TRACE=1`: enables debug printing for all DBIx queries

## Environment variables for Mojolicious
* MOJO_PORT
* MOJO_LOG_LEVEL
* MOJO_CLIENT_DEBUG
* MOJO_SERVER_DEBUG
* MOJO_EVENTEMITTER_DEBUG
* MOJO_IOLOOP_DEBUG
* MOJO_WEBSOCKET_DEBUG
* MOJO_PROCESS_DEBUG

Outdated but maybe still useful: https://github.com/mojolicious/mojo/wiki/%25ENV
