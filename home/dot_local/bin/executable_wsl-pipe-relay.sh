#!/bin/bash
set -eu

# Relay a Windows named pipe to a unix socket in WSL via socat + npiperelay.exe
# Delivered by chezmoi externals
# https://github.com/albertony/npiperelay
#
# Usage: wsl-pipe-relay.sh ssh|gpg|keepassxc
#        wsl-pipe-relay.sh <unix-socket> <npiperelay args...>

NPIPERELAY_BIN="$HOME/.local/bin/npiperelay.exe"

# Read a windows env var, escaped for use inside a socat address
win_env() {
    /mnt/c/Windows/system32/cmd.exe /C "echo %$1%" 2>/dev/null | tr -d '\r' | tr '\\' '/' | sed 's#\:#\\:#'
}

case "${1-}" in
    ssh)
        # Served by windows gpg-agent via enable-win32-openssh-support
        set -- "${SSH_AUTH_SOCK-$HOME/.ssh/agent.sock}" -ei -s //./pipe/openssh-ssh-agent
        ;;
    gpg)
        set -- "${GPG_AGENT_SOCK-$(gpgconf --list-dir agent-socket)}" -ei -ep -a "$(win_env USERPROFILE)/AppData/Local/gnupg/S.gpg-agent"
        ;;
    keepassxc)
        # Legacy socket path, looked up by kpxc-cli (keepassxc-browser-api)
        set -- "$XDG_RUNTIME_DIR/org.keepassxc.KeePassXC.BrowserServer" -p -ei -s "//./pipe/org.keepassxc.KeePassXC.BrowserServer_$(win_env USERNAME)"
        ;;
esac

if [ $# -lt 2 ]; then
    echo >&2 "Usage: $0 ssh|gpg|keepassxc | <unix-socket> <npiperelay args...>"
    exit 2
fi

if ! test -x "$NPIPERELAY_BIN"; then
    echo >&2 "WARNING: $NPIPERELAY_BIN is not executable."
    exit 1
fi

SOCK=$1
shift

rm -rf "$SOCK"
mkdir -p "$(dirname "$SOCK")"
echo >&2 "Relaying $* -> $SOCK"
# Large buffer: kpxc-cli reads each reply with a single recv()
exec socat -b 1048576 UNIX-LISTEN:"$SOCK,fork" EXEC:"$NPIPERELAY_BIN $*"
