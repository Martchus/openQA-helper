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
export EXTRA_PROVE_ARGS="-v" # for verbose output of openQA's own unit tests
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
* Importing database dumps from our production instances is useful for local testing. The dumps can be
  found on `backup.qa.suse.de` (not publicly accessible). Example using `rsync`:
  ```
  rsync -aHP \
    "backup.qa.suse.de:/home/rsnapshot/alpha.0/openqa.opensuse.org/var/lib/openqa/SQL-DUMPS/$(date --date="1 day ago" +%F).dump" \
    "$OPENQA_BASEDIR/sql-dumps/openqa.opensuse.org"
  rsync -aHP \
    "backup.qa.suse.de:/home/rsnapshot/alpha.0/openqa.suse.de/var/lib/openqa/SQL-DUMPS/$(date --date="1 day ago" +%F).dump" \
    "$OPENQA_BASEDIR/sql-dumps/openqa.suse.de"
  ```
* Note that you'll have to migrate your database when upgrading major or minor PostgreSQL release.
  See https://www.postgresql.org/docs/8.1/static/backup.html and the section PostgreSQL migration on openSUSE below.

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
* `openqa-start all` - starts all daemons listed above, each in its own tab (works with Konsole and tmux)
* `openqa-start cj --from openqa.opensuse.org 1234` - clones job 1234 from o3
* `openqa-start cl ` - invokes the client with the options to connect to the local web UI
* `openqa-start cmd` - invokes the specified command on the web UI app, e.g.:
    * `openqa-start cmd eval -V 'app->schema->resultset("Jobs")->count'` - do *something* with the app/database
    * `openqa-start cmd minion job -e minion_job_name` - enqueue a Minion job
    * `openqa-start cmd eval -V 'print(app->minion->job(297)->info->{result})'` - view e.g. log of Minion job
    * `openqa-start cmd minion job -h` - view other options regarding Minion jobs

Additional parameters are simply appended to the invocation. That works of course also for `--help`.

**Note that none of these commands should to be run as root.**
Running one of these commands accidentally as root breaks the setup because then newly created files and directories are
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

