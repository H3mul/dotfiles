#!/bin/bash
source $HOME/repo.conf
cd $HOME/storage/shared/$GH_REPO
git pull --rebase --autostash
cd $HOME
bash -c "read -t 3 -n 1"
