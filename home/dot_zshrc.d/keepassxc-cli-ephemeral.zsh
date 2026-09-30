# Wrapper around keepassxc-cli that prompts for the master password once and caches it
# in the kernel keyring (keyctl, user keyring @u) with a strict TTL.
#
# Caveat: any process running as your uid can read keys from @u while they live;
# the TTL bounds that exposure window. The TTL is NOT extended by use.

_kp_error_parsing_options=81

_kp_usage() {
    cat <<USAGE_TEXT
Usage: kp [-h | --help] [-c | --config <config.toml>] <command> [options] [args]
       kp unlock | lock | status | init

DESCRIPTION
    Wrapper for keepassxc-cli that caches the master password in the kernel
    keyring (keyctl) with a strict TTL. The database and keyfile are injected,
    so any keepassxc-cli command works: kp ls / kp show -s Github / kp clip Github

    OPTIONS:

    -h, --help
        Print this help and exit.

    -c, --config <config.toml>
        Config file to use (default: \$KP_CONFIG or ${XDG_CONFIG_HOME:-$HOME/.config}/keepassxc-cli-ephemeral/config.toml).
        Keys: db (required), keyfile, ttl (seconds, default 900, not extended by use).
        Env vars KP_DB, KP_KEYFILE, KP_TTL override the file.

    init
        Create a template config file for this host.
USAGE_TEXT
}

# No exit here (this is sourced into the shell): callers do `_kp_die ...; return`
_kp_die() {
    echo "kp: ${1}" >&2
    return "${2:-90}"
}

