# Automates unlocking luks volumes on remote hosts via ssh
# Automatic mode assumes you have the unlock passphrase encrypted in the ~/keys directory:
#   Eg, ssh target named `host1` will automatically be unlocked with the key
#   `~/keys/host1-unlock-passphrase.gpg` (provided local gpg can decrypt it)
# 
# If there is no such file for the current target, or `--force` is passed,
# the user will be prompted to enter they passphrase interactively

function ssh-luks-unlock() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
Usage: ssh-luks-unlock <ssh_target> [--force]

Automates unlocking luks volumes on remote hosts via ssh.
Automatic mode assumes you have the unlock passphrase encrypted in the ~/keys directory:
  Eg, ssh target named 'host1' will automatically be unlocked with the key
  '~/keys/host1-unlock-passphrase.gpg' (provided local gpg can decrypt it)

If there is no such file for the current target, or --force is passed,
the user will be prompted to enter they passphrase interactively.
EOF
    return 0
  fi

  ssh_target="${1-}"
  force_interactive="${2-}"
  ssh_command=(ssh "root@${ssh_target}" -p 222)

  passphrase=""
  if [ -z "${force_interactive}" ] && [ -f "$HOME/keys/${ssh_target}-unlock-passphrase.gpg" ]; then
    echo "Decrypting unlock passphrase..."
    passphrase=$(gpg -d "$HOME/keys/${ssh_target}-unlock-passphrase.gpg" 2>/dev/null)

    if [ -z ${passphrase} ]; then
      echo "Passphrase key decryption failed (or empty string)"
      return 1
    fi
  fi

  if [ -z "${force_interactive}" ]; then
    echo "Unlocking luks over ssh with passhphrase..."
    echo "${passphrase}" | "${ssh_command[@]}" console_auth
  else
    echo "Starting interactive ssh session..."
    "${ssh_command[@]}"
  fi

  echo "Done"
}