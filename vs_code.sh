#!/usr/bin/env bash

if [ -f ~/Library/Application\ Support/Code/User/settings.json ]; then
    echo "File found! Getting the latest from GitHub, Archving the old"
    mv ~/.vimrc ~/.vimrc.bak
    curl -O https://raw.githubusercontent.com/maimon33/mac-setting/master/source/vs_code/settings.json ~/Library/Application\ Support/Code/User/settings.json
else
    curl -O https://raw.githubusercontent.com/maimon33/mac-setting/master/source/vs_code/settings.json ~/Library/Application\ Support/Code/User/settings.json
fi
