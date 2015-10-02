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

## Using the Pooler class

If you want to write some ruby scripts around the vmpooler api, vmfloaty provides a `Pooler` and `Auth` class to make things easier. The ruby script below shows off an example of a script that gets a token, grabs a vm, runs some commands through ssh, and then destroys the vm.

```ruby
require 'vmfloaty/pooler'
require 'vmfloaty/auth'
require 'io/console'
require 'net/ssh'

def aquire_token(verbose, url)
  STDOUT.flush
  puts "Enter username:"
  user = $stdin.gets.chomp
  puts "Enter password:"
  password = STDIN.noecho(&:gets).chomp
  token = Auth.get_token(verbose, url, user, password)

  puts "Your token:\n#{token}"
  token
end

def grab_vms(os_string, token, url, verbose)
  response_body = Pooler.retrieve(verbose, os_string, token, url)

  if response_body['ok'] == false
    STDERR.puts "There was a problem with your request"
    exit 1
  end

  response_body[os_string]
end

def run_puppet_on_host(hostname)
  STDOUT.flush
  puts "Enter 'root' password for vm:"
  password = STDIN.noecho(&:gets).chomp
  user = 'root'
  # run puppet
  run_puppet = "/opt/puppetlabs/puppet/bin/puppet agent -t"

  begin
    ssh = Net::SSH.start(hostname, user, :password => password)
    output = ssh.exec!(run_puppet)
    puts output
    ssh.close
  rescue
    STDERR.puts "Unable to connect to #{hostname} using #{user}"
    exit 1
  end
end

if __FILE__ == $0
  verbose = true
  url = 'https://vmpooler.mycompany.net'
  token = aquire_token(verbose, url)
  os = ARGV[0]

  hostname = grab_vm(os, token, url, verbose)
  run_puppet_on_host(hostname)
end
```

```
ruby myscript.rb centos-7-x86_64
```
