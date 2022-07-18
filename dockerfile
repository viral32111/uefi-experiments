# docker build --pull --file dockerfile --tag uefi:latest /var/empty

FROM registry.server.home/ubuntu:22.04

RUN apt-get update && \
	apt-get install --no-install-recommends --yes sudo && \
	adduser ${USER_NAME} sudo && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER ${USER_ID}:${USER_ID}
