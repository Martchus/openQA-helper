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

I recommend to use Tumbleweed as development system for openQA - at least when using these helpers.
It has proven to be stable enough for me. Using Leap you might miss some of the required packages.

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

### Create PostgreSQL user, maybe import some data
* See https://github.com/os-autoinst/openQA/blob/master/docs/Contributing.asciidoc#setup-postgresql
    * You can of course skip `pg_restore`. Starting with an empty database is likely sufficient for the beginning.
    * It makes sense to use a different name for the database than `openqa`. I usually use `openqa-local` and when
      importing later production data from OSD and o3 `openqa-osd` and `openqa-o3`.
* Imporing database dumps from our production instances is useful for local testing. The dumps can be
  found on wotan (not publicly accessible). Example using `sshfs`:
  ```
  mkdir -p ~/wotan && sshfs ${WOTAN_USER_NAME}@wotan.suse.de:/ ~/wotan
  ln -s ~/wotan/mounts/work_users/coolo/SQL-DUMPS $OPENQA_BASEDIR/sql-dumps-on-wotan
  ```
* Note that you'll have to migrate your database when upgrading major or minor PostgreSQL release.
  See https://www.postgresql.org/docs/8.1/static/backup.html

### Clone and configure all required repos
1. Add to `~/.bashrc` (or however I would like to add environment variables for the current user):
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
   created via the web UI (see step 7).
2. `mkdir -p $OPENQA_BASEDIR/repos; cd $OPENQA_BASEDIR/repos; git clone https://github.com/Martchus/openQA-helper.git`
3. Install all packages required for openQA development via `openqa-install-devel-deps`. This script will work only for
   openSUSE. It will also add some required repositories. Maybe you better open the script before just running it to
   be aware what it does and prevent eg. duplicated repositories.
4. Fork all required repos on GitHub:
     * [os-autoinst/os-autoinst](https://github.com/os-autoinst/os-autoinst) - "backend", the thing that starts/controls the VM
     * [os-autoinst/openQA](https://github.com/os-autoinst/openQA) - mainly the web UI, scheduler, worker and documentation
     * [os-autoinst/os-autoinst-distri-opensuse](https://github.com/os-autoinst/os-autoinst-distri-opensuse) - the actual tests (for openSUSE)
     * [os-autoinst/os-autoinst-needles-opensuse](https://github.com/os-autoinst/os-autoinst-needles-opensuse) - needles/reference images (for openSUSE)
     * I also encourage you to fork *this* repository because there's still room for improvement.
5. Execute `openqa-devel-setup your_github_name` to clone all required repos to the correct directories inside `$OPENQA_BASEDIR`. This also adds
   your forks.
6. Now you are almost done and can try to start openQA's services (see next section). Until finishing this guide, only start the web UI. It will
   initialize the database and pull required assets (e.g. jQuery) the first time you start it (so it might take some time).
7. Generate API keys and put them into your `.bashrc` to amend step 1. To generate API keys you need to access the web UI page http://localhost:9526/api_keys,
   specify an expiration date and click on "Create".
8. The openQA config files will be located under `$OPENQA_BASEDIR/config`.
    * In `worker.ini` you likely want to adjust the `HOST` to `http://localhost:9526` so the worker will directly
      connect to the web UI and websocket server (making it unnessarary to use an HTTP reverse proxy).
    * For this setup it makes most sense to set `WORKER_HOSTNAME` to `127.0.0.1` in `worker.ini`. Note that for remote workers (not covered by this setup
      guide) the variable must be set to an IP or domin which the web UI can use to connect to the worker host
      (see [official documentation](https://github.com/os-autoinst/openQA/blob/master/docs/Pitfalls.asciidoc#steps-to-debug-developer-mode-setup)).
    * Useful adjustments to the config for using the svirt backend, enable caching and profiling
      are given in the subsequent sections.
9. You can now also try to start the other services (as described in the next section) to check whether they're running. In practise I usually
   only start the services which I require right now (to keep things simple).
10. Before you can run a job you also need to build isotovideo from the sources cloned via Git in previous steps.
    To do so, just invoke `openqa-devel-maintain` (see section "Keeping repos up-to-date" for details).

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

## Keeping repos up-to-date
Just execute `openqa-devel-maintain`. If the local master or a detetched HEAD is checked out in a repository, the
script automatically resets it to the latest state on `origin`. So it is assumed that you'll never ever use the local
master or a detetched HEAD to do modifications! Configure and make are run for os-autoinst automatically.

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
# get latest docker image - here it is openqa**_dev**:latest
docker pull registry.opensuse.org/devel/openqa/containers/openqa_dev:latest

# build the docker image - here we build openqa:latest (without **_dev*)
cd "$OPENQA_BASEDIR/repos/openQA"
make docker-test-build
```

For convenience, these helper also provide the `openqa-docker-update` commands which executes the commands
above.

### Run tests
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
openqa-perl-prefix-install perltidy-new Perl::Tidy@version_number
openqa-perl-prefix-run perltidy-new tools/tidy
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
* Usually QEMU isn't used via svirt so this setup isn't well tested. When I tried it recently, the QEMU line was wrong
  preventing the system to boot from the image.

### Running a job
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

## More scripts
* https://github.com/okurz/scripts

## Environment variables for DBI(x)
* `OPENQA_SQL_DEBUG=1`: enables debug printing for DBIx queries
* `DBI_TRACE=1`: enables debug printing for all DBI queries

## Environment variables for Mojolicious
* MOJO_PORT
* MOJO_LOG_LEVEL
* MOJO_CLIENT_DEBUG
* MOJO_SERVER_DEBUG
* MOJO_EVENTEMITTER_DEBUG
* MOJO_IOLOOP_DEBUG
* MOJO_WEBSOCKET_DEBUG

Outdated but maybe still useful: https://github.com/mojolicious/mojo/wiki/%25ENV
