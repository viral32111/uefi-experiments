#!/bin/bash

# Exit if any errors occur
set -e

# Docker options
NAME='builder'
HUB='viral32111/uefi-experiments:latest'

# Do not continue unless we have all the arguments
if [[ "$#" -ne 1 ]]; then
	echo "Usage: $0 < docker [ intermediary | final ] | applications >" 1>&2
	exit 1
fi

# Easy access to arguments
ACTION="$1"
IMAGE="$2"

# Do not continue if action is empty
if [[ -z "$ACTION" ]]; then
	echo "Usage: $0 < docker [ intermediary | final ] | applications >" 1>&2
	exit 1
fi

# Build the docker image
if [[ "$ACTION" = "docker" ]]; then

	# Create logs directory if it does not exist
	if [[ ! -d "logs/docker" ]]; then
		mkdir -v -p logs/docker
	fi

	# Download the base image in case of any updates
	docker image pull ubuntu:22.04

	# Build just the intermediary image
	if [[ "$IMAGE" = "intermediary" ]]; then
		docker image build --file dockerfiles/intermediary --tag "${NAME}:intermediary" /var/empty 2>&1 | tee logs/docker/intermediary.log

	# Build just the final image
	elif [[ "$IMAGE" = "final" ]]; then
		docker image build --file dockerfiles/final --tag "${NAME}:final" /var/empty 2>&1 | tee logs/docker/final.log

		docker tag "$NAME:final" "${HUB}"

	# Build all images
	else
		docker image build --file dockerfiles/intermediary --tag "${NAME}:intermediary" /var/empty 2>&1 | tee logs/docker/intermediary.log
		docker image build --file dockerfiles/final --tag "${NAME}:final" /var/empty 2>&1 | tee logs/docker/final.log

		docker tag "$NAME:final" "${HUB}"
	fi

# Run a container to build the applications
elif [[ "$ACTION" = "applications" ]]; then

	# TODO: Run GCC instead of Bash
	docker run \
		--name "${NAME}" \
		--hostname "${NAME}" \
		--mount type=bind,source=$PWD/applications,target=/applications \
		--workdir /applications \
		--entrypoint bash \
		--interactive \
		--tty \
		--rm \
		"${HUB}"

# Unrecognised action
else
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi
