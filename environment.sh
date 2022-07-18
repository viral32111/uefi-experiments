#!/bin/sh

docker run \
	--name uefi \
	--hostname uefi \
	--mount type=bind,source=$PWD,target=/home/user/data \
	--interactive \
	--tty \
	--rm \
	uefi:latest
