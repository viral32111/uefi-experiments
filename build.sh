#!/bin/sh

# Exit if any errors occur
set -e

# Docker options
NAME='builder'
IMAGE='builder:latest'

if [[ "$#" -ne 1 ]]; then
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi

# Build the docker image
if [[ "$1" = "docker" ]]; then
	export DOCKER_BUILDKIT=1

	docker image build \
		--pull \
		--cache-from $IMAGE \
		--file dockerfile \
		--tag $IMAGE \
		/var/empty \
		2>&1 | tee docker.log

# Run a container to build the applications
elif [[ "$1" = "applications" ]]; then

	# TODO: Run GCC instead of Bash
	docker run \
		--name $NAME \
		--hostname $NAME \
		--mount type=bind,source=$PWD,target=/repository \
		--workdir /repository \
		--entrypoint bash \
		--interactive \
		--tty \
		--rm \
		$IMAGE

else
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi
