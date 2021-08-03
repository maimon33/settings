#!/usr/bin/env bash

SOURCE_FILE="https://raw.githubusercontent.com/maimon33/mac-setting/master/source/.bash_profile"
TARGET_FILE="~/.bash_profile"

if [ -f $TARGET_FILE ]; then
    echo "File found! Getting the latest from GitHub, Archving the old"
    mv $TARGET_FILE $TARGET_FILE.bak
    curl $SOURCE_FILE -o $TARGET_FILE
else
    curl $SOURCE_FILE -o $TARGET_FILE
fi

# Setting Bash as default shell
chsh -s /bin/bash

source $TARGET_FILE
