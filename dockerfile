# This is a very large image, and will take a while (about an hour on my i7-12700K) to build.

# Everything is divided into separate stages & layers so that if something
#  breaks you do not have to rebuild the entire image.

# Due to the use of separated layers, multi-stage builds are
#  used to reduce the size of the final image size.

# During development you need the header files for GNU-EFI, you should copy
#  the include (/opt/gnuefi/include) directory from this image to your local
#  development directory then configure your preferred IDE to use it.

# Instructions provided by...
#  https://wiki.osdev.org/Building_GCC
#  https://wiki.osdev.org/GCC_Cross-Compiler
#  https://gcc.gnu.org/install/
#  https://wiki.osdev.org/GNU-EFI

# See ./build.sh script for the command to build this image.

# Start the build image from Ubuntu LTS
FROM ubuntu:22.04 AS build

# Options for building & installing packages
ARG MAKE_JOBS=20 \
	DEBIAN_FRONTEND=noninteractive

# Options for building Binutils
ARG BINUTILS_VERSION=2.38 \
	BINUTILS_DIRECTORY=/opt/binutils

# Options for building GMP
ARG GMP_VERSION=6.2.1 \
	GMP_DIRECTORY=/opt/gmp

# Options for building MPFR
ARG MPFR_VERSION=4.1.0 \
	MPFR_DIRECTORY=/opt/mpfr

# Options for building MPC
ARG MPC_VERSION=1.2.1 \
	MPC_DIRECTORY=/opt/mpc

# Options for building GCC
ARG GCC_VERSION=12.1.0 \
	GCC_DIRECTORY=/opt/gcc

# Options for building GNU-EFI
ARG GNUEFI_VERSION=3.0.14 \
	GNUEFI_DIRECTORY=/opt/gnuefi

# Options for building the cross-compiler
ARG CROSS_TARGET=i686-elf \
	CROSS_BINUTILS_DIRECTORY=/opt/cross/binutils \
	CROSS_GCC_DIRECTORY=/opt/cross/gcc

# Install the dependencies for building
# https://wiki.osdev.org/Building_GCC#Installing_Dependencies
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		ca-certificates wget \
		build-essential make \
		texinfo \
		bison flex libisl-dev gcc-multilib \
		dejagnu tcl expect

# Download the source trees
# https://wiki.osdev.org/Building_GCC#Downloading_the_Source_Code
RUN mkdir --verbose --parents \
		/tmp/binutils/source /tmp/binutils/build ${BINUTILS_DIRECTORY} \
		/tmp/gmp/source /tmp/gmp/build ${GMP_DIRECTORY} \
		/tmp/mpfr/source /tmp/mpfr/build ${MPFR_DIRECTORY} \
		/tmp/mpc/source /tmp/mpc/build ${MPC_DIRECTORY} \
		/tmp/gcc/source /tmp/gcc/build ${GCC_DIRECTORY} \
		/tmp/gnuefi ${GNUEFI_DIRECTORY} \
		/tmp/cross/binutils/source /tmp/cross/binutils/build ${CROSS_BINUTILS_DIRECTORY} \
		/tmp/cross/gcc/source /tmp/cross/gcc/build ${CROSS_GCC_DIRECTORY} && \
	wget --progress dot:mega --output-document /tmp/binutils/source.tar.gz https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gmp/source.tar.gz https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/mpfr/source.tar.gz https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/mpc/source.tar.gz https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gcc/source.tar.gz https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz 2>&1 && \
	wget --progress dot:mega --output-document /tmp/gnuefi/source.tar.bz2 https://sourceforge.net/projects/gnu-efi/files/gnu-efi-${GNUEFI_VERSION}.tar.bz2/download 2>&1

# Extract the downloaded source trees
RUN tar --verbose --extract --strip-components 1 --file /tmp/binutils/source.tar.gz --directory /tmp/binutils/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/gmp/source.tar.gz --directory /tmp/gmp/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/mpfr/source.tar.gz --directory /tmp/mpfr/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/mpc/source.tar.gz --directory /tmp/mpc/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/gcc/source.tar.gz --directory /tmp/gcc/source && \
	tar --verbose --extract --strip-components 1 --file /tmp/gnuefi/source.tar.bz2 --directory /tmp/gnuefi

# Copy source trees for building the cross-compiler
RUN	cp --verbose --archive /tmp/binutils/source /tmp/cross/binutils && \
	cp --verbose --archive /tmp/gcc/source /tmp/cross/gcc

# Build & install Binutils (this is quick)
# https://wiki.osdev.org/Building_GCC#Binutils
RUN cd /tmp/binutils/build && \
	../source/configure --prefix=${BINUTILS_DIRECTORY} --disable-nls --disable-werror && \
	make --jobs ${MAKE_JOBS} && \
	make install

# Build, test & install GMP
# https://gmplib.org/manual/Installing-GMP
RUN cd /tmp/gmp/build && \
	../source/configure --prefix=${GMP_DIRECTORY} && \
	make --jobs ${MAKE_JOBS} && \
	make check && \
	make install