### Migrating database to newer PostgreSQL version on openSUSE
See [official documentation](https://open.qa/docs/#_migrating_postgresql_database_on_opensuse).

### Move PostgreSQL database to another drive
```
src=/var/lib/pgsql dst=/hdd/pgsql
sudo systemctl stop postgresql.service
sudo usermod -d "$dst" postgres
mkdir "$dst"
sudo chown postgres:postgres "$dst"
sudo sudo -u postgres rsync -ahPHAX "$src"/ "$dst"/
sudo mv "$src"{,.bak}
sudo systemctl start postgresql.service
```

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

## Run openQA and a worker via docker-compose
If TLS is required, edit `container/webui/docker-compose.yaml` to point it to your certificate. By default, a
test certificate is used.

Edit `container/webui/conf/openqa.ini` as needed, e.g. change `[auth] method = Fake` or the logging level.

Edit `container/webui/nginx.conf` to customize the NGINX configuration.

The web UI will be available under http://localhost and https://localhost. So it is using default ports
by default. Make sure those ports are not used by another service yet or change ports in the *nginx section*
of `container/webui/docker-compose.yaml`.

Start all openQA "web UI host" services:
```
cd "$OPENQA_BASEDIR/repos/${OPENQA_CHECKOUT:-openQA}/container/webui"
docker-compose up  # maybe you need to add --build to give it a fresh build
```

Generate an API key/secret in the web UI and configure it in `container/webui/conf/client.conf` *and*
`container/worker/conf/client.conf`. Restart the web UI container to apply the configuration changes:

```
cd "$OPENQA_BASEDIR/repos/${OPENQA_CHECKOUT:-openQA}/container/webui"
docker-compose restart
```

Note that the web UI services need it as well for internal API requests.

Start a worker:
```
cd "$OPENQA_BASEDIR/repos/${OPENQA_CHECKOUT:-openQA}/container/worker"
docker-compose up  # maybe you need to add --build to give it a fresh build
```

Clone a job:
```
$OPENQA_BASEDIR/repos/openQA/script/openqa-clone-job \
    --dir $OPENQA_BASEDIR/repos/openQA/container/webui/workdir/data/factory
    --show-progress \
    --apikey $apikey --apisecret $apisecret \
    --host http://localhost \
    https://openqa.opensuse.org/tests/1896520
```

### Useful commands
* To list all launched containers and check their status use `docker-compose top`.
* Use e.g. `docker exec -it webui_websockets_1 bash` to enter any of these containers for manual investigation.
* To rebuild a container, e.g. use `docker-compose build nginx` to apply NGINX config

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

or for `Pod::AsciiDoctor` to generate documentation:
```
openqa-perl-prefix-install doc Pod::AsciiDoctor
openqa-perl-prefix-run openqa-start doc
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

## Test/run svirt and other exotic backends locally
This section has been moved to the
[official documentation](https://github.com/os-autoinst/os-autoinst/blob/master/doc/backends.md).

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
3. Optionally import production data like described in the official contributors documentation.
4. Restart the web UI, browse some pages. Profiling is done in the background.
5. Access profiling data via `/nytprof` route.

### Note
Profiling data is extensive. Use `openqa-clear-profiling-data` to get rid of it again and disable the
`profiling_enabled` configuration if not needed right now.

Keeping too much profiling data around slows down Docker startup for the testsuite significantly as it
copies all the data of your openQA repository checkout.

## Schedule jobs with dependencies locally to test dependency handling
At this point `openqa-clone-job` is able to handle any kind of dependencies just
fine. So you can use it to clone a cluster from production (instead of following
the more complicated approach mentioned in the next section).

Often those jobs cannot be executed locally because they use special backends
(e.g. IPMI) or require special setup (e.g. openvswitch). You can nevertheless
just clone a cluster and override all variables to make them regular QEMU jobs:

```
openqa-start cj --skip-download --parental-inheritance http://openqa.qam.suse.cz/tests/39746 \
  DESKTOP=minimalx SCHEDULE=tests/installation/isosize,tests/installation/bootloader_start \
  YAML_SCHEDULE=schedule/yast/raid/raid0_sle_gpt.yaml \
  ISO=openSUSE-Tumbleweed-DVD-x86_64-Snapshot20220322-Media.iso ISO_MAXSIZE=4700372992 \
  DISTRI=opensuse ARCH=x86_64 FLAVOR=DVD VERSION=Tumbleweed BUILD=20220322 \
  MAX_JOB_TIME=240 \
  WORKER_CLASS=qemu_x86_64 BACKEND=qemu
```

## Schedule jobs via "isos post" locally to test dependency handling
This example is about creating directly chained dependencies but the same applies to other dependency
types.

Usually I don't care much which exact job is being executed. In these examples I've just downloaded the
latest TW build from o3 into the `isos` directory and set `BUILD` and `ISO` accordingly. In addition, I
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

### Fix PostgreSQL authentication problems

If you run into trouble with ident authentication, change it to password in the config
file `/var/lib/pgsql/data/pg_hba.conf`. Be sure your user has a password, e.g. set one
via `ALTER USER user_name WITH PASSWORD 'new_password';`. Specify the password in the Telegraf
config like in the example `monitoring/telegraf-psql.conf`.

### Troubelshooting

Try a minimal config with debugging options, e.g. `telegraf --test --debug --config minimal.conf`.
If there's no error logged you can only guess what's wrong:

* DB authentication doesn't work
* Access for specific table is not granted (can be granted via `grant select on table TABLE_NAME to USER_NAME;`)

### Useful commands/examples
Show fields of measurement:
```
show field keys from apache_log
```

Show required disk space by measurement:
```
sudo influx_inspect report-disk -detailed /var/lib/influxdb/data > influx-disk-usage.json
jq -r '["measurement","size_gb"], (.Measurement | sort_by(.size) | reverse[] | [select(.db == "telegraf")] | map(.measurement,.size / 1024 / 1024 / 1024)) | @tsv' influx-disk-usage.json
```

Delete old data:
```
delete where time < '2019-11-22'                   # affects all data
delete from "apache_log" where time < '2020-11-22' # affects data from measurement
```

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

Modify a parameterized systemd-unit (e.g. `…@.path`) for each associated parameterized systemd-unit (e.g. `…@.service`):

```
systemctl list-units --output=json  'openqa-worker-auto-restart@*.service' | jq -r '.[] | .unit | sub("openqa-worker-";"openqa-reload-worker-") | sub(".service";".path")' | xargs systemctl enable --now
```

For all o3 workers:
```
for i in aarch64 openqaworker1 openqaworker4 openqaworker7 power8 imagetester rebel; do echo $i && ssh root@$i " systemctl list-units --output=json  'openqa-worker-auto-restart@*.service' | jq -r '.[] | .unit | sub(\"openqa-worker-\";\"openqa-reload-worker-\") | sub(\".service\";\".path\")' | xargs systemctl enable --now " ; done
```

### View Minion dashboard from o3 workers locally
```
martchus@ariel:~> ssh -L 9530:localhost:9530 -N root@openqaworker4      # on openqa.opensuse.org (ariel)
ssh -L 9530:localhost:9530 -N openqa.opensuse.org                       # locally
ssh -J openqa.opensuse.org -L 9530:localhost:9530 -N root@openqaworker5 # using the -J flag
```

### View o3 Munin dashboard locally
```
ssh  -L 8080:localhost:80 openqa.opensuse.org # locally
xdg-open http://127.0.0.1:8080/munin
```

### Delete specific Minion jobs
```
sudo -u geekotest /usr/share/openqa/script/openqa eval -V 'for (my ($jobs, $job) = app->minion->jobs({states => ["failed"], tasks => ["download_asset"]}); $job = $jobs->next;) { app->minion->job($job->{id})->remove }'
```

### Search for Minion job
```
select * from minion_jobs where args::TEXT ~ '%7275485%';
```

### Start a Minion job manually
```
sudo -u geekotest /usr/share/openqa/script/openqa minion job -e download_asset -a '["http://download.opensuse.org/repositories/Virtualization:/Appliances:/Images:/Testing_x86:/archlinux/images/kiwi-test-image-live-disk-kis.x86_64-1.0.0-Disk-Build56.8.raw.xz", "/var/lib/openqa/share/factory/hdd/kiwi-test-image-live-disk-kis.x86_64-1.0.0-Disk-Build56.8.raw", 1]'
```

### Access management interface in the new security zone
```
ssh -4 -L 8090:openqaworker4-ipmi.qe-ipmi-ur:443 -N jumpy@qe-jumpy.suse.de
```

* Edit `jviewer.jnlp` via text editor so the port matches.
* Do portscan on `qe-jumpy.suse.de` and possibly forward further ports.

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

Show usage statistics for indexes, e.g.:
```
select * from pg_stat_user_indexes where relname = 'job_settings' order by idx_scan desc;
```

Show vacuuming stats:
```
select relname,last_vacuum, last_autovacuum, last_analyze, last_autoanalyze from pg_stat_user_tables;
```

### Useful SQL queries
Job group containing a certain job template setting value:
```
select *, (select group_id from job_templates where id = job_template_id) from job_template_settings where value like '%qxl%';
```

Specific incompletes finished after some date with their workers:
```
select id, t_finished, result, reason, (select host from workers where id = assigned_worker_id) as worker from jobs where reason like '%setup exceeded MAX_SETUP_TIME%' and t_finished >= '2021-08-05T00:00:00' order by t_finished;
```

Incompletes grouped by reason:
```
select count(id), array_agg(id), reason from jobs where t_finished >= '2022-11-21T12:00:00' and result = 'incomplete' group by reason order by count(id) desc;
select count(id), substring(reason from 0 for 30) as reason_substr from jobs where t_finished = '2023-05-14T00:04:00' and result = 'incomplete' group by reason_substr order by count(id) desc;
```

Incompletes on a specific worker host:
```
select id, t_finished, result, reason from jobs where (select host from workers where id = assigned_worker_id) = 'openqaworker13' and result = 'incomplete' and t_finished >= '2021-08-24T00:00:00' order by t_finished;
```

Worker hosts and their online slot count and processed assets and jobs as of some date:
```
select host, count(id) as online_slots, (select array[((select sum(size) from assets where id = any(array_agg(distinct jobs_assets.asset_id))) / 1024 / 1024 / 1024), count(distinct id)] from jobs join jobs_assets on jobs.id = jobs_assets.job_id where assigned_worker_id = any(array_agg(w.id)) and t_finished >= '2021-08-06T00:00:00') as recent_asset_size_in_gb_and_job_count from workers as w where t_updated > (timezone('UTC', now()) - interval '1 hour') group by host order by recent_asset_size_in_gb_and_job_count desc;
```

Recently abandoned jobs by worker host (total count and per hour):
```
select host, count(id) as online_slots, (select array[count(distinct id), count(distinct id) / (extract(epoch FROM (timezone('UTC', now()) - '2021-08-12T00:00:00')) / 3600)] from jobs join jobs_assets on jobs.id = jobs_assets.job_id where assigned_worker_id = any(array_agg(w.id)) and t_finished >= '2021-08-12T00:00:00' and reason like '%abandoned: associated worker%') as recently_abandoned_jobs_total_and_per_hour from workers as w where t_updated > (timezone('UTC', now()) - interval '1 hour') group by host order by recently_abandoned_jobs_total_and_per_hour desc;
```

Scheduled jobs which have been restarted:
```
select count(j1.id) from jobs as j1 where state = 'scheduled' and (select j2.id from jobs as j2 where j1.id = j2.clone_id limit 1) is not null;
```

Ratio of job results within a certain set of jobs (here jobs with parallel dependencies or jobs of a specific build):
```
with mm_jobs as (select distinct id, result from jobs left join job_dependencies on (id = child_job_id or id = parent_job_id) where dependency = 2) select result, count(id) * 100. / (select count(id) from mm_jobs) as ratio from mm_jobs group by mm_jobs.result order by ratio desc;
with test_jobs as (select distinct id, state, result from jobs where build = 'test-arm4-3') select state, result, count(id) * 100. / (select count(id) from test_jobs) as ratio from test_jobs group by test_jobs.state, test_jobs.result order by ratio desc;
```

Change of overall fail ratio within a set of jobs:
```
with finished as (select result, t_finished from jobs where arch='s390x') select (extract(YEAR from t_finished)) as year, (extract(MONTH from t_finished)) as month, round(count(*) filter (where result = 'failed' or result = 'incomplete') * 100. / count(*), 2)::numeric(5,2)::float as ratio_of_all_failures_or_incompletes, count(*) total from finished where t_finished >= '2020-01-01' group by year, month order by year, month asc;
openqa=> with finished as (select result, t_finished from jobs) select (extract(YEAR from t_finished)) as year, (extract(MONTH from t_finished)) as month, (extract(DAY from t_finished)) as day, round(count(*) filter (where result = 'failed' or result = 'incomplete') * 100. / count(*), 2)::numeric(5,2)::float as ratio_of_all_failures_or_incompletes, count(*) total from finished where t_finished >= '2022-05-01' group by year, month, day order by year, month, day asc;
```

Change of ratio of specific job failures grouped by month (here jobs with a specific reason *within* failing/incompleting jobs of a specific arch):
```
with finished as (select result, reason, t_finished from jobs where arch='s390x' and (result='failed' or result='incomplete')) select (extract(YEAR from t_finished)) as year, (extract(MONTH from t_finished)) as month, round(count(*) filter (where reason like '%Error connecting to VNC server%') * 100. / count(*), 2)::numeric(5,2)::float as ratio_of_vnc_issues, count(*) total from finished where t_finished >= '2021-01-01' group by year, month order by year, month asc;
```


Fail/incomplete ratio of jobs on selected worker hosts:
```
with finished as (select result, t_finished, host from jobs left join workers on jobs.assigned_worker_id = workers.id where result != 'none') select host, round(count(*) filter (where result='failed' or result='incomplete') * 100. / count(*), 2)::numeric(5,2)::float as ratio_failed_by_host, count(*) total from finished where host like '%-arm-%' and t_finished >= '2022-04-22' group by host order by ratio_failed_by_host desc;
```

Recent job results with a certain setting:
```
select job_id, value, (select result from jobs where id = job_id) from job_settings where key = 'UEFI_PFLASH_VARS' and value like '%ovmf%' order by job_id desc limit 50;
```

Resolve chain of ID/relations recursively:
```
with recursive orig_id as (select 2301 as orig_id, 1 as level union all select id as orig_id, orig_id.level + 1 as level from jobs join orig_id on orig_id.orig_id = jobs.clone_id and level < 50) select orig_id, level from orig_id;
with recursive orig_id as (select 2301 as orig_id, 1 as level union all select id as orig_id, orig_id.level + 1 as level from jobs join orig_id on orig_id.orig_id = jobs.clone_id) select level from orig_id order by level desc limit 1;
```

Search within JSON columns:
```
select id as error from scheduled_products where results ->> 'error' like '%unique constraint%' order by id desc limit 10;
select id from scheduled_products where settings ->> 'GITHUB_SHA' = '37d3c48c4c13eebcc8bb2bf14b9e1a6988fd86c5' order by id desc limit 10;
```

* `data -> 'foo'`: accesses a field keeping it JSON
* `data ->> 'foo'`: accesses a field turning it into text
* `CAST (data ->> 'foo' AS INTEGER)`: accesses a field turning it into a certain type

JSON-array length:

```
select id, t_created, t_updated, jsonb_array_length(results -> 'failed_job_info') as failed_jobs from scheduled_products where jsonb_array_length(results -> 'failed_job_info') > 0 order by id desc limit 50;
```

Example for exporting job IDs from a query and using them in another command:
```
\copy (select distinct jobs.id from jobs join job_settings on jobs.id = job_settings.job_id left join job_dependencies on (jobs.id = child_job_id or jobs.id = parent_job_id) where dependency != 2 and result = 'passed' and job_settings.key = 'WORKER_CLASS' and job_settings.value = 'qemu_aarch64' order by id desc limit 100) to '/tmp/jobs_to_clone_arm' csv;
```

```
for job_id in $(cat /tmp/jobs_to_clone_arm) ; do openqa-clone-job --host https://openqa.suse.de --skip-download --skip-chained-deps --clone-children --parental-inheritance "https://openqa.suse.de/tests/$job_id" _GROUP=0 TEST+=-arm4-test BUILD=test-arm4 WORKER_CLASS=openqaworker-arm-4 ; done
for i in $(cat /tmp/failed_parallel_jobs); do sudo openqa-cli api --host "openqa.suse.de" -X POST jobs/"$i"/restart ; done
```

Failing jobs with parallel dependencies:
```
select id, parents.parent_job_id as parallel_parent, children.child_job_id as parallel_child from jobs left join job_dependencies as parents on jobs.id = parents.child_job_id left join job_dependencies as children on jobs.id = children.parent_job_id where clone_id is null and t_finished > '2022-11-09' and result = 'failed' and (parents.dependency = 2 or children.dependency = 2) order by id desc;
```

### UEFI boot via iPXE
See our
[Wiki](https://progress.opensuse.org/projects/openqav3/wiki/Wiki#Setup-guide-for-new-machines)
for a more verbose and o3-specific documentation. (The documentation here is rather terse.)

---

Configure `/etc/dnsmasq.d/pxeboot.conf`:

```
enable-tftp
tftp-root=/srv/tftpboot
pxe-prompt="Press F8 for menu. foobar", 10
dhcp-match=set:efi-x86_64,option:client-arch,7
dhcp-match=set:efi-x86_64,option:client-arch,9
dhcp-match=set:efi-x86,option:client-arch,6
dhcp-match=set:bios,option:client-arch,0
#dhcp-boot=tag:efi-x86_64,with/to/image
```

Provide config, build image, deploy image:
```
# make file that contains the iPXE commands to boot available via some http server, file contents for installing Leap 15.4 with autoyast:
#!ipxe
kernel http://download.opensuse.org/distribution/leap/15.4/repo/oss/boot/x86_64/loader/linux initrd=initrd console=tty0 console=ttyS1,115200 install=http://download.opensuse.org/distribution/leap/15.4/repo/oss/ autoyast=http://martchus.no-ip.biz/ipxe/ay-openqa-worker.xml rootpassword=…
initrd http://download.opensuse.org/factory/repo/oss/boot/x86_64/loader/initrd
boot

# setup build of iPXE UEFI image like explained on https://en.opensuse.org/SDB:IPXE_booting#Setup
git clone https://github.com/ipxe/ipxe.git
cd ipxe
echo "#!ipxe
dhcp
chain http://martchus.no-ip.biz/ipxe/leap-15.4" > myscript.ipxe
cd src

# conduct build similar to https://github.com/archlinux/svntogit-community/blob/packages/ipxe/trunk/PKGBUILD#L58
make EMBED=../myscript.ipxe NO_WERROR=1 bin/ipxe.lkrn bin/ipxe.pxe bin-i386-efi/ipxe.efi bin-x86_64-efi/ipxe.efi

# copy image to production host
rsync bin-x86_64-efi/ipxe.efi openqa.opensuse.org:/home/martchus/ipxe.efi

# use image on production host
sudo cp /home/martchus/ipxe.efi /srv/tftpboot/ipxe-own-build/ipxe.efi
```

### Useful commands for dealing with HMC managed machines
The following commmands can be used by connecting to the HMC via SSH (using the same credentials as on the
HMC web UI):

```
export MACHINE=qa-power8
lssyscfg -m $MACHINE  -r lpar -F name,lpar_id,state --header # list partitions and virtual I/O servers
mkvterm -m $MACHINE -p testvm                                # enter terminal on a partition
chsysstate -m $MACHINE -r lpar -n testvm -o on -b sms        # turn partition on
chsysstate -m $MACHINE -r lpar -n testvm -o shutdown --immed # turn partition off
```

### Profiling expensive SQL queries via PostgreSQL extension
#### Setup
1. Configure `pg_statements`, see example on https://www.postgresql.org/docs/current/pgstatstatements.html.
2. Ensure contrib package (e.g. `postgresql14-contrib`) is installed.
3. Restart PostgreSQL.
4. Enable the extension via `CREATE EXTENSION pg_stat_statements`.

#### Useful queries
Use `\x` in `psql` for extended mode.

List similar, most time-consuming queries:
```
SELECT substring(query from 0 for 250) as query_start, sum(calls) as calls, max(max_exec_time) as met, sum(total_exec_time) as tet, sum(rows) as rows FROM pg_stat_statements group by query_start ORDER BY tet DESC LIMIT 10;
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
* MOJO_MAX_MESSAGE_SIZE (https://docs.mojolicious.org/Mojo/Message#max_message_size)
* MOJO_MAX_BUFFER_SIZE (https://docs.mojolicious.org/Mojo/Content#max_buffer_size)
* MOJO_MAX_LINE_SIZE (https://docs.mojolicious.org/Mojo/Message#max_line_size)

Outdated but maybe still useful: https://github.com/mojolicious/mojo/wiki/%25ENV

## Issues/workarounds
* https://github.com/pjcj/Devel--Cover/issues/292