keepassxc-cli-ephemeral() {
    # Strict mode, scoped to this function (emulate -L restores options on return).
    # err_return is zsh's errexit-for-functions; expected failures below are guarded with `|| ...`
    emulate -L zsh
    setopt err_return no_unset pipe_fail

    local cfg_file="${KP_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/keepassxc-cli-ephemeral/config.toml}"
    local opts

    # '+' stops at the first non-option so keepassxc-cli's own flags (e.g. show -s) pass through
    opts=$(getopt --options +c:h --long config:,help -- "$@" 2>/dev/null) || {
        _kp_usage
        _kp_die "error: parsing options" "$_kp_error_parsing_options"
        return
    }
    eval set -- "$opts"

    while true; do
        case "$1" in
            -h|--help)
                _kp_usage
                return 0
                ;;
            -c|--config)
                cfg_file="${2/#\~/$HOME}"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
    done

    if (( $# == 0 )); then
        _kp_usage
        return 1
    fi

    local dep
    for dep in keyctl python3; do
        if (( ! $+commands[$dep] )); then
            _kp_die "missing dependency: $dep"
            return
        fi
    done

    # Env vars take precedence over the host-local config file
    local env_db="${KP_DB-}" env_keyfile="${KP_KEYFILE-}" env_ttl="${KP_TTL-}"
    local KP_DB="" KP_KEYFILE="" KP_TTL=""
    # ponytail: python3 tomllib (3.11+) parses the file; recognised keys only, flat table
    if [[ -f "$cfg_file" ]]; then
        local cfg_vars
        cfg_vars=$(python3 -c 'import sys, tomllib, shlex
for k, v in tomllib.load(open(sys.argv[1], "rb")).items():
    if k in ("db", "keyfile", "ttl"): print(f"KP_{k.upper()}={shlex.quote(str(v))}")' "$cfg_file")
        eval "$cfg_vars"
    fi
    [[ -n "$env_db" ]] && KP_DB="$env_db"
    [[ -n "$env_keyfile" ]] && KP_KEYFILE="$env_keyfile"
    [[ -n "$env_ttl" ]] && KP_TTL="$env_ttl"
    : "${KP_TTL:=900}"
    KP_DB="${KP_DB/#\~/$HOME}"
    KP_KEYFILE="${KP_KEYFILE/#\~/$HOME}"

    local cmd="${1-}"

    if [[ "$cmd" == "init" ]]; then
        if [[ -f "$cfg_file" ]]; then
            echo "$cfg_file already exists"
            return 1
        fi
        mkdir -p "${cfg_file:h}"
        cat > "$cfg_file" <<EOF
# Host-local config for keepassxc-cli-ephemeral (kp). Not managed by chezmoi.
db = "~/path/to/database.kdbx"
keyfile = "~/path/to/keyfile"  # remove if the database has no keyfile
ttl = 900
EOF
        echo "Created $cfg_file - edit it for this host."
        return 0
    fi

    if [[ -z "$KP_DB" ]]; then
        _kp_die "KP_DB is not set. Run 'kp init' or export KP_DB."
        return
    fi
    if [[ ! -f "$KP_DB" ]]; then
        _kp_die "database not found: $KP_DB"
        return
    fi

    # One cache key per database
    local desc="keepassxc-cli-ephemeral:$(realpath "$KP_DB" | sha256sum | cut -c1-12)"
    local key_id
    key_id=$(keyctl search @u user "$desc" 2>/dev/null) || key_id=""

    local kp_base=(-q)
    [[ -n "$KP_KEYFILE" ]] && kp_base+=(-k "$KP_KEYFILE")

    case "$cmd" in
        lock)
            if [[ -n "$key_id" ]]; then
                keyctl revoke "$key_id" >/dev/null && echo "Locked"
            else
                echo "Already locked"
            fi
            return 0
            ;;
        status)
            if [[ -z "$key_id" ]]; then
                echo "Locked"
            else
                local hex_id=$(printf '%08x' "$key_id")
                local remaining=$(awk -v id="$hex_id" '$1 == id { print $4 }' /proc/keys)
                echo "Unlocked (expires in ${remaining:-?})"
            fi
            return 0
            ;;
    esac

    local pw=""

    # Validate a password against the database without touching the cache
    _kp_valid() {
        print -rn -- "$1" | keepassxc-cli db-info "${kp_base[@]}" "$KP_DB" >/dev/null 2>&1
    }

    _kp_unlock() {
        [[ -n "$key_id" ]] && { keyctl revoke "$key_id" >/dev/null 2>&1 || true; }
        read -rs "pw?Master password ($(basename "$KP_DB")): " </dev/tty
        echo >&2
        if ! _kp_valid "$pw"; then
            echo "kp: could not open database (wrong password?)" >&2
            pw=""
            return 1
        fi
        key_id=$(keyctl add user "$desc" "$pw" @u) || { pw=""; return 1; }
        # possessor + user only; no group/other access
        keyctl setperm "$key_id" 0x3f3f0000 >/dev/null
        keyctl timeout "$key_id" "$KP_TTL" >/dev/null
    }

    if [[ -n "$key_id" ]]; then
        pw=$(keyctl pipe "$key_id" 2>/dev/null) || pw=""
    fi
    if [[ -z "$pw" ]]; then
        _kp_unlock || return 1
    fi

    if [[ "$cmd" == "unlock" ]]; then
        pw=""
        echo "Unlocked for ${KP_TTL}s"
        return 0
    fi

    local rc=0
    print -rn -- "$pw" | keepassxc-cli "$cmd" "${kp_base[@]}" "$KP_DB" "${@:2}" || rc=$?

    # Failed: if the cached password is no longer valid (e.g. it changed), re-prompt once
    if (( rc != 0 )) && [[ -n "$key_id" ]] && ! _kp_valid "$pw"; then
        echo "kp: cached password no longer valid" >&2
        if _kp_unlock; then
            rc=0
            print -rn -- "$pw" | keepassxc-cli "$cmd" "${kp_base[@]}" "$KP_DB" "${@:2}" || rc=$?
        fi
    fi

    pw=""
    unfunction _kp_valid _kp_unlock 2>/dev/null
    return $rc
}

alias kp=keepassxc-cli-ephemeral
