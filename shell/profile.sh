# Shell entrypoint. Generic aliases/functions live in aliases.sh and functions.sh.
# Kubernetes commands, aliases, and the `k` dispatcher live in kubernetes.sh.
# Cleanup and maintenance utilities live in cleanup.sh.
# AWS CLI helpers live in aws.sh.
# Personal, machine-specific values belong in ~/.config/settings/local.sh (not this repo).

_settings_shell_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$_settings_shell_dir/aliases.sh"
. "$_settings_shell_dir/functions.sh"
. "$_settings_shell_dir/kubernetes.sh"
. "$_settings_shell_dir/cleanup.sh"
. "$_settings_shell_dir/aws.sh"
unset _settings_shell_dir