# Build, test & install MPFR
# https://www.mpfr.org/mpfr-current/mpfr.html#Installing-MPFR
RUN cd /tmp/mpfr/build && \
	../source/configure --prefix=${MPFR_DIRECTORY} --with-gmp=${GMP_DIRECTORY} && \
	make --jobs ${MAKE_JOBS} && \
	make check && \
	make install

# Build, test & install MPC
# https://multiprecision.org/downloads/mpc-1.2.1.pdf
RUN cd /tmp/mpc/build && \
	../source/configure --prefix=${MPC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} && \
	make --jobs ${MAKE_JOBS} && \
	make check && \
	make install

# Build & install GCC with bootstrapping
# https://wiki.osdev.org/Building_GCC#GCC
# NOTE: We don't run tests here because they take way too long
RUN cd /tmp/gcc/build && \
	../source/configure --prefix=${GCC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --disable-nls --enable-languages=c,c++ && \
	make --jobs ${MAKE_JOBS} && \
	make install

# Remove the old compiler & former build dependencies
RUN apt-get remove --purge --autoremove --yes \
		ca-certificates wget \
		gcc g++ gcc-multilib

# Add Binutils and GCC to the PATH
ENV PATH="${BINUTILS_DIRECTORY}/bin:${GCC_DIRECTORY}/bin:$PATH"

# Build & install GNU-EFI
# https://wiki.osdev.org/GNU-EFI#Requirements
RUN cd /tmp/gnuefi && \
	make --jobs ${MAKE_JOBS} && \
	make PREFIX=${GNUEFI_DIRECTORY} install && \
	mv -v ${GNUEFI_DIRECTORY}/lib/crt0-efi-x86_64.o ${GNUEFI_DIRECTORY}/crt0-efi-x86_64.o && \
	mv -v ${GNUEFI_DIRECTORY}/lib/elf_x86_64_efi.lds ${GNUEFI_DIRECTORY}/elf_x86_64_efi.lds

# Build Binutils as a cross-compiler
# https://wiki.osdev.org/GCC_Cross-Compiler#Binutils
RUN cd /tmp/cross/binutils/build && \
	../source/configure --target=${CROSS_TARGET} --prefix=${CROSS_BINUTILS_DIRECTORY} --with-sysroot --disable-nls --disable-werror && \
	make --jobs ${MAKE_JOBS} && \
	make install

# Add the cross-compiler Binutils to the PATH
ENV PATH="${CROSS_BINUTILS_DIRECTORY}/bin:$PATH"

# Build GCC as a cross-compiler without bootstrapping
# https://wiki.osdev.org/GCC_Cross-Compiler#GCC
RUN cd /tmp/cross/gcc/build && \
	../source/configure --target=${CROSS_TARGET} --prefix=${CROSS_GCC_DIRECTORY} --with-gmp=${GMP_DIRECTORY} --with-mpfr=${MPFR_DIRECTORY} --with-mpc=${MPC_DIRECTORY} --disable-nls --enable-languages=c,c++ --disable-bootstrap --without-headers && \
	make --jobs ${MAKE_JOBS} all-gcc && \
	make --jobs ${MAKE_JOBS} all-target-libgcc && \
	make install-gcc && \
	make install-target-libgcc

# Add the cross-compiler GCC to the PATH
ENV PATH="${CROSS_GCC_DIRECTORY}/bin:$PATH"

# Remove build dependencies & temporary files
RUN apt-get remove --purge --autoremove --yes \
		build-essential make \
		texinfo \
		bison flex libisl-dev \
		dejagnu tcl expect && \
	rm --verbose --force --recursive \
		/tmp/* \
		/var/lib/apt/lists/*

# ------------------------------------------------------------------------

# Start the final image from Ubuntu LTS
FROM ubuntu:22.04

# Options for the regular user
ARG USER_ID=1000 \
	USER_NAME=user \
	USER_HOME=/home/user

# Create regular user with sudo access
RUN mkdir --verbose --parents ${USER_HOME} && \
	apt-get update && \
	apt-get install --no-install-recommends --yes sudo && \
	adduser --system --disabled-password --disabled-login --shell /bin/bash --no-create-home --home ${USER_HOME} --gecos ${USER_NAME} --group --uid ${USER_ID} ${USER_NAME} && \
	usermod --append --groups sudo ${USER_NAME} && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
	chown --changes --recursive ${USER_ID}:${USER_ID} ${USER_HOME} && \
	rm --verbose --force --recursive /var/lib/apt/lists/*

# Copy all builds from the build images
COPY --from=build --chown=root:root /opt /opt

# Add all the builds to the PATH, and disable writing shell history to file
ENV PATH="${CROSS_BINUTILS_DIRECTORY}/bin:${CROSS_GCC_DIRECTORY}/bin:${BINUTILS_DIRECTORY}/bin:${GCC_DIRECTORY}/bin:$PATH" \
	HISTFILE=/dev/null

# Change to the regular user
WORKDIR ${USER_HOME}
USER ${USER_ID}:${USER_ID}

# Enter into a shell on startup
ENTRYPOINT [ "/bin/bash" ]
