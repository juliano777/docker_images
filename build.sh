#!/bin/bash

export TAG="${1}"

docker image prune -f

docker image build \
    -t juliano777/${TAG}\
    --compress\
    --no-cache\
    --squash\
    --force-rm .

docker image prune -f
