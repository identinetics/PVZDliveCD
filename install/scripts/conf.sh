#!/usr/bin/env bash
set -e -o pipefail

# configuration for dscripts/verify.sh

main() {
    echo "starting $0" >> /tmp/startapp.log
    get_docker_image_name
    set_image_signature_args
    init_sudo
}


get_docker_image_name() {
    source /tmp/set_data_dir.sh >> /tmp/startapp.log 2>&1
    source $DATADIR/set_docker_image.sh >> /tmp/startapp.log 2>&1
    export IMAGENAME=$DOCKER_IMAGE
}


set_image_signature_args() {
    export DIDI_SIGNER='tester@testinetics.at'  # PGP uid  - no verification if empty
    export GPG_SIGN_OPTIONS='--default-key B5341047'
}


init_sudo() {
    if [ $(id -u) -ne 0 ]; then
        sudo="sudo"
    fi
}


main $@
