# Automates unlocking luks volumes on remote hosts via ssh
# Automatic mode assumes you have the unlock passphrase encrypted in the ~/keys directory:
#   Eg, ssh target named `host1` will automatically be unlocked with the key
#   `~/keys/host1-unlock-passphrase.gpg` (provided local gpg can decrypt it)
#
# If there is no such file for the current target, or it can't be decrypted,
# or `-p` is passed, the user will be prompted to enter the passphrase
# If `-f` is passed, an interactive ssh shell is opened instead

function ssh-luks-unlock() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
Usage: ssh-luks-unlock <ssh_target> [-f|--force] [-p|--password]

Automates unlocking luks volumes on remote hosts via ssh.
Automatic mode assumes you have the unlock passphrase encrypted in the ~/keys directory:
  Eg, ssh target named 'host1' will automatically be unlocked with the key
  '~/keys/host1-unlock-passphrase.gpg' (provided local gpg can decrypt it)

If there is no such file for the current target, or it can't be decrypted,
the user will be prompted to enter the passphrase interactively.

  -p, --password  always prompt for the passphrase instead of using the key
  -f, --force     open an interactive ssh shell instead of unlocking
EOF
    return 0
  fi

  ssh_target="${1-}"
  shift
  force_interactive=""
  prompt_password=""
  for arg in "$@"; do
    case "$arg" in
      -f|--force) force_interactive=1 ;;
      -p|--password) prompt_password=1 ;;
      *) echo "Unknown option: $arg" >&2; return 1 ;;
    esac
  done
  ssh_command=(ssh "root@${ssh_target}" -p 222)

  if [ -n "${force_interactive}" ]; then
    echo "Starting interactive ssh session..."
    "${ssh_command[@]}"
  else
    passphrase=""
    if [ -z "${prompt_password}" ] && [ -f "$HOME/keys/${ssh_target}-unlock-passphrase.gpg" ]; then
      echo "Decrypting unlock passphrase..."
      passphrase=$(gpg -d "$HOME/keys/${ssh_target}-unlock-passphrase.gpg" 2>/dev/null)
    fi

    # Fall back to prompting when there is no key or gpg could not decrypt it
    if [ -z "${passphrase}" ]; then
      print -n "Unlock passphrase: "
      read -rs passphrase
      echo
      if [ -z "${passphrase}" ]; then
        echo "Empty passphrase"
        return 1
      fi
    fi

    echo "Unlocking luks over ssh with passphrase..."
    print -r -- "${passphrase}" | "${ssh_command[@]}" console_auth
  fi

  echo "Done"
}
