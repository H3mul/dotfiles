# Hardening that `gh` can do (the baseline in ta-policy docs/hardening.md, minus what has no API).
# Idempotent; each step reports on its own so one that a plan or repo type refuses (secret scanning
# on a free private repo, say) does not stop the rest. Branch protection is separate (protect=1)
# because it also blocks direct pushes to the default branch, yours included.
_gh_harden_step () {
  local desc="$1" out; local -a lines; shift
  if out="$("$@" 2>&1)"; then
    echo "  ok    ${desc}"
  else
    lines=("${(@f)out}")
    echo "  FAIL  ${desc}: ${lines[1]}"
    _gh_harden_failed=1
  fi
}

_gh_harden_repo () {
  local repo="$1" protect="${2:-0}" info private branch
  _gh_harden_failed=0
  info="$(gh repo view "${repo}" --json isPrivate,defaultBranchRef --jq '"\(.isPrivate) \(.defaultBranchRef.name // "")"')" || {
    echo "hardening: cannot read ${repo}" >&2
    return 1
  }
  private="${info%% *}"
  branch="${info#* }"
  [[ "${branch}" == "${info}" ]] && branch=""

  echo "Hardening ${repo}:"
  _gh_harden_step "auto-merge off" \
    gh api -X PATCH "repos/${repo}" -F allow_auto_merge=false
  _gh_harden_step "secret scanning and push protection on" \
    gh api -X PATCH "repos/${repo}" \
      -f 'security_and_analysis[secret_scanning][status]=enabled' \
      -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
  _gh_harden_step "workflow token read-only, workflows cannot approve PRs" \
    gh api -X PUT "repos/${repo}/actions/permissions/workflow" \
      -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
  if [[ "${private}" == "true" ]]; then
    _gh_harden_step "forking off (private repo)" \
      gh api -X PATCH "repos/${repo}" -F allow_forking=false
  else
    _gh_harden_step "fork PR workflows need approval" \
      gh api -X PUT "repos/${repo}/actions/permissions/fork-pr-contributor-approval" \
        -f approval_policy=all_external_contributors
    _gh_harden_step "only collaborators open PRs, issues and comments (renew within six months)" \
      gh api -X PUT "repos/${repo}/interaction-limits" -f limit=collaborators_only -f expiry=six_months
  fi

  if (( protect )); then
    if [[ -z "${branch}" ]]; then
      echo "  skip  branch protection: ${repo} has no default branch yet (push first, then run --harden --protect)"
    else
      _gh_harden_step "protect ${branch}: PR required, administrators included, no force push or deletion" \
        gh api -X PUT "repos/${repo}/branches/${branch}/protection" --input - <<JSON
{"required_status_checks": null, "enforce_admins": true,
 "required_pull_request_reviews": {"required_approving_review_count": 0, "dismiss_stale_reviews": true},
 "restrictions": null, "allow_force_pushes": false, "allow_deletions": false,
 "required_conversation_resolution": true}
JSON
    fi
  else
    echo "  note  branch protection not applied (it blocks direct pushes): add --protect when ready"
  fi
  echo "  not set here: required status checks, selected-actions, environments, tag rulesets (see the hardening doc)"
  return $(( _gh_harden_failed ))
}

gh-create-repo () {
  local usage="Usage: gh-create-repo [--clone] [--harden [--protect]] [--fork [--no-remote-setup]] [<repo-name|owner/repo>] [private] [license]"

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<EOF
Creates a new GitHub repository (or forks one) and prints its ssh/https remotes.

${usage}
  --clone            also clone the repo locally
  --fork             fork <owner/repo> instead of creating a new repo (private/license ignored).
                     <owner/repo> may be omitted inside a git repo to fork that repo.
  --harden           after creating (or finding) the repo, apply the hardening settings gh can:
                     auto-merge off, secret scanning and push protection, read-only workflow
                     token that cannot approve PRs, fork-PR approval and a collaborators-only
                     interaction limit (public repos) or forking off (private). Safe to repeat.
                     With no <repo-name>, hardens the repo of the current directory.
  --protect          with --harden, also protect the default branch: PR required,
                     administrators included, no force push or deletion. This blocks direct
                     pushes to it, so use it once the first commits are in.
  --no-remote-setup  with --fork, don't touch the current repo's remotes. By default,
                     when run inside the repo being forked, the matching remote is
                     renamed to 'upstream' and your fork is added as 'origin'.
Example: gh-create-repo --clone my-project private MIT
Example: gh-create-repo --fork --clone cli/cli
Example: gh-create-repo --fork            # inside a clone of the repo to fork
Example: gh-create-repo --harden           # inside an existing clone: harden that repo
Example: gh-create-repo --harden --protect my-project private
EOF
    return 0
  fi

  local clone=0 fork=0 no_setup=0 harden=0 protect=0
  while [[ "$1" == --* ]]; do
    case "$1" in
      --clone) clone=1 ;;
      --fork) fork=1 ;;
      --no-remote-setup) no_setup=1 ;;
      --harden) harden=1 ;;
      --protect) protect=1 ;;
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

  # --harden with no name and no --fork: the repo of the current directory
  if [ -z "${repo_name}" ] && (( harden )) && (( ! fork )); then
    repo_name="$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)"
    if [ -z "${repo_name}" ]; then
      echo "--harden without <repo-name> must run inside a clone of a GitHub repo"
      return 1
    fi
  fi

  if (( protect )) && (( ! harden )); then
    echo "--protect only makes sense with --harden"
    return 1
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

  if (( harden )); then
    _gh_harden_repo "${repo_name}" "${protect}"
  fi

  gh repo view "${repo_name}" --json sshUrl,url --jq '"ssh:   \(.sshUrl)\nhttps: \(.url).git"'

  if (( clone )); then
    gh repo view "${repo_name}" --json sshUrl --jq '.sshUrl' | xargs -I {} git clone {}
  fi
}
