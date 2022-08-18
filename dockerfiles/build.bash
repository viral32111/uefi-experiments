#!/bin/bash

# Exit if there are any errors
set -e

# Configuration
LOGS_DIRECTORY="logs"
IMAGE_NAME="viral32111/operating-system"

# Do not continue unless we have all the arguments
if [[ "$#" -lt 1 ]] || [[ -z "$1" ]]; then
	echo "Usage: $0 < build [ native | (target) ] | push >" 1>&2
	exit 1
fi

# Enable Docker BuiltKit
export DOCKER_BUILDKIT=1

# Builds the native (x86_64-pc-linux-gnu) GCC compiler
function build-gcc-native {
	docker image build \
		--progress plain \
		--file gcc/native.dockerfile \
		--tag "${IMAGE_NAME}:gcc-native" \
		--cache-from "${IMAGE_NAME}:gcc-native" \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		/var/empty 2>&1 | tee "${LOGS_DIRECTORY}/gcc-native.log"
}

# Builds a specified (i686-elf & x86_64-elf in our case) GCC cross-compiler
function build-gcc-cross-compiler {
	if [[ -z "$1" ]]; then
		echo "No target (e.g. i686-elf) given to build GCC cross-compiler function" 1>&2
		exit 1
	fi

	docker image build \
		--progress plain \
		--file gcc/cross.dockerfile \
		--tag "${IMAGE_NAME}:gcc-${1}" \
		--cache-from "${IMAGE_NAME}:gcc-native" \
		--cache-from "${IMAGE_NAME}:gcc-${1}" \
		--build-arg "CROSS_COMPILER_TARGET=${1}" \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		/var/empty 2>&1 | tee "${LOGS_DIRECTORY}/gcc-${1}.log"
}

# If the action is to build the images...
if [[ "$1" = "build" ]]; then

	# Create the logs directory if it does not exist
	if [[ ! -d "${LOGS_DIRECTORY}" ]]; then
		mkdir --verbose --parents "${LOGS_DIRECTORY}"
	fi

	# Download/update the Ubuntu LTS base image
	docker image pull ubuntu:22.04

	# Build all images if no specific target was provided
	if [[ -z "$2" ]]; then
		build-gcc-native
		build-gcc-cross-compiler "i686-elf"
		build-gcc-cross-compiler "x86_64-elf"

		# Build the image for UEFI experiments
		docker image build \
			--progress plain \
			--file uefi.dockerfile \
			--tag "${IMAGE_NAME}:uefi" \
			--cache-from "${IMAGE_NAME}:gcc-native" \
			--cache-from "${IMAGE_NAME}:gcc-i686-elf" \
			--cache-from "${IMAGE_NAME}:uefi" \
			--build-arg BUILDKIT_INLINE_CACHE=1 \
			/var/empty 2>&1 | tee "${LOGS_DIRECTORY}/uefi.log"

	# Just build native GCC if that was the target
	elif [[ "$2" = "native" ]]; then
		build-gcc-native

	# Otherwise, just build whatever target was specified
	else
		build-gcc-cross-compiler "$2"
	fi

	# TODO: Build an image based on i686-elf with GNU-EFI for compiling UEFI applications

# If the action is to push the images...
elif [[ "$1" = "push" ]]; then

	# Get a list of all images starting with the base image name
	IMAGE_LIST=$(docker image ls --format '{{ .Repository }}:{{ .Tag }}' | grep "^${IMAGE_NAME}:")

	# Push each of those images to their registry
	for IMAGE in "${IMAGE_LIST}"; do
		docker image push "${IMAGE}"
	done

# Otherwise, the action is unknown
else
	echo "Usage: $0 < build [ native | (target) ] | push >" 1>&2
	exit 1
fi
