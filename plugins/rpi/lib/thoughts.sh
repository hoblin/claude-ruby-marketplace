thoughts_repo() {
  [[ $# -eq 0 ]] && { echo "${HOME}/thoughts"; return; }

  local target
  target="$(realpath "$1")"
  [[ -d "$target" ]] || target="$(dirname "$target")"
  git -C "$target" rev-parse --show-toplevel
}
