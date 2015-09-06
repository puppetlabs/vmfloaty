vmfloaty
========

A CLI helper tool for Puppet Labs vmpooler to help you stay afloat.

## Install

Grab the latest from ruby gems...

```
gem install vmfloaty
```

## Usage

```
    delete   Schedules the deletion of a host or hosts
    get      Gets a vm or vms based on the os flag
    help     Display global or [command] help documentation
    list     Shows a list of available vms from the pooler
    modify
    query
    revert
    snapshot
    status   Prints the status of vmpooler
    summary  Prints the summary of vmpooler

  GLOBAL OPTIONS:

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs
```

### vmfloaty dotfile

If you do not wish to continuely specify various config options with the cli, you can have a dotfile in your home directory for some defaults. For example:

```yaml
#file at /Users/me/.vmpooler.yml
url: 'http://vmpooler.mycompany.net'
user: 'brian'
```

Now vmfloaty will use those config files if no flag was specified.
