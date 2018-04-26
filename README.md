# openQA helper
Scripts and documentation to ease openQA development.

## Setup guide: clone and configure all required repos
* Add to `~/.bashrc`:

``` 
export OPENQA_BASEDIR=/hdd/openqa-devel
export OPENQA_CONFIG=$OPENQA_BASEDIR/config
export DBUS_STARTER_BUS_TYPE=session
export PATH="$PATH:/usr/lib64/chromium:/hdd/openqa-devel/repos/openQA-helper/scripts"
#export OPENQA_SQL_DEBUG=true
```

* Install all packages required for openQA development via `openqa-install-devel-deps`.

* Fork all required repos on GitHub. For the list of repos, just checkout the
  `openqa-devel-setup your_github_name` script.

* Execute `openqa-devel-setup your_github_name` to clone all required repos. This also adds your
  forks.

## Switching between databases conveniently
* Create files similar to the ones found under `example-config`.
* Don't change the pattern used for the filenames.
* Use eg. `openqa-switchdb osd` to activate the configuration `database-osd.ini`.
