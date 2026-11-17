gh-create-repo () {
  local usage="Usage: gh-create-repo [--clone] [--fork [--no-remote-setup]] <repo-name|owner/repo> [private] [license]"

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
Creates a new GitHub repository (or forks one) and prints its ssh/https remotes.

${usage}
  --clone            also clone the repo locally
  --fork             fork <owner/repo> instead of creating a new repo (private/license ignored).
                     <owner/repo> may be omitted inside a git repo to fork that repo.
  --no-remote-setup  with --fork, don't touch the current repo's remotes. By default,
                     when run inside the repo being forked, the matching remote is
                     renamed to 'upstream' and your fork is added as 'origin'.
Example: gh-create-repo --clone my-project private MIT
Example: gh-create-repo --fork --clone cli/cli
Example: gh-create-repo --fork            # inside a clone of the repo to fork
EOF
    return 0
  fi

  local clone=0 fork=0 no_setup=0
  while [[ "$1" == --* ]]; do
    case "$1" in
      --clone) clone=1 ;;
      --fork) fork=1 ;;
      --no-remote-setup) no_setup=1 ;;
      *) echo "${usage}"; return 1 ;;
    esac
    shift
  done

  local repo_name="${1}"
  local -a private_flag
  local -a license_flag

  private_flag=(--public)
  license_flag=(--license MIT)

  # --fork with no args: infer the upstream from the current repo's remotes
  if [ -z "${repo_name}" ] && (( fork )); then
    local r url
    for r in upstream origin; do
      url="$(git remote get-url "${r}" 2>/dev/null)" && break
    done
    if [ -z "${url}" ]; then
      echo "--fork without <owner/repo> must run inside a git repo with a remote"
      return 1
    fi
    repo_name="$(sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#' <<<"${url}")"
  fi

  if [ -z "${repo_name}" ]; then
    echo "${usage}"
    return 1
  fi

  if (( fork )); then
    if [[ "${repo_name}" != */* ]]; then
      echo "--fork requires <owner/repo>"
      return 1
    fi
    local upstream="${repo_name}"
    # the fork lives under the current user, keeping the upstream repo name
    repo_name="$(gh api user --jq .login)/${upstream#*/}"

    if ! gh repo view "${repo_name}" >/dev/null 2>&1; then
      gh repo fork "${upstream}" --clone=false || return 1
    fi

    if (( ! no_setup )) && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      local r slug in_repo=0 origin_is_upstream=0
      for r in $(git remote); do
        slug="$(sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#' <<<"$(git remote get-url "${r}")")"
        if [[ "${(L)slug}" == "${(L)upstream}" ]]; then
          in_repo=1
          [[ "${r}" == "origin" ]] && origin_is_upstream=1
        fi
      done

      if (( in_repo )); then
        if (( origin_is_upstream )); then
          if git remote get-url upstream >/dev/null 2>&1; then
            echo "remote 'upstream' already exists; leaving 'origin' alone" >&2
          else
            git remote rename origin upstream || return 1
          fi
        fi
        if ! git remote get-url origin >/dev/null 2>&1; then
          git remote add origin "$(gh repo view "${repo_name}" --json sshUrl --jq .sshUrl)" || return 1
        fi
      fi
    fi
  else
    if [[ "${2-}" == "private" ]]; then
      private_flag=(--private)
    fi

    if [ -n "${3-}" ]; then
      license_flag=(--license "${3}")
    fi

    if ! gh repo view "${repo_name}" >/dev/null 2>&1; then
      gh repo create "${repo_name}" "${private_flag[@]}" "${license_flag[@]}" || return 1
    fi
  fi

  gh repo view "${repo_name}" --json sshUrl,url --jq '"ssh:   \(.sshUrl)\nhttps: \(.url).git"'

  if (( clone )); then
    gh repo view "${repo_name}" --json sshUrl --jq '.sshUrl' | xargs -I {} git clone {}
  fi
}
