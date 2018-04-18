# Shell appearance
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\[\033[36m\]\u\[\033[m\]@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# History File
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Setting up Virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

# System Aliases
alias _='sudo'
alias s='source ~/.bash_profile'
alias pro='vim ~/.bash_profile'
alias mkdir='mkdir -p'
alias c='clear'
alias h='history'
alias path='echo -e ${PATH//:/\\n}'
alias du='du -kh'    # Makes a more readable output.
alias du+='du -hsc .*' # Disc usage of current dicertory
alias em='emacs -nw'
alias ls='ls -GFh'
alias ll='ls -la'
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias o="open ." # Open the current directory in Finder
else
    alias o='xdg-open . > /dev/null 2>&1'
fi

# Applications Aliases
alias pip.='confirm pip install -e . --upgrade'
alias ip="curl icanhazip.com" # Your public IP address
alias p='ping 8.8.8.8'
alias d='docker'

# virtual Env shortcuts
alias mk_env='mkvirtualenv'
alias rm_env='rmvirtualenv'

# Shell functions
## Create folder and enter
md () {
    mkdir $1
    cd $1
}

confirm() {
    echo -n "Do you want to run $*? [N/y] "
    read -N 1 REPLY
    echo
    if test "$REPLY" = "y" -o "$REPLY" = "Y"; then
        "$@"
    else
        echo "Cancelled by user"
    fi
}

# AWS envs
alias aws-stage='export AWS_ACCESS_KEY_ID=AKA...L && export AWS_SECRET_ACCESS_KEY="shu&%$%#n..T"'

# Disable options:
unset MAILCHECK        # Don't want my shell to warn me of incoming mail.

# git shortcuts
alias gm='git checkout master && git pull' # git-master, checks out master and pulls
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
 
# Safeties
## do not delete / or prompt if deleting more than 3 files at a time #
alias rm='rm -I --preserve-root'

# confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
 
# Parenting changing perms on / #
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
