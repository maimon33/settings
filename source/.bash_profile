export BASH_SILENCE_DEPRECATION_WARNING=1

# Shell appearance
parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\[\033[36m\]\u\[\033[m\]@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

## History File
# append to the history file, don't overwrite it
shopt -s histappend
# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Bash Complition
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

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
alias lsblk='diskutil list'
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias o="open ." # Open the current directory in Finder
else
    alias o='xdg-open . > /dev/null 2>&1'
fi

# Applications Aliases
alias pip.='confirm pip install -e . --upgrade'
alias ip="curl icanhazip.com" # Your public IP address
alias ping="prettyping" # https://github.com/denilsonsa/prettyping
alias p='ping 8.8.8.8'
alias d='docker'
alias tg="terragrunt"

# virtual Env shortcuts
alias mk_env='mkvirtualenv'
alias rm_env='rmvirtualenv'

# Shell functions
md () {
    # Create folder and enter
    mkdir $1
    cd $1
}

confirm() {
    echo $1
    read -r -p "Are you sure? [Y/n]" response
    if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
        $@
    else
        return 1
    fi
}

rmx () {
    # Secure delete folders and files
    echo "You are about to complitly delete $1"
    confirm
    rm -rP $1 &
}

ssh_proxy () {
    # Connect to a server via proxy
    echo "You are about to connect to $2 via $1"
    ssh -o "ProxyCommand ssh $1 -W %h:%p" $2   
}

# Docker scripts
docker_clean () {
    confirm "You are about to delete $1 that match $2"
    case "$1" in
      images)
          docker images |grep $2 | while read -r image ; do
   	        echo "Deleteing $image"
   	        docker rmi $(echo $image | cut -d " " -f 3)
   	      done
	  ;;
      containers)
	    docker ps -a |grep $2 | while read -r container ; do
	      echo "Deleteing $container"
	      docker rm $(echo $container | cut -d " " -f 1)
        done
	  ;;
    esac
}

tag+push() {
	read -p "Docker Repo? (default: repo-docker-mirror.dev-f2g.com:5000/fdna): " DOCKER_REPO
	if [[ -z $DOCKER_REPO ]]; then DOCKER_REPO=repo-docker-mirror.dev-f2g.com:5000/fdna ;fi
	echo "Tagging $1 as $DOCKER_REPO/$2"
	docker tag $1 $DOCKER_REPO/$2
	docker push $2
}

# AWS envs
set-aws() {
        read -p "AWS Region? (default: eu-west-1): " AWS_DEFAULT_REGION
        read -p "AWS ACCESS KEY ID? (default: None): " AWS_ACCESS_KEY_ID
        read -p "AWS SECRET ACCESS KEY? (default: None): " AWS_SECRET_ACCESS_KEY
        if [[ -z $AWS_DEFAULT_REGION ]]; then AWS_DEFAULT_REGION=eu-west-1 ;fi
        echo "[default]" > $HOME/.aws/credentials
        echo "output=json" >> $HOME/.aws/credentials
        echo "region=$AWS_DEFAULT_REGION" >> $HOME/.aws/credentials
        echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> $HOME/.aws/credentials
        echo "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> $HOME/.aws/credentials

}

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
alias gh='git rev-parse HEAD'
alias git_age='echo "Git Age:" $(( ($(date "+%s") - $(date -jf"%a %b %d %T %Y %z" "$(git log -1 --format=%cd)" +%s)) / (3600) )) "Hours"'
 
# Safeties
## do not delete / or prompt if deleting more than 3 files at a time #
#alias rm='rm -I --preserve-root'

# confirmation #
#alias mv='mv -i'
#alias cp='cp -i'
#alias ln='ln -i'
 
# Parenting changing perms on / #
#alias chown='chown --preserve-root'
#alias chmod='chmod --preserve-root'
#alias chgrp='chgrp --preserve-root'
