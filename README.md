vmfloaty
========

A CLI helper tool for Puppet Labs vmpooler to help you stay afloat.

## Install

Grab the latest from ruby gems...

```
gem install vmfloaty
```

## Usage

_note:_ subject to change

```
Commands:
  floaty get <OPERATING SYSTEM,...>      # Gets a VM
  floaty help [COMMAND]                  # Describe available commands or one specific command
  floaty list [PATTERN]                  # List all open VMs
  floaty modify <HOSTNAME>               # Modify a VM
  floaty release <HOSTNAME,...> [--all]  # Schedules a VM for deletion
  floaty status                          # List status of all active VMs
```
