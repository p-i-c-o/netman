# bash completion for netman
_netman_completion() {
  local cur prev
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local cmds="set list edit create rollback --test --json --help -h"
  local profiles
  profiles="$(command netman list 2>/dev/null)"

  if [[ "$prev" == "set" || "$prev" == "edit" ]]; then
    COMPREPLY=( $(compgen -W "$profiles" -- "$cur") )
    return 0
  fi

  if [[ "$prev" == "create" ]]; then
    return 0
  fi

  if [[ "$prev" == "--dns" || "$prev" == "--subnet" ]]; then
    return 0
  fi

  COMPREPLY=( $(compgen -W "$cmds" -- "$cur") )
}

complete -F _netman_completion netman ./netman
