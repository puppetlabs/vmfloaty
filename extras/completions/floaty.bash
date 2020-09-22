#!/usr/bin/env bash

_vmfloaty()
{
  local cur prev commands template_arg_commands hostname_arg_commands service_subcommands

  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="delete get help list modify query revert service snapshot ssh status summary token"
  template_arg_commands="get ssh"
  hostname_arg_commands="delete modify query revert snapshot"
  service_subcommands="types examples"

  if [[ $cur == -* ]] ; then
    # TODO: option completion
    COMPREPLY=()
  elif [[ $template_arg_commands =~ (^| )$prev($| ) ]] ; then
    if [[ -z "$_vmfloaty_avail_templates" ]] ; then
      # TODO: need a --hostnameonly equivalent here because the section headers of
      # `floaty list` are adding some spurious entries (including files in current
      # directory because part of the headers is `**` which is getting expanded)
      _vmfloaty_avail_templates=$(floaty list 2>/dev/null)
    fi

    COMPREPLY=( $(compgen -W "${_vmfloaty_avail_templates}" -- "${cur}") )
  elif [[ $hostname_arg_commands =~ (^| )$prev($| ) ]] ; then
    _vmfloaty_active_hostnames=$(floaty list --active --hostnameonly 2>/dev/null)
    COMPREPLY=( $(compgen -W "${_vmfloaty_active_hostnames}" -- "${cur}") )
  elif [[ "service" == $prev ]] ; then
    COMPREPLY=( $(compgen -W "${service_subcommands}" -- "${cur}") )
  elif [[ $1 == $prev ]] ; then
    # only show top level commands we are at root
    COMPREPLY=( $(compgen -W "${commands}" -- "${cur}") )
  fi
}
complete -F _vmfloaty floaty
