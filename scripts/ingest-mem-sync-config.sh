#!/usr/bin/env bash
# Merge the host's ~/.claude-mem-sync/config.json onto the chezmoi template,
# re-templating the host-specific fields (chezmoi re-add skips templates).
# Host values win; projects only present in the template are kept, so a host
# with a subset of projects never drops the others. Remove projects by editing
# the template by hand. Objects merge recursively, arrays are replaced.
set -eu

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

src="${HOME}/.claude-mem-sync/config.json"
tmpl="${REPO_ROOT}/home/dot_claude-mem-sync/config.json.tmpl"

[ -f "${src}" ] || { log_red "No config at ${src}"; exit 1; }

host=$(jq \
    --arg dev 'h3mul-{{ .chezmoi.hostname }}' \
    --arg db '{{ .chezmoi.homeDir }}/.claude-mem/claude-mem.db' \
    '.global.devName = $dev | .global.claudeMemDbPath = $db' "${src}")

# The template is valid JSON ({{ }} only appears inside strings)
if [ -f "${tmpl}" ]; then
    new=$(jq -n --argjson t "$(cat "${tmpl}")" --argjson h "${host}" '$t * $h')
else
    new="${host}"
fi

if [ -f "${tmpl}" ] && [ "${new}" = "$(cat "${tmpl}")" ]; then
    log_success "Template already up to date"
    exit 0
fi

printf '%s\n' "${new}" >"${tmpl}"
git -C "${REPO_ROOT}" --no-pager diff --stat -- "${tmpl}"
log_success "Updated ${tmpl} (review and commit)"
