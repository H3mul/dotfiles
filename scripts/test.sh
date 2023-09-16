#!/bin/sh

set -eu

cd $(dirname "$0")
source ./common.sh

cd ${TEST_DIR}


run_test() {
    dockerfile="Dockerfile-${1}"
    dockertag="test-${1}"
    
    [ -f ${dockerfile} ] || error "Test dockerfile doesnt exist: ${dockerfile}"

    log_cmd docker build . -f ${dockerfile} -t ${dockertag}
    log_cmd docker run --rm -it \
        --env TERM --env COLORTERM \
        --volume "${REPO_ROOT}:/original-dotfiles:ro" \
        ${dockertag}:latest
}

run_test "$@"