#!/bin/bash

# Exit if any errors occur
set -e

# Docker options
NAME='builder'

if [[ "$#" -ne 1 ]]; then
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi

# Build the docker image
if [[ "$1" = "docker" ]]; then

	# Create directory for logs
	mkdir -v -p logs/docker

	# Download the base image
	docker image pull ubuntu:22.04

	# Build the intermediary image
	docker image build --file dockerfiles/intermediary --tag "$NAME:intermediary" /var/empty 2>&1 | tee logs/docker/intermediary.log
	
	# Build the final image
	docker image build --file dockerfiles/final --tag "$NAME:final" /var/empty 2>&1 | tee logs/docker/final.log

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
		"$NAME:final"

else
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi
