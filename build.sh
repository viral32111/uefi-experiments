#!/bin/sh

# Exit if any errors occur
set -e

# Options
NAME='builder'
IMAGE='builder:latest'

# Build the docker image if it does not exist
if [[ ! docker image inspect $IMAGE ]]; then
	docker image build --pull --file dockerfile --tag $IMAGE /var/empty
fi

# Run a container to build the application
# TODO: Run GCC instead of Bash
docker run \
	--name $NAME \
	--hostname $NAME \
	--mount type=bind,source=$PWD,target=/repository \
	--workdir /repository \
	--entrypoint bash \
	--interactive \
	--tty \
	$IMAGE
