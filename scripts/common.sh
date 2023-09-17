
# NOTE - this file Intended to be included via source as a lib, hence no shebang

# POSIX way to get script's dir: https://stackoverflow.com/a/29834779/12156188
# shellcheck disable=SC2312
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
REPO_ROOT=$(realpath "${SCRIPT_DIR}/../")
TEST_DIR=$(realpath "${REPO_ROOT}/test")

log_color() {
  color_code="$1"
  shift

  printf "\033[${color_code}m%s\033[0m\n" "$*" >&2
}

log_red() {
  log_color "0;31" "$@"
}

log_blue() {
  log_color "0;34" "$@"
}

log_green() {
  log_color "1;32" "$@"
}

log_task() {
  log_blue "🔃" "$@"
}

log_cmd() {
  log_task "$@"
  $@
}

log_manual_action() {
  log_red "⚠️" "$@"
}

log_error() {
  log_red "❌" "$@"
}

error() {
  log_error "$@"
  exit 1
}
