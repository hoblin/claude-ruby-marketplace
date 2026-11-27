thoughts_repo() {
  if [[ $# -eq 0 ]]; then
    local linked
    linked="$(git rev-parse --show-toplevel 2>/dev/null)/thoughts/shared"
    [[ -L "$linked" ]] || { echo "${HOME}/thoughts"; return; }
    set -- "$linked"
  fi

  local target
  target="$(realpath "$1")" || return
  [[ -d "$target" ]] || target="$(dirname "$target")"
  git -C "$target" rev-parse --show-toplevel
}
