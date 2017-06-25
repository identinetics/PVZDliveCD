#!/bin/bash -x
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# configure proxy settings
# export http_proxy=http://10.203.0.1:3128/
# export no_proxy="localhost,127.0.0.1"
# export https_proxy=$http_proxy
# You must duplicate in both upper-case and lower-case because (unfortunately) some programs only look for one or the other
# export HTTP_PROXY=$http_proxy
# export HTTPS_PROXY=$http_proxy
