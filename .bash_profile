# Shell appearance
export PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Setting up Virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

# Aliases
alias ls='ls -GFh'
alias ll='ls -la'
alias pip.='pip install -e . --upgrade'

# Disable options:
unset MAILCHECK        # Don't want my shell to warn me of incoming mail.

#alias mkdir='mkdir -p'
alias c='clear'
alias h='history'
#alias j='jobs -l'
#alias ..='cd ..'
alias path='echo -e ${PATH//:/\\n}'
#alias libpath='echo -e ${LD_LIBRARY_PATH//:/\\n}'
alias du='du -kh'    # Makes a more readable output.
alias du+='du -hsc .*' # Disc usage of current dicertory 
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
alias git-master='git checkout master && git pull'
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

# OS purge tool to clean your OS environment
alias clean_os='ospurge --own-project --dont-delete-project'
export OS_AUTH_URL=
export OS_USERNAME=
export OS_PASSWORD=''
export OS_TENANT_NAME=

