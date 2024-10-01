#!/bin/bash
set -eu

# Use windows gpg agent socket - enables using yubikey in wsl
# Largely based on:
# https://jardazivny.medium.com/the-ultimate-guide-to-yubikey-on-wsl2-part-2-1d9546ef23a6

# GPG Socket
# Removing Linux GPG Agent socket and replacing it by link to wsl2-ssh-pageant GPG socket
WIN_USERPROFILE_PATH=$(/mnt/c/Windows/system32/cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' | tr '\\' '/' | sed 's#\:#\\:#')    
GPG4WIN_CONFIG_PATH="${WIN_USERPROFILE_PATH}/AppData/Local/gnupg"    
WSL2_SSH_PAGEANT_BIN="$HOME/.local/bin/wsl2-ssh-pageant.exe"
GPG_AGENT_SOCK=${GPG_AGENT_SOCK-"$(gpgconf --list-dir agent-socket)"}
SSH_AUTH_SOCK=${SSH_AUTH_SOCK-"$HOME/.ssh/agent.sock"}

forward_gpg_agent() {
    rm -rf "$GPG_AGENT_SOCK"
    if test -x "$WSL2_SSH_PAGEANT_BIN"; then
        echo >&2 "Starting socat forwarder..."
        setsid socat UNIX-LISTEN:"$GPG_AGENT_SOCK,fork" EXEC:"$WSL2_SSH_PAGEANT_BIN --gpgConfigBasepath ${GPG4WIN_CONFIG_PATH} --gpg S.gpg-agent" >/dev/null 2>&1
    else
        echo >&2 "WARNING: $WSL2_SSH_PAGEANT_BIN is not executable."
        exit 1
    fi
}

forward_ssh_agent() {
    rm -rf "$SSH_AUTH_SOCK"
    if test -x "$WSL2_SSH_PAGEANT_BIN"; then
        echo >&2 "Starting socat forwarder..."
        setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK,fork" EXEC:"$WSL2_SSH_PAGEANT_BIN" >/dev/null 2>&1
    else
        echo >&2 "WARNING: $WSL2_SSH_PAGEANT_BIN is not executable."
    fi
}

if [ "$1" == "ssh" ]; then
    forward_ssh_agent
else
    forward_gpg_agent
fi