#!/bin/bash

set -e

docker image build \
	--compress \
	--build-arg PG_VERSION='12.2' \
	--force-rm \
	--no-cache \
	--squash \
	--tag \
	juliano777/postgres:12.2 .

docker system prune -f
