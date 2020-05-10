#!/bin/bash

docker image prune -f

docker image build \
    -t juliano777/postgres:latest\
    --compress\
    --no-cache\
    --squash\
    --force-rm .

docker image prune -f
