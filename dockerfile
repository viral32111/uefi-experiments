# docker build --pull --file dockerfile --tag uefi-build-environment:latest /var/empty

# This is a large image, and will take a while (about 15 minutes) to build.
# Everything is divided into separate stages so that if something breaks you do not have to rebuild the entire image.

# https://wiki.osdev.org/Building_GCC
# https://wiki.osdev.org/GCC_Cross-Compiler

# Start from Ubuntu LTS
FROM ubuntu:22.04

# Disable shell history for all users
ENV HISTFILE=/dev/null

# Options for regular user
ARG USER_ID=1000 \
	USER_NAME=user \
	USER_HOME=/home/user

# Options for installing & building
ARG DEBIAN_FRONTEND=noninteractive \
	MAKE_JOBS=20

# Options for building Binutils
ARG BINUTILS_VERSION=2.38 \
	BINUTILS_DIRECTORY=/opt/binutils

# Options for building GCC
ARG GCC_VERSION=12.1.0 \
	GCC_DIRECTORY=/opt/gcc \
	GMP_VERSION=6.2.1 \
	MPFR_VERSION=4.1.0 \
	MPC_VERSION=1.2.1

# Create regular user with sudo access & install global dependencies
RUN mkdir --verbose --parents ${USER_HOME} && \
	apt-get update && \
	apt-get install --no-install-recommends --yes ca-certificates wget sudo && \
	adduser --system --disabled-password --disabled-login --shell /bin/bash --no-create-home --home ${USER_HOME} --gecos ${USER_NAME} --group --uid ${USER_ID} ${USER_NAME} && \
	usermod --append --groups sudo ${USER_NAME} && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
	chown --changes --recursive ${USER_ID}:${USER_ID} ${USER_HOME} && \	
	rm --verbose --force --recursive /var/lib/apt/lists/*

# Build the latest version of Binutils
# https://wiki.osdev.org/Building_GCC#Binutils
RUN apt-get update && \
	apt-get install --no-install-recommends --yes build-essential texinfo && \
	mkdir --verbose --parents /tmp/binutils/source /tmp/binutils/build ${BINUTILS_DIRECTORY} && \
	wget --progress dot:mega --output-document /tmp/binutils/binutils.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/binutils/binutils.tar.gz --directory /tmp/binutils/source && \
	cd /tmp/binutils/build && \
	../source/configure --prefix=${BINUTILS_DIRECTORY} --disable-nls --disable-werror && \
	make --jobs ${MAKE_JOBS} && \
	make install && \
	cd / && \
	apt-get remove --purge --autoremove --yes build-essential texinfo && \
	rm --verbose --force --recursive /tmp/binutils /var/lib/apt/lists/*

# Build the latest version of GCC (with bootstrapping)
# https://wiki.osdev.org/Building_GCC#GCC
RUN apt-get update && \
	apt-get install --no-install-recommends --yes build-essential \
		bison flex libgmp3-dev libmpc-dev libmpfr-dev libisl-dev \
		gcc-multilib \
		dejagnu tcl expect && \
	mkdir --verbose --parents /tmp/gcc/source /tmp/gcc/build ${GCC_DIRECTORY} && \
	wget --progress dot:mega --output-document /tmp/gcc/gcc.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gcc/gmp.tar.gz https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gcc/mpfr.tar.gz https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gcc/mpc.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/gcc.tar.gz --directory /tmp/gcc/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/gmp.tar.gz --directory /tmp/gcc/source --one-top-level=gmp && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/mpfr.tar.gz --directory /tmp/gcc/source --one-top-level=mpfr && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/mpc.tar.gz --directory /tmp/gcc/source --one-top-level=mpc && \
	cd /tmp/gcc/build && \
	../source/configure --prefix=${GCC_DIRECTORY} --disable-nls --enable-languages=c,c++ && \
	make --jobs ${MAKE_JOBS} && \
	make --keep-going check && \
	make install && \
	cd / && \
	apt-get remove --purge --autoremove --yes build-essential \
		bison flex libgmp3-dev libmpc-dev libmpfr-dev libisl-dev \
		dejagnu tcl expect && \
	rm --verbose --force --recursive /tmp/gcc /var/lib/apt/lists/*

# Add Binutils & GCC to PATH
ENV PATH="${BINUTILS_DIRECTORY}/bin:${GCC_DIRECTORY}/bin:$PATH"

# TODO: Compile a cross-compiler for i686-elf using the new compiler & co.

# Change to the regular user
WORKDIR ${USER_HOME}
USER ${USER_ID}:${USER_ID}

# Enter into a shell on startup
ENTRYPOINT [ "/bin/bash" ]
