vmfloaty
========

A CLI helper tool for Puppet Labs vmpooler to help you stay afloat.

_NOTE:_ Hack day(s?) project... we'll see where this goes :)

## Install

__note:__ this doesn't work yet. Have not published this to ruby gems

```
gem install vmfloaty
```

## Usage

_note:_ subject to change

```
Commands:
  floaty get <OPERATING SYSTEM,...> [--withpe version]  # Gets a VM
  floaty help [COMMAND]                                 # Describe available commands or one specific command
  floaty list [PATTERN]                                 # List all open VMs
  floaty modify <HOSTNAME>                              # Modify a VM
  floaty release <HOSTNAME>                             # Schedules a VM for deletion
  floaty status                                         # List status of all active VMs
```
