# Start from Ubuntu LTS for the configuration stage
FROM ubuntu:22.04 AS config

# Number of jobs to run in parallel when building
ARG MAKE_JOB_COUNT=12

# The libraries required for building the build tools
ENV GMP_VERSION=6.2.1 \
	GMP_DIRECTORY=/opt/gmp \
	MPFR_VERSION=4.1.0 \
	MPFR_DIRECTORY=/opt/mpfr \
	MPC_VERSION=1.2.1 \
	MPC_DIRECTORY=/opt/mpc \
	ISL_VERSION=0.25 \
	ISL_DIRECTORY=/opt/isl

# The build tools
ENV BINUTILS_VERSION=2.39 \
	BINUTILS_DIRECTORY=/opt/binutils \
	GCC_VERSION=12.1.0 \
	GCC_DIRECTORY=/opt/gcc

###############################################

# Start from the configuration stage for the build stage
FROM config AS build

# Install utilities, dependencies & build tools from package repositories for building the libraries & build tools
# https://wiki.osdev.org/Building_GCC#Installing_Dependencies
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		ca-certificates wget \
		build-essential \
		m4 \
		gcc-multilib texinfo bison

# ------------------------------------------- #

# Build the GMP library
# https://gmplib.org/manual/Installing-GMP
RUN mkdir --verbose --parents ${GMP_DIRECTORY} /tmp/gmp/source /tmp/gmp/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gmp/source.tar.gz https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/gmp/source.tar.gz --directory /tmp/gmp/source && \
	cd /tmp/gmp/build && \
	/tmp/gmp/source/configure --prefix=${GMP_DIRECTORY} && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make check && \
	make install && \
	rm --verbose --recursive /tmp/gmp

# Build the MPFR library
# https://www.mpfr.org/mpfr-current/mpfr.html#Installing-MPFR
RUN mkdir --verbose --parents ${MPFR_DIRECTORY} /tmp/mpfr/source /tmp/mpfr/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/mpfr/source.tar.gz https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/mpfr/source.tar.gz --directory /tmp/mpfr/source && \
	cd /tmp/mpfr/build && \
	/tmp/mpfr/source/configure --prefix=${MPFR_DIRECTORY} --with-gmp=${GMP_DIRECTORY} && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make check && \
	make install && \
	rm --verbose --recursive /tmp/mpfr

# Build the MPC library
# https://multiprecision.org/downloads/mpc-1.2.1.pdf
RUN mkdir --verbose --parents ${MPC_DIRECTORY} /tmp/mpc/source /tmp/mpc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/mpc/source.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/mpc/source.tar.gz --directory /tmp/mpc/source && \
	cd /tmp/mpc/build && \
	/tmp/mpc/source/configure --prefix=${MPC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make check && \
	make install && \
	rm --verbose --recursive /tmp/mpc

# Build the ISL library
# https://libisl.sourceforge.io/user.html
RUN mkdir --verbose --parents ${ISL_DIRECTORY} /tmp/isl/source /tmp/isl/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/isl/source.tar.gz https://libisl.sourceforge.io/isl-${ISL_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/isl/source.tar.gz --directory /tmp/isl/source && \
	cd /tmp/isl/build && \
	/tmp/isl/source/configure --prefix=${ISL_DIRECTORY} --with-int=gmp --with-gmp-prefix=${GMP_DIRECTORY} && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make check && \
	make install && \
	rm --verbose --recursive /tmp/isl

# ------------------------------------------- #

# Build native (x86_64-pc-linux-gnu) Binutils
# https://wiki.osdev.org/Building_GCC#Binutils
# NOTE: This has no tests
RUN mkdir --verbose --parents ${BINUTILS_DIRECTORY} /tmp/binutils/source /tmp/binutils/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/binutils/source.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/binutils/source.tar.gz --directory /tmp/binutils/source && \
	cd /tmp/binutils/build && \
	/tmp/binutils/source/configure --prefix=${BINUTILS_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --with-isl=${ISL_DIRECTORY} --disable-nls --disable-werror && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make install && \
	rm --verbose --recursive /tmp/binutils

# Build native (x86_64-pc-linux-gnu) GCC (with bootstrapping)
# https://wiki.osdev.org/Building_GCC#GCC
# https://gcc.gnu.org/install/configure.html
# NOTE: Tests are not ran because they take too long
RUN mkdir --verbose --parents ${GCC_DIRECTORY} /tmp/gcc/source /tmp/gcc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gcc/source.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/source.tar.gz --directory /tmp/gcc/source && \
	cd /tmp/gcc/build && \
	/tmp/gcc/source/configure --prefix=${GCC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --with-isl=${ISL_DIRECTORY} --disable-nls --enable-languages=c,c++ && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make install && \
	rm --verbose --recursive /tmp/gcc

# Uninstall utilities, dependencies & build tools from package repositories
# NOTE: This is not required, as the final stage only copies the libraries & build tools from this stage.
RUN apt-get remove --purge --autoremove --yes \
		ca-certificates wget \
		build-essential \
		m4 \
		gcc-multilib texinfo bison && \
	rm --verbose --recursive /var/lib/apt/lists/*

###############################################

# Start from the configuration stage for the final stage
FROM config AS final

# Copy all of the libraries & build tools from the build stage
COPY --from=build --chown=root:root /opt /opt

# Add the libraries & build tool libraries to the linker path, and the build tools to the binaries path
ENV LD_LIBRARY_PATH=${GMP_DIRECTORY}/lib:${MPFR_DIRECTORY}/lib:${MPC_DIRECTORY}/lib:${ISL_DIRECTORY}/lib:${BINUTILS_DIRECTORY}/lib:${GCC_DIRECTORY}/lib:$LD_LIBRARY_PATH \
	PATH=${BINUTILS_DIRECTORY}/bin:${GCC_DIRECTORY}/bin:$PATH

# Install dependencies required to use the build tools
RUN apt-get update && \
	apt-get install --no-install-recommends --yes libc-dev && \
	rm --verbose --recursive /var/lib/apt/lists/*
