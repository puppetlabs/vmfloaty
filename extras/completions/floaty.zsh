_floaty()
{
  local line subcommands template_subcommands hostname_subcommands

  subcommands="delete get help list modify query revert snapshot ssh status summary token"

  template_subcommands=("get" "ssh")
  hostname_subcommands=("delete" "modify" "query" "revert" "snapshot")

  _arguments -C \
    "1: :(${subcommands})" \
    "*::arg:->args"

  if ((template_subcommands[(Ie)$line[1]])); then
    _floaty_template_sub
  elif ((hostname_subcommands[(Ie)$line[1]])); then
    _floaty_hostname_sub
  fi
}

_floaty_template_sub()
{
  if [[ -z "$_vmfloaty_avail_templates" ]] ; then
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
