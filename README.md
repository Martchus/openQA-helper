# openQA helper
Scripts and (a little bit) documentation to ease openQA development.

Note this aims to get a development setup where everything is started as your regular
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
* `cd $OPENQA_BASEDIR/repos; git checkout https://github.com/Martchus/openQA-helper.git`
* Install all packages required for openQA development via `openqa-install-devel-deps`.
* Fork all required repos on GitHub. For the list of repos, just checkout the
  `openqa-devel-setup your_github_name` script.
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
### Prepare running tests via Docker
```
sudo zypper in docker
```

Customize path for Docker stuff (I don't want it on the SSD):
```
SYSTEMD_EDITOR=/bin/vim sudo -E systemctl edit docker.service

[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --containerd /run/containerd/containerd.sock --add-runtime oci=/usr/sbin/docker-runc --data-root=/hdd/docker $DOCKER_NETWORK_OPTIONS $DOCKER_OPTS
```

```
sudo systemctl start docker.service
sudo docker pull dasantiago/openqa-tests
```

### Run tests
```
openqa-docker-test

# pass env vars, eg. to run fullstack test
openqa-docker-test -e FULLSTACK=1
openqa-docker-test -e DEVELOPER_FULLSTACK=1

# expose ports
# FIXME: not working for me
openqa-docker-test -e MOJO_PORT=12345 -p 12345-12347:12345-12347

# non-headless mode
# FIXME: not working for me
openqa-docker-test -e NOT_HEADLESS=1 -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix

# set custom container name
export CONTAINER_NAME=the-other-testrun
```

### Enter container with Bash
```
sudo docker exec -it openqa-testsuite bash
```

### Stop test again, get rid of container
```
sudo docker stop openqa-testsuite
sudo docker container rm openqa-testsuite
```

## More scripts
* https://github.com/okurz/scripts