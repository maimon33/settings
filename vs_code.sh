#!/usr/bin/env bash

SOURCE_FILE="ttps://raw.githubusercontent.com/maimon33/mac-setting/master/source/vs_code/settings.json"
TARGET_FILE="~/Library/Application\ Support/Code/User/settings.json"

if [ -f $TARGET_FILE ]; then
    echo "File found! Getting the latest from GitHub, Archving the old"
    mv $TARGET_FILE $TARGET_FILE.bak
    curl $SOURCE_FILE -o $TARGET_FILE
else
    curl $SOURCE_FILE -o $TARGET_FILE
fi
