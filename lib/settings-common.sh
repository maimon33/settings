#!/usr/bin/env bash

settings_repo() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

settings_config_dir() { printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/settings-manager"; }
settings_state_dir() { printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/settings-manager"; }

settings_log() {
  local state_dir
  state_dir="$(settings_state_dir)"
  mkdir -p "$state_dir"
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$state_dir/activity.log"
}

settings_load_env() {
  local env_file
  env_file="$(settings_config_dir)/settings.env"
  [ -r "$env_file" ] && . "$env_file"
  : "${BACKUP_DESTINATION:=${XDG_STATE_HOME:-$HOME/.local/state}/settings-manager/backups}"
  : "${BACKUP_RETENTION_DAYS:=30}"
}
