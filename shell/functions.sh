# Functions shared by every machine using this repository.
md() {
  mkdir -p -- "$1" && cd -- "$1"
}

settings-edit-local() {
  "${EDITOR:-vi}" "$HOME/.config/settings/local.sh"
}

settings-sync() {
  local repo="${SETTINGS_REPO:-$HOME/settings}"
  git -C "$repo" pull --ff-only && . "$HOME/.config/settings/profile.sh"
}
