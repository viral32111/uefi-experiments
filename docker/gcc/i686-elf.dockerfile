# syntax=docker/dockerfile:1

# This Docker image contains a cross-compiled GCC toolchain for the i686-elf architecture.
# Use it to compile ELF binaries for UEFI systems on the i686 architecture.

# Use the following command to build this image with Docker Buildx. Remember to change the number of parallel make jobs.
# docker buildx build --progress plain --pull --file ./docker/gcc/i686-elf.dockerfile --tag ghcr.io/viral32111/gcc:i686-elf /var/empty

# Start from the native GCC toolchain, for the configuration stage
FROM ghcr.io/viral32111/gcc:x86_64-pc-linux-gnu AS config

# Configure target architecture & directories
ENV CROSS_TARGET=i686-elf \
	CROSS_DIRECTORY=/opt/i686-elf \
	CROSS_BINUTILS_DIRECTORY=/opt/i686-elf/binutils \
	CROSS_GCC_DIRECTORY=/opt/i686-elf/gcc

###############################################

# Start from the configuration stage, for the build stage
FROM config AS build

# Install utilities & build tools from package repositories for building the libraries & build tools
# https://wiki.osdev.org/Building_GCC#Installing_Dependencies
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		wget \
		build-essential m4 gcc-multilib texinfo bison file gawk python3 && \
	apt-get clean --yes && \
	rm --verbose --recursive /var/lib/apt/lists/*

# Build Binutils
# https://wiki.osdev.org/GCC_Cross-Compiler#Binutils
# NOTE: This has no tests
RUN mkdir --verbose --parents ${CROSS_BINUTILS_DIRECTORY} /tmp/binutils/source /tmp/binutils/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/binutils/source.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/binutils/source.tar.gz --directory /tmp/binutils/source && \
	cd /tmp/binutils/build && \
	/tmp/binutils/source/configure \
		--target=${CROSS_TARGET} \
		--prefix=${CROSS_BINUTILS_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} \
		--with-mpfr=${MPFR_DIRECTORY} \
		--with-mpc=${MPC_DIRECTORY} \
		--with-isl=${ISL_DIRECTORY} \
		--with-sysroot \
		--disable-nls \
		--disable-werror \
		--disable-multilib && \
	make --directory /tmp/binutils/build --jobs $(nproc) && \
	make --directory /tmp/binutils/build --jobs $(nproc) install && \
	rm --verbose --recursive /tmp/binutils

# Build GCC (without bootstrapping)
# https://wiki.osdev.org/GCC_Cross-Compiler#GCC
# https://wiki.osdev.org/Why_do_I_need_a_Cross_Compiler
# https://gcc.gnu.org/install/build.html#Building-a-cross-compiler
# NOTE: Tests are not ran because they take too long
ARG PATH=${CROSS_BINUTILS_DIRECTORY}/bin:$PATH
RUN mkdir --verbose --parents ${CROSS_GCC_DIRECTORY} /tmp/gcc/source /tmp/gcc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gcc/source.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --no-same-owner --strip-components 1 --file /tmp/gcc/source.tar.gz --directory /tmp/gcc/source && \
	cd /tmp/gcc/build && \
	/tmp/gcc/source/configure \
		--target=${CROSS_TARGET} \
		--prefix=${CROSS_GCC_DIRECTORY} \
		--with-gmp=${GMP_DIRECTORY} \
		--with-mpfr=${MPFR_DIRECTORY} \
		--with-mpc=${MPC_DIRECTORY} \
		--with-isl=${ISL_DIRECTORY} \
		--disable-nls \
		--enable-languages=c,c++ \
		--disable-bootstrap \
		--without-headers \
		--disable-multilib && \
	make --directory /tmp/gcc/build --jobs $(nproc) all-gcc && \
	make --directory /tmp/gcc/build --jobs $(nproc) all-target-libgcc && \
	make --directory /tmp/gcc/build --jobs $(nproc) install-gcc && \
	make --directory /tmp/gcc/build --jobs $(nproc) install-target-libgcc && \
	rm --verbose --recursive /tmp/gcc

###############################################

# Start from the configuration stage, for the final stage
FROM config AS final

# Copy all artifacts from the build stage
COPY --from=build --chown=0:0 ${CROSS_DIRECTORY} ${CROSS_DIRECTORY}

# Add the artifacts to the system path
ENV PATH=${CROSS_BINUTILS_DIRECTORY}/bin:${CROSS_GCC_DIRECTORY}/bin:$PATH \
	LD_LIBRARY_PATH=${BINUTILS_DIRECTORY}/lib:${GCC_DIRECTORY}/lib:$LD_LIBRARY_PATH
