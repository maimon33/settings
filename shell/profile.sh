# Shell entrypoint. Add shared aliases to aliases.sh and functions to functions.sh.
# Personal, machine-specific values belong in ~/.config/settings/local.sh (not this repo).

_settings_shell_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$_settings_shell_dir/aliases.sh"
. "$_settings_shell_dir/functions.sh"
unset _settings_shell_dir
