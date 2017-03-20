#!/usr/bin/env bash

if [ $(id -u) -ne 0 ]; then
    sudo="sudo"
fi

echo "removing unused containers"
$sudo docker rm -v $(sudo docker ps --filter status=exited -q 2>/dev/null) 2>/dev/null
echo "removing unused images"
$sudo docker rmi $(sudo docker images --filter "dangling=true" -q --no-trunc)
echo "listing unused volumes"
$sudo $sudo docker rmi $(sudo docker images --filter "dangling=true" -q --no-trunc)

