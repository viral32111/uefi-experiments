# syntax=docker/dockerfile:1

# This Docker image contains a native (x86_64-pc-linux-gnu) GCC toolchain.
# Use it to compile binaries for systems running GNU/Linux on the x86_64 architecture.

# Use the following command to build this image with Docker Buildx. Remember to change the number of parallel make jobs.
# docker buildx build --progress plain --pull --file ./docker/gcc/x86_64-pc-linux-gnu.dockerfile --tag ghcr.io/viral32111/gcc:x86_64-pc-linux-gnu /var/empty

# https://gmplib.org/#DOWNLOAD
# https://www.mpfr.org/mpfr-current/
# https://multiprecision.org/mpc/download.html
# https://libisl.sourceforge.io/
# https://ftp.gnu.org/gnu/binutils/
# https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/

# Start from my Ubuntu image, for the configuration stage
FROM ghcr.io/viral32111/ubuntu:22.10 AS config

# Configure versions & install directories
ENV GMP_VERSION=6.2.1 \
	GMP_DIRECTORY=/opt/gmp \
	MPFR_VERSION=4.2.0 \
	MPFR_DIRECTORY=/opt/mpfr \
	MPC_VERSION=1.3.1 \
	MPC_DIRECTORY=/opt/mpc \
	ISL_VERSION=0.26 \
	ISL_DIRECTORY=/opt/isl \
	GLIBC_VERSION=2.37 \
	GLIBC_DIRECTORY=/opt/glibc \
	BINUTILS_VERSION=2.40 \
	BINUTILS_DIRECTORY=/opt/binutils \
	GCC_VERSION=12.2.0 \
	GCC_DIRECTORY=/opt/gcc

###############################################

# Start from the configuration stage, for the build stage
FROM config AS build

