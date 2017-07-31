#!/usr/bin/env bash

_vmfloaty()
{
  local cur prev subcommands template_subcommands hostname_subcommands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  subcommands="delete get help list modify query revert snapshot ssh status summary token"
  template_subcommands="get ssh"
  hostname_subcommands="delete modify query revert snapshot"

  if [[ $cur == -* ]] ; then
    # TODO: option completion
    COMPREPLY=()
  elif [[ $template_subcommands =~ (^| )$prev($| ) ]] ; then
    if [[ -z "$_vmfloaty_avail_templates" ]] ; then
      _vmfloaty_avail_templates=$(floaty list 2>/dev/null)
    fi

    COMPREPLY=( $(compgen -W "${_vmfloaty_avail_templates}" -- "${cur}") )
  elif [[ $hostname_subcommands =~ (^| )$prev($| ) ]] ; then
    _vmfloaty_active_hostnames=$(floaty list --active 2>/dev/null | grep '^-' | cut -d' ' -f2)
    COMPREPLY=( $(compgen -W "${_vmfloaty_active_hostnames}" -- "${cur}") )
  else
    COMPREPLY=( $(compgen -W "${subcommands}" -- "${cur}") )
  fi
}
complete -F _vmfloaty floaty
