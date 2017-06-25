#!/bin/bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

export DOCKER_IMAGE='rhoerbe/pvzd-client-app:pr'

# other images
#export DOCKER_IMAGE='rhoerbe/pvzd-client-app:qa'
#export DOCKER_IMAGE='rhoerbe/keymgmt'
#export DOCKER_IMAGE='rhoerbe/safenetac'
