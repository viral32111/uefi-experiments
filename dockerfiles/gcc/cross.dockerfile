# Start from the native GCC image for the configuration stage
FROM viral32111/uefi-experiments:gcc-native AS config

# Number of jobs to run in parallel when building
ARG MAKE_JOB_COUNT=12

# The cross-compiler target architecture
ARG CROSS_COMPILER_TARGET=i686-elf

# The cross-compiler build tools
# TODO: Use the versions from the config stage of the native GCC image
ENV CROSS_COMPILER_BINUTILS_DIRECTORY=/opt/${CROSS_COMPILER_TARGET}/binutils \
	CROSS_COMPILER_GCC_DIRECTORY=/opt/${CROSS_COMPILER_TARGET}/gcc

###############################################

# Start from the configuration stage for the build stage
FROM config AS build

# Install utilities, dependencies & build tools from package repositories for building the build tools
# https://wiki.osdev.org/Building_GCC#Installing_Dependencies
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		ca-certificates wget \
		make \
		texinfo bison
# flex libisl-dev dejagnu tcl expect
# dpkg-dev
# libc-dev m4
# file

# ------------------------------------------- #

# Build cross-compiler Binutils
# https://wiki.osdev.org/GCC_Cross-Compiler#Binutils
# NOTE: This has no tests
RUN mkdir --verbose --parents ${CROSS_COMPILER_BINUTILS_DIRECTORY} /tmp/binutils/source /tmp/binutils/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/binutils/source.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/binutils/source.tar.gz --directory /tmp/binutils/source && \
	cd /tmp/binutils/build && \
	/tmp/binutils/source/configure --target=${CROSS_COMPILER_TARGET} --prefix=${CROSS_COMPILER_BINUTILS_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --with-isl=${ISL_DIRECTORY} --with-sysroot --disable-nls --disable-werror && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make install && \
	rm --verbose --recursive /tmp/binutils

# Build cross-compiler GCC (without bootstrapping)
# https://wiki.osdev.org/GCC_Cross-Compiler#GCC
# https://wiki.osdev.org/Why_do_I_need_a_Cross_Compiler
# NOTE: Tests are not ran because they take too long
ARG PATH=${CROSS_COMPILER_BINUTILS_DIRECTORY}/bin:$PATH
RUN mkdir --verbose --parents ${CROSS_COMPILER_GCC_DIRECTORY} /tmp/gcc/source /tmp/gcc/build && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gcc/source.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/source.tar.gz --directory /tmp/gcc/source && \
	cd /tmp/gcc/build && \
	/tmp/gcc/source/configure --target=${CROSS_COMPILER_TARGET} --prefix=${CROSS_COMPILER_GCC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --with-isl=${ISL_DIRECTORY} --disable-nls --enable-languages=c,c++ --disable-bootstrap --without-headers && \
	make --jobs ${MAKE_JOB_COUNT} all-gcc && \
	make --jobs ${MAKE_JOB_COUNT} all-target-libgcc && \
	make install-gcc && \
	make install-target-libgcc && \
	rm --verbose --recursive /tmp/gcc

# ------------------------------------------- #

# Uninstall utilities, dependencies & build tools from package repositories
# NOTE: This is not required, as the final stage only copies the libraries & build tools.
RUN apt-get remove --purge --autoremove --yes \
		ca-certificates wget \
		make \
		texinfo bison && \
	rm --verbose --recursive /var/lib/apt/lists/*
# flex libisl-dev dejagnu tcl expect
# dpkg-dev
# libc-dev m4
# file

###############################################

# Start from the configuration stage for the final stage
FROM config AS final

# Copy all of the build tools from the build stage
COPY --from=build --chown=root:root /opt/${CROSS_COMPILER_TARGET} /opt/${CROSS_COMPILER_TARGET}

# Add the cross-compiler build tools to the binaries path & cross-compiler build tool libraries to the linker path
ENV PATH=${CROSS_COMPILER_BINUTILS_DIRECTORY}/bin:${CROSS_COMPILER_GCC_DIRECTORY}/bin:$PATH \
	LD_LIBRARY_PATH=${BINUTILS_DIRECTORY}/lib:${GCC_DIRECTORY}/lib:$LD_LIBRARY_PATH

# TODO: Are there any dependencies required to use the cross-compiler? (e.g. libc6-dev is required to use the native GCC)
