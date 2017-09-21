vmfloaty
========

[![Gem Version](https://badge.fury.io/rb/vmfloaty.svg)](https://badge.fury.io/rb/vmfloaty) [![Build Status](https://travis-ci.org/briancain/vmfloaty.svg?branch=master)](https://travis-ci.org/briancain/vmfloaty)

A CLI helper tool for [Puppet Labs vmpooler](https://github.com/puppetlabs/vmpooler) to help you stay afloat.

<img src="http://i.imgur.com/xGcGwuH.jpg" width=200 height=200>

This project is still supported by @briancain and @demophoon. Ping either of us if you'd like something merged and released.

## Install

Grab the latest from ruby gems...

```
$ gem install vmfloaty
...
...
$ floaty --help
```

## Usage

```
    delete   Schedules the deletion of a host or hosts
    get      Gets a vm or vms based on the os argument
    help     Display global or [command] help documentation
    list     Shows a list of available vms from the pooler or vms obtained with a token
    modify   Modify a vms tags, time to live, and disk space
    query    Get information about a given vm
    revert   Reverts a vm to a specified snapshot
    snapshot Takes a snapshot of a given vm
    ssh      Grabs a single vm and sshs into it
    status   Prints the status of pools in vmpooler
    summary  Prints a summary of vmpooler
    token    Retrieves or deletes a token or checks token status

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
floaty token get --user username --url https://vmpooler.mycompany.net/api/v1
```

This command will then ask you to log in. If successful, it will return a token that you can save either in a dotfile or use with other cli commands.

Grabbing vms:

```
floaty get centos-7-x86_64=2 debian-7-x86_64 windows-10=3 --token mytokenstring --url https://vmpooler.mycompany.net/api/v1
```

### vmfloaty dotfile

If you do not wish to continuely specify various config options with the cli, you can have a dotfile in your home directory for some defaults. For example:

```yaml
#file at /Users/me/.vmfloaty.yml
url: 'https://vmpooler.mycompany.net/api/v1'
user: 'brian'
token: 'tokenstring'
```

Now vmfloaty will use those config files if no flag was specified.

#### Valid config keys

Here are the keys that vmfloaty currently supports:

- verbose
  + Boolean
- token
  + String
- user
  + String
- url
  + String

### Tab Completion

There is a basic completion script for Bash (and possibly other shells) included with the gem in the [extras/completions](https://github.com/briancain/vmfloaty/blob/master/extras/completions) folder. To activate, that file simply needs to be sourced somehow in your shell profile.

For convenience, the path to the completion script for the currently active version of the gem can be found with the `floaty completion` subcommand. This makes it easy to add the completion script to your profile like so:

```bash
source $(floaty completion --shell bash)
```

If you are running on macOS and use Homebrew's `bash-completion` formula, you can symlink the script to `/usr/local/etc/bash_completion.d/floaty` and it will be sourced automatically:

```bash
ln -s $(floaty completion --shell bash) /usr/local/etc/bash_completion.d/floaty
```

## vmpooler API

This cli tool uses the [vmpooler API](https://github.com/puppetlabs/vmpooler/blob/master/API.md).

## Using the Pooler class

vmfloaty providers a `Pooler` class that gives users the ability to make requests to vmpooler without having to write their own requests. It also provides an `Auth` class for managing vmpooler tokens within your application.

### Example Projects

- [John McCabe: vmpooler-bitbar](https://github.com/johnmccabe/vmpooler-bitbar/)
  + vmpooler status and management in your menubar with bitbar
- [Brian Cain: vagrant-vmpooler](https://github.com/briancain/vagrant-vmpooler)
  + Use Vagrant to manage your vmpooler instances
