# Cleanup and maintenance utilities for macOS. Bash 3.2 compatible.

_cleanup_confirm() {
  local reply
  printf '%s\n' "$1" >&2
  printf 'Type yes to continue: ' >&2
  IFS= read -r reply
  [ "$reply" = yes ] || {
    printf 'Cancelled.\n' >&2
    return 1
  }
}

_cleanup_count_dirs() {
  find "$1" -maxdepth 1 -type d -name "$2" 2>/dev/null | wc -l | tr -d ' '
}

cleanup-cache() {
  local count cache_dir

  printf 'Cache cleanup\n' >&2

  # Home cache
  if [ -d "$HOME/.cache" ]; then
    printf '  ~/.cache: will delete\n' >&2
  fi

  # Recursive cache in current directory
  count="$(_cleanup_count_dirs . ".cache")"
  if [ "$count" -gt 0 ]; then
    printf '  Found %s .cache folders in current tree\n' "$count" >&2
  fi

  _cleanup_confirm "Delete cache folders?" || return

  [ -d "$HOME/.cache" ] && rm -rf "$HOME/.cache"
  find . -type d -name ".cache" -exec rm -rf {} + 2>/dev/null || true
  printf 'Cache cleanup complete.\n'
}

cleanup-terraform() {
  local count
  count="$(_cleanup_count_dirs . ".terraform")"

  if [ "$count" -eq 0 ]; then
    printf 'No .terraform folders found.\n'
    return
  fi

  printf 'Found %s .terraform folder(s) in current tree:\n' "$count" >&2
  find . -type d -name ".terraform" -maxdepth 5 -exec printf '  %s\n' {} \; >&2

  _cleanup_confirm "Delete all .terraform folders?" || return

  find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
  printf 'Terraform cleanup complete.\n'
}

cleanup-docker() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'docker: command not found\n' >&2
    return 127
  fi

  printf 'Docker cleanup (remove unused images, containers, networks, volumes)\n' >&2
  docker system df >&2

  _cleanup_confirm "Run docker system prune -a?" || return

  docker system prune -a
}

cleanup-tmp() {
  local count

  printf 'Tmp folder cleanup\n' >&2

  if [ -d "$HOME/tmp" ]; then
    count="$(find "$HOME/tmp" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
    printf '  ~/tmp: %s files\n' "$count" >&2
  fi

  if [ -d "/tmp" ]; then
    count="$(find /tmp -maxdepth 1 -type f -mtime +7 2>/dev/null | wc -l | tr -d ' ')"
    printf '  /tmp: %s files older than 7 days\n' "$count" >&2
  fi

  _cleanup_confirm "Delete tmp files (keeps /tmp subdirs and recent files)?" || return

  [ -d "$HOME/tmp" ] && find "$HOME/tmp" -maxdepth 1 -type f -delete 2>/dev/null || true
  [ -d "/tmp" ] && find /tmp -maxdepth 1 -type f -mtime +7 -delete 2>/dev/null || true

  printf 'Tmp cleanup complete.\n'
}

app-list() {
  if ! command -v system_profiler >/dev/null 2>&1; then
    printf 'app-list: system_profiler not found (macOS only)\n' >&2
    return 1
  fi

  printf 'Installed Applications:\n\n'
  system_profiler SPApplicationsDataType | grep -E '^\s+(Location|Version):' | paste - - | \
    sed 's/Location: //' | sed 's/Version: /  v/' | sort
}

app-usage() {
  printf 'Top running processes by memory usage:\n\n'
  ps aux | sort -k 4 -rn | head -11 | tail -10 | awk '{ printf "%-8s %5s%% %7sMB %s\n", $1, $4, int($6/1024), substr($0, index($0, $11)) }'
}

schedule-task() {
  [ "$#" -ge 1 ] || {
    printf 'usage: schedule-task COMMAND [INTERVAL]\n' >&2
    printf '  COMMAND: shell command to run (quote if multiple words)\n' >&2
    printf '  INTERVAL: daily (default), hourly, weekly, or HH:MM for specific time\n' >&2
    return 2
  }

  if ! command -v launchctl >/dev/null 2>&1; then
    printf 'schedule-task: launchctl not found (macOS only)\n' >&2
    return 1
  fi

  local command="$1" interval="${2:-daily}" label plist start_time

  label="com.user.scheduled.$(printf '%s' "$command" | tr ' /' '..' | sed 's/[^a-zA-Z0-9._-]//g')"
  plist="$HOME/Library/LaunchAgents/$label.plist"

  printf 'Will schedule: %s\n' "$command" >&2
  printf 'Label: %s\n' "$label" >&2
  printf 'Plist: %s\n' "$plist" >&2
  printf 'Interval: %s\n' "$interval" >&2

  _cleanup_confirm "Create launchd agent?" || return

  mkdir -p "$HOME/Library/LaunchAgents" || return

  case "$interval" in
    daily) start_time='<key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>2</integer>
      <key>Minute</key>
      <integer>0</integer>
    </dict>' ;;
    hourly) start_time='<key>StartCalendarInterval</key>
    <dict>
      <key>Minute</key>
      <integer>0</integer>
    </dict>' ;;
    weekly) start_time='<key>StartCalendarInterval</key>
    <dict>
      <key>Weekday</key>
      <integer>0</integer>
      <key>Hour</key>
      <integer>2</integer>
      <key>Minute</key>
      <integer>0</integer>
    </dict>' ;;
    *:*) start_time="<key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key>
      <integer>${interval%%:*}</integer>
      <key>Minute</key>
      <integer>${interval##*:}</integer>
    </dict>" ;;
    *) printf 'schedule-task: invalid interval (use daily, hourly, weekly, or HH:MM)\n' >&2; return 2 ;;
  esac

  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-c</string>
    <string>$command</string>
  </array>
  $start_time
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$HOME/Library/Logs/$label.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Library/Logs/$label.err</string>
</dict>
</plist>
EOF

  chmod 644 "$plist"
  launchctl load "$plist" 2>/dev/null || {
    printf 'Loaded via launchctl. To unload later: launchctl unload %s\n' "$plist"
  }
  printf 'Scheduled. Check %s/Library/Logs/%s.log for output.\n' "$HOME" "$label"
}

cleanup-all() {
  printf 'Running all cleanup functions.\n\n'
  cleanup-cache && printf '\n'
  cleanup-terraform && printf '\n'
  cleanup-docker && printf '\n'
  cleanup-tmp && printf '\n'
  printf 'All cleanups complete.\n'
}

_cleanup_help() {
  cat <<'EOF'
System cleanup and maintenance utilities (macOS)

Cleanup functions (all prompt before making changes)
  cleanup-cache              delete ~/.cache and .cache folders recursively
  cleanup-terraform          find and delete .terraform folders in current tree
  cleanup-docker             run docker system prune -a
  cleanup-tmp                purge ~/tmp and old /tmp files
  cleanup-all                run all cleanup functions

Utilities
  app-list                   show installed applications
  app-usage                  show top running processes by file descriptors
  schedule-task CMD [WHEN]   schedule a command as a launchd agent
                             WHEN: daily (02:00), hourly, weekly, or HH:MM

Examples:
  cleanup-cache
  cleanup-terraform
  schedule-task 'brew update' daily
  schedule-task 'cleanup-all' 03:00
  schedule-task 'find ~/Downloads -mtime +30 -delete' weekly
EOF
}
