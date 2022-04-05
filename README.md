# vmfloaty

[![Gem Version](https://badge.fury.io/rb/vmfloaty.svg)](https://badge.fury.io/rb/vmfloaty)
[![CI](https://github.com/puppetlabs/vmfloaty/actions/workflows/ci.yml/badge.svg)](https://github.com/puppetlabs/vmfloaty/actions/workflows/ci.yml)

A CLI helper tool for [Puppet's VMPooler](https://github.com/puppetlabs/vmpooler) to help you stay afloat.

![float image](float.jpg)

- [Install](#install)
- [Usage](#usage)
  - [Example workflow](#example-workflow)
  - [vmfloaty dotfile](#vmfloaty-dotfile)
    - [Basic configuration](#basic-configuration)
    - [Using multiple services](#using-multiple-services)
    - [Using backends besides VMPooler](#using-backends-besides-vmpooler)
    - [Valid config keys](#valid-config-keys)
  - [Tab Completion](#tab-completion)
- [VMPooler API](#vmpooler-api)
- [Using the Pooler class](#using-the-pooler-class)
  - [Example Projects](#example-projects)
- [Contributing](#contributing)
  - [Code Reviews](#code-reviews)
- [Releasing](#releasing)
- [Special thanks](#special-thanks)

## Install

Grab the latest from ruby gems...

```bash
gem install vmfloaty
```

## Usage

```plain
$ floaty --help
  NAME:

    floaty

  DESCRIPTION:

    A CLI helper tool for Puppet's VMPooler to help you stay afloat

  COMMANDS:

    completion Outputs path to completion script
    delete     Schedules the deletion of a host or hosts
    get        Gets a vm or vms based on the os argument
    help       Display global or [command] help documentation
    list       Shows a list of available vms from the pooler or vms obtained with a token
    modify     Modify a VM's tags, time to live, disk space, or reservation reason
    query      Get information about a given vm
    revert     Reverts a vm to a specified snapshot
    service    Display information about floaty services and their configuration
    snapshot   Takes a snapshot of a given vm
    ssh        Grabs a single vm and sshs into it
    status     Prints the status of pools in the pooler service
    summary    Prints a summary of a pooler service
    token      Retrieves or deletes a token or checks token status

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

```bash
floaty token get --user username --url https://vmpooler.example.net/api/v1
```

This command will then ask you to log in. If successful, it will return a token that you can save either in a dotfile or use with other cli commands.

Grabbing vms:

```bash
floaty get centos-7-x86_64=2 debian-7-x86_64 windows-10=3 --token mytokenstring --url https://vmpooler.example.net/api/v1
```

### vmfloaty dotfile

If you do not wish to continually specify various config options with the cli, you can `~/.vmfloaty.yml` for some defaults. You can get a list of valid service types and example configuration files via `floaty service types` and `floaty service examples`, respectively.

#### Basic configuration

This is the simplest type of configuration where you only need a single service:

```yaml
# file at ~/.vmfloaty.yml
url: 'https://vmpooler.example.net/api/v1'
user: 'brian'
token: 'tokenstring'
```

Run `floaty service examples` to see additional configuration options

#### Using multiple services

Most commands allow you to specify a `--service <servicename>` option to allow the use of multiple pooler instances. This can be useful when you'd rather not specify a `--url` or `--token` by hand for alternate services.

- If you run `floaty` without a `--service <name>` option, vmfloaty will use the first configured service by default.
- If keys are missing for a configured service, vmfloaty will attempt to fall back to the top-level values.
  This makes it so you can specify things like `user` once at the top of your `~/.vmfloaty.yml`.

#### Using backends besides VMPooler

vmfloaty supports additional backends besides VMPooler. To see a complete list, run `floaty service types`. The output of `floaty service examples` will show you how to configure each of the supported backends.

#### Valid config keys

Here are the keys that vmfloaty currently supports:

- verbose (Boolean)
- token (String)
- user (String)
- url (String)
- services (String)
- type (String)
- vmpooler_fallback (String)

### Tab Completion

There is a basic completion script for Bash (and possibly other shells) included with the gem in the [extras/completions](https://github.com/puppetlabs/vmfloaty/blob/master/extras/completions) folder. To activate, that file simply needs to be sourced somehow in your shell profile.

For convenience, the path to the completion script for the currently active version of the gem can be found with the `floaty completion` subcommand. This makes it easy to add the completion script to your profile like so:

```bash
source $(floaty completion --shell bash)
```

If you are running on macOS and use Homebrew's `bash-completion` formula, you can symlink the script to `/usr/local/etc/bash_completion.d/floaty` and it will be sourced automatically:

```bash
ln -s $(floaty completion --shell bash) /usr/local/etc/bash_completion.d/floaty
```

There is also tab completion for zsh:

```zsh
source $(floaty completion --shell zsh)
```

## VMPooler API

This cli tool uses the [VMPooler API](https://github.com/puppetlabs/vmpooler/blob/master/API.md).

## Using the Pooler class

vmfloaty providers a `Pooler` class that gives users the ability to make requests to VMPooler without having to write their own requests. It also provides an `Auth` class for managing VMPooler tokens within your application.

### Example Projects

- [John McCabe: vmpooler-bitbar](https://github.com/johnmccabe/vmpooler-bitbar/)
  - vmpooler status and management in your menubar with bitbar
- [Brian Cain: vagrant-vmpooler](https://github.com/briancain/vagrant-vmpooler)
  - Use Vagrant to manage your vmpooler instances

## Contributing

PR's are welcome! We always love to see how others think this tool can be made better.

### Code Reviews

Please wait for multiple code owners to sign off on any notable change.

## Releasing

Releasing is a two step process:

1. Submit a release prep PR that updates `lib/vmfloaty/version.rb` to the desired new version and get that merged
2. Navigate to <https://github.com/puppetlabs/vmfloaty/actions/workflows/release.yml> --> Run workflow --> select "main" branch --> Run workflow. This will publish a GitHub release, build, and push the gem to RubyGems.

## Special thanks

Special thanks to [Brian Cain](https://github.com/briancain) as he is the original author of vmfloaty! Vast amounts of this code exist thanks to his efforts.
