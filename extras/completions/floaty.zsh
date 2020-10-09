_floaty()
{
  local line commands template_arg_commands hostname_arg_commands service_subcommands

  commands="delete get help list modify query revert service snapshot ssh status summary token"

  template_arg_commands=("get" "ssh")
  hostname_arg_commands=("delete" "modify" "query" "revert" "snapshot")
  service_subcommands=("types" "examples")

  _arguments -C \
    "1: :(${commands})" \
    "*::arg:->args"

  if ((template_arg_commands[(Ie)$line[1]])); then
    _floaty_template_sub
  elif ((hostname_arg_commands[(Ie)$line[1]])); then
    _floaty_hostname_sub
  elif [[ "service" == $line[1] ]]; then
    _arguments "1: :(${service_subcommands})"
  fi
}

_floaty_template_sub()
{
  if [[ -z "$_vmfloaty_avail_templates" ]] ; then
    # TODO: need a --hostnameonly equivalent here because the section headers of
    # `floaty list` are adding some spurious entries (including files in current
    # directory because part of the headers is `**` which is getting expanded)
    _vmfloaty_avail_templates=$(floaty list 2>/dev/null)
  fi

  _arguments "1: :(${_vmfloaty_avail_templates})"
}

_floaty_hostname_sub()
{
  _vmfloaty_active_hostnames=$(floaty list --active --hostnameonly 2>/dev/null)

  _arguments "1: :(${_vmfloaty_active_hostnames})"
}

compdef _floaty floaty
