# Shell appearance
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Setting up Virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

# Setting up Vault server address
export VAULT_ADDR='http://vault.gspaces.com:8200'

# Aliases
alias ls='ls -GFh'
alias ll='ls -la'

# Disable options:
#unset MAILCHECK        # Don't want my shell to warn me of incoming mail.

#alias mkdir='mkdir -p'
#alias c='clear'
#alias h='history'
#alias j='jobs -l'
#alias ..='cd ..'
#alias path='echo -e ${PATH//:/\\n}'
#alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
#alias du='du -kh'    # Makes a more readable output.
#alias df='df -kTh'

# Add colors for filetype and  human-readable sizes by default on 'ls':
#alias ls='ls -h --color'
#alias lx='ls -lXB'         #  Sort by extension.
#alias lk='ls -lSr'         #  Sort by size, biggest last.
#alias lt='ls -ltr'         #  Sort by date, most recent last.
#alias lc='ls -ltcr'        #  Sort by/show change time,most recent last.
#alias lu='ls -ltur'        #  Sort by/show access time,most recent last.

# The ubiquitous 'll': directories first, with alphanumeric sorting:
#alias ll="ls -lv --group-directories-first"
#alias lm='ll |more'        #  Pipe through 'more'
#alias lr='ll -R'           #  Recursive ls.
#alias la='ll -A'           #  Show hidden files.
#alias tree='tree -Csuh'    #  Nice alternative to 'recursive ls' ...

# git shortcuts
alias gs='git status '
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias go='git checkout '
alias gk='gitk --all&'
alias gx='gitx --all'
alias gp='git pull'
alias gl='git log --oneline -n 10'
alias gr='git rebase -i'

# virtual Env shortcuts
alias mk_env='mkvirtualenv'
alias rm_env='rmvirtualenv'

# Cloudhealth API key
export CLOUDHEALTH_API_KEY=

# OS purge tool to clean your OS environment
alias clean_os='ospurge --own-project --dont-delete-project'
export OS_AUTH_URL=
export OS_USERNAME=
export OS_PASSWORD=''
export OS_TENANT_NAME=

# The next line updates PATH for the Google Cloud SDK.
if [ -f /Users/assi/Downloads/google-cloud-sdk/path.bash.inc ]; then
  source '/Users/assi/Downloads/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f /Users/assi/Downloads/google-cloud-sdk/completion.bash.inc ]; then
  source '/Users/assi/Downloads/google-cloud-sdk/completion.bash.inc'
fi

## Service hosts and managers ##
alias use-prod='cfy profiles use 8.8.8.8'
alias use-test='cfy profiles use 8.8.8.8'
alias cs-super='ssh -i ~/AWS/Cloudify\ Service/cs-key.pem centos@172.31.48.43'