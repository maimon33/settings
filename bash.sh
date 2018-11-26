#!/usr/bin/env bash

if [ -f ~/.bash_profile ]; then
    echo "File found! Getting the latest from GitHub, Archving the old"
    mv ~/.bash_profile ~/.bash_profile.bak
    curl https://raw.githubusercontent.com/maimon33/mac-setting/master/source/.bash_profile -o ~/.bash_profile
else
    curl https://raw.githubusercontent.com/maimon33/mac-setting/master/source/.bash_profile -o ~/.bash_profile
fi