# Install utilities & build tools from package repositories
# https://wiki.osdev.org/Building_GCC#Installing_Dependencies
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		wget \
		build-essential m4 gcc-multilib texinfo bison file gawk python3 \
		libnss3-dev libselinux1-dev && \
	apt-get clean --yes && \
	rm --verbose --recursive /var/lib/apt/lists/*

# Build the GMP library - https://gmplib.org/
# https://gmplib.org/manual/Installing-GMP
RUN mkdir --verbose --parents ${GMP_DIRECTORY} /tmp/gmp/source /tmp/gmp/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gmp/source.tar.gz https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/gmp/source.tar.gz --directory /tmp/gmp/source && \
	cd /tmp/gmp/build && \
	/tmp/gmp/source/configure \
		--prefix=${GMP_DIRECTORY} && \
	make --directory /tmp/gmp/build --jobs $(nproc) && \
	make --directory /tmp/gmp/build --jobs $(nproc) check && \
	make --directory /tmp/gmp/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/gmp

# Build the MPFR library - https://www.mpfr.org/
# https://www.mpfr.org/mpfr-current/mpfr.html#Installing-MPFR
RUN mkdir --verbose --parents ${MPFR_DIRECTORY} /tmp/mpfr/source /tmp/mpfr/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/mpfr/source.tar.gz https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/mpfr/source.tar.gz --directory /tmp/mpfr/source && \
	cd /tmp/mpfr/build && \
	/tmp/mpfr/source/configure \
		--prefix=${MPFR_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} && \
	make --directory /tmp/mpfr/build --jobs $(nproc) && \
	make --directory /tmp/mpfr/build --jobs $(nproc) check && \
	make --directory /tmp/mpfr/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/mpfr

# Build the MPC library - https://multiprecision.org/mpc
# https://multiprecision.org/downloads/mpc-1.2.1.pdf
RUN mkdir --verbose --parents ${MPC_DIRECTORY} /tmp/mpc/source /tmp/mpc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/mpc/source.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/mpc/source.tar.gz --directory /tmp/mpc/source && \
	cd /tmp/mpc/build && \
	/tmp/mpc/source/configure \
		--prefix=${MPC_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} \
		--with-mpfr=${MPFR_DIRECTORY} && \
	make --directory /tmp/mpc/build --jobs $(nproc) && \
	make --directory /tmp/mpc/build --jobs $(nproc) check && \
	make --directory /tmp/mpc/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/mpc

# Build the ISL library - https://libisl.sourceforge.io/
# https://libisl.sourceforge.io/user.html
RUN mkdir --verbose --parents ${ISL_DIRECTORY} /tmp/isl/source /tmp/isl/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/isl/source.tar.gz https://libisl.sourceforge.io/isl-${ISL_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/isl/source.tar.gz --directory /tmp/isl/source && \
	cd /tmp/isl/build && \
	/tmp/isl/source/configure \
		--prefix=${ISL_DIRECTORY} \
		--with-int=gmp \
		--with-gmp-prefix=${GMP_DIRECTORY} && \
	make --directory /tmp/isl/build --jobs $(nproc) && \
	make --directory /tmp/isl/build --jobs $(nproc) check && \
	make --directory /tmp/isl/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/isl

# Build the GNU C library - https://www.gnu.org/software/libc/
# https://sourceware.org/glibc/wiki/Testing/Builds
#RUN mkdir --verbose --parents ${GLIBC_DIRECTORY} /tmp/glibc/source /tmp/glibc/build && \
#	wget --no-hsts --progress dot:mega --output-document /tmp/glibc/source.tar.gz https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.gz 2>&1 && \
#	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/glibc/source.tar.gz --directory /tmp/glibc/source && \
#	cd /tmp/glibc/build && \
#	/tmp/glibc/source/configure --prefix=${GLIBC_DIRECTORY} && \
#	make --directory /tmp/glibc/build --jobs $(nproc) && \
#	make --directory /tmp/glibc/build --jobs $(nproc) check && \
#	make --directory /tmp/glibc/build --jobs $(nproc) install DESTDIR=${GLIBC_DIRECTORY} && \
#	rm --verbose --recursive /tmp/glibc

# Build native (x86_64-pc-linux-gnu) Binutils - https://www.gnu.org/software/binutils/
# https://wiki.osdev.org/Building_GCC#Binutils
# NOTE: This has no tests
RUN mkdir --verbose --parents ${BINUTILS_DIRECTORY} /tmp/binutils/source /tmp/binutils/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/binutils/source.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/binutils/source.tar.gz --directory /tmp/binutils/source && \
	cd /tmp/binutils/build && \
	/tmp/binutils/source/configure \
		--prefix=${BINUTILS_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} \
		--with-mpfr=${MPFR_DIRECTORY} \
		--with-mpc=${MPC_DIRECTORY} \
		--with-isl=${ISL_DIRECTORY} \
		--disable-nls \
		--disable-werror && \
	make --directory /tmp/binutils/build --jobs $(nproc) && \
	make --directory /tmp/binutils/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/binutils

# Build native (x86_64-pc-linux-gnu) GCC (with bootstrapping)
# https://wiki.osdev.org/Building_GCC#GCC
# https://gcc.gnu.org/install/configure.html
# NOTE: Tests are not ran because they take too long
RUN mkdir --verbose --parents ${GCC_DIRECTORY} /tmp/gcc/source /tmp/gcc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gcc/source.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/gcc/source.tar.gz --directory /tmp/gcc/source && \
	cd /tmp/gcc/build && \
	/tmp/gcc/source/configure \
		--prefix=${GCC_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} \
		--with-mpfr=${MPFR_DIRECTORY} \
		--with-mpc=${MPC_DIRECTORY} \
		--with-isl=${ISL_DIRECTORY} \
		--disable-nls \
		--enable-languages=c,c++ && \
	make --directory /tmp/gcc/build --jobs $(nproc) && \
	make --directory /tmp/gcc/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/gcc

###############################################

# Start from the configuration stage, for the final stage
FROM config

# Copy all artifacts from the build stage
COPY --from=build --chown=0:0 /opt /opt

# Add the artifacts to the system path
ENV LD_LIBRARY_PATH=${GMP_DIRECTORY}/lib:${MPFR_DIRECTORY}/lib:${MPC_DIRECTORY}/lib:${ISL_DIRECTORY}/lib:${GLIBC_DIRECTORY}/lib:${BINUTILS_DIRECTORY}/lib:${GCC_DIRECTORY}/lib:$LD_LIBRARY_PATH \
	PATH=${BINUTILS_DIRECTORY}/bin:${GCC_DIRECTORY}/bin:$PATH

# Install the GNU C library
RUN apt-get update && \
	apt-get install --no-install-recommends --yes libc-dev && \
	apt-get clean --yes && \
	rm --verbose --recursive /var/lib/apt/lists/*
