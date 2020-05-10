#!/bin/bash

docker image build \
    -t juliano777/postgres:latest\
    --compress\
    --no-cache\
    --squash\
    --force-rm .
