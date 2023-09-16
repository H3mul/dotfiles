#!/bin/bash

set -euxo pipefail

mkdir -p ~/.dotfiles
rsync -av  --no-o /original-dotfiles/ ~/.dotfiles/ \
    --exclude ".git/" \
    --exclude "test"

export DOTFILES_DEBUG=true

~/.dotfiles/scripts/install.sh

# set +xeu
# source ~/.profile
# set -xeu

# chezmoi data

cd ~

/bin/bash "$@"