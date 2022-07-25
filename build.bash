#!/bin/bash

# Exit if any errors occur
set -e

# Docker options
NAME='uefi-experiments'
IMAGE='viral32111/uefi-experiments'

# Do not continue unless we have all the arguments
if [[ "$#" -lt 1 ]]; then
	echo "Usage: $0 < docker [ intermediary | final ] | applications >" 1>&2
	exit 1
fi

# Easy access to arguments
ACTION="$1"
STEP="$2"

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

	# Just build the intermediary image
	if [[ "$STEP" = "intermediary" ]]; then
		docker image build --file dockerfiles/intermediary --tag "${IMAGE}:intermediary" /var/empty 2>&1 | tee logs/docker/intermediary.log

	# Just build the final image
	elif [[ "$STEP" = "final" ]]; then
		docker image build --file dockerfiles/final --tag "${IMAGE}:latest" /var/empty 2>&1 | tee logs/docker/final.log

	# Build all images
	else
		docker image build --file dockerfiles/intermediary --tag "${IMAGE}:intermediary" /var/empty 2>&1 | tee logs/docker/intermediary.log
		docker image build --file dockerfiles/final --tag "${IMAGE}:latest" /var/empty 2>&1 | tee logs/docker/final.log
	fi

# Run a container to build the applications
elif [[ "$ACTION" = "applications" ]]; then

	# TODO: Run GCC
	docker run \
		--name "${NAME}" \
		--hostname "${NAME}" \
		--mount type=bind,source=$PWD/applications,target=/applications,readonly \
		--mount type=bind,source=$PWD/scripts,target=/scripts,readonly \
		--workdir /tmp \
		--entrypoint bash \
		--interactive \
		--tty \
		--rm \
		"${IMAGE}:latest"

	# docker cp uefi-experiments:/tmp/image.img helloworlds.img

# TODO: Action for creating the disk image

# Unrecognised action
else
	echo "Usage: $0 < docker | applications >" 1>&2
	exit 1
fi
