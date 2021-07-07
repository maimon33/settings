#!/usr/bin/env bash

sudo apt-get install vim python-pip python-dev build-essential -y
sudo pip install --upgrade pip 
sudo pip install --upgrade virtualenv
source ~/.bash_profile
mkdir ~/.Env
sudo pip install virtualenvwrapper
