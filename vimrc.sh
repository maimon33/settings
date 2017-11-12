#!/usr/bin/env bash

if [ -f ~/.vimrc ]; then
    echo "File found! Getting the latest from GitHub, Archving the old"
    mv ~/.vimrc ~/.vimrc.bak
    curl -O https://raw.githubusercontent.com/maimon33/mac-setting/master/source/.vimrc ~/.vimrc
else
    curl -O https://raw.githubusercontent.com/maimon33/mac-setting/master/source/.vimrc ~/.vimrc
fi