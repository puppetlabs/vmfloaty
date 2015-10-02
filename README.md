vmfloaty
========

A CLI helper tool for [Puppet Labs vmpooler](https://github.com/puppetlabs/vmpooler) to help you stay afloat.

<img src="http://i.imgur.com/xGcGwuH.jpg" width=200 height=200>

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
    modify   Modify a vms tags and TTL
    query    Get information about a given vm
    revert   Reverts a vm to a specified snapshot
    snapshot Takes a snapshot of a given vm
    status   Prints the status of vmpooler
    summary  Prints the summary of vmpooler
    token    Retrieves or deletes a token

  GLOBAL OPTIONS:

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs
```

### Example workflow

Grabbing a token for authenticated pooler requests:

```
floaty token get --user me --url https://vmpooler.mycompany.net
```

This command will then ask you to log in. If successful, it will return a token that you can save either in a dotfile or use with other cli commands.

Grabbing vms:

```
floaty get centos-7,debian-7,windows-10 --token mytokenstring --url https://vmpooler.mycompany.net
```

### vmfloaty dotfile

If you do not wish to continuely specify various config options with the cli, you can have a dotfile in your home directory for some defaults. For example:

```yaml
#file at /Users/me/.vmfloaty.yml
url: 'http://vmpooler.mycompany.net'
user: 'brian'
token: 'tokenstring'
```

Now vmfloaty will use those config files if no flag was specified.

#### Valid config keys

Here are the keys that vmfloaty currently supports:

- verbose
  + true
  + false
- token
  + :token-string
- user
  + :username
- url
  + :pooler-url

## vmpooler API

This cli tool uses the [vmpooler API](https://github.com/puppetlabs/vmpooler/blob/master/API.md).
