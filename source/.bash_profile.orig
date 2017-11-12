# Shell appearance
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\[\033[36m\]\u\[\033[m\]@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Setting up Virtualenvwrapper
export WORKON_HOME=~/Envs
source /usr/local/bin/virtualenvwrapper.sh

# Aliases
alias s='source ~/.bash_profile'
alias pro='vim ~/.bash_profile'
alias ip="curl icanhazip.com" # Your public IP address
alias o="open ." # Open the current directory in Finder
alias ls='ls -GFh'
alias ll='ls -la'
alias pip.='pip install -e . --upgrade'
alias mkdir='mkdir -p'
alias c='clear'
alias h='history'
alias path='echo -e ${PATH//:/\\n}'
alias du='du -kh'    # Makes a more readable output.
alias du+='du -hsc .*' # Disc usage of current dicertory
alias em='emacs -nw'
alias _='sudo'

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

<<<<<<< HEAD:.bash_profile
# History File
# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

=======
# do not delete / or prompt if deleting more than 3 files at a time #
alias rm='rm -I --preserve-root'
 
# confirmation #
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
 
# Parenting changing perms on / #
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
>>>>>>> add source folder:source/.bash_profile

# virtual Env shortcuts
alias mk_env='mkvirtualenv'
alias rm_env='rmvirtualenv'

# Shell functions
## Create folder and enter
md () {
    mkdir $1
    cd $1
}

 # AWS envs
 alias aws-stage='export AWS_ACCESS_KEY_ID=AKA...L && export AWS_SECRET_ACCESS_KEY="shu&%$%#n..T"'
