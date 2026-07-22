# Aliases shared by every machine using this repository.
alias c='clear'
alias h='history'
alias ll='ls -la'
alias la='ls -A'
alias mkdir='mkdir -p'
alias path='printf "%s\\n" "${PATH//:/\\n}"'
alias settings-reload='source "$HOME/.config/settings/profile.sh"'
alias settings='"${SETTINGS_REPO:-$HOME/settings}/bin/settingsctl"'
