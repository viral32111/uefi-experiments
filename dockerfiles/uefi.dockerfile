# Start from the i686-elf GCC cross-compiler image for the configuration stage
FROM viral32111/uefi-experiments:gcc-i686-elf AS config

# Number of jobs to run in parallel when building
ARG MAKE_JOB_COUNT=12

# The libraries required for building UEFI applications
ARG GNUEFI_VERSION=3.0.15 \
	GNUEFI_DIRECTORY=/opt/gnuefi

# The utilities required for building kernels
ARG GRUB_VERSION=2.06 \
	GRUB_DIRECTORY=/opt/grub

###############################################

# Start from the configuration stage for the build stage
FROM config AS build

# Install utilities & build tools from package repositories
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		ca-certificates wget bzip2 \
		make
# gettext bison flex pkg-config libdevmapper1.02.1 libfreetype6 unifont python3 autoconf automake qemu xorriso

# Build GNU-EFI
# https://wiki.osdev.org/GNU-EFI#Requirements
# https://sourceforge.net/projects/gnu-efi/
RUN mkdir --verbose --parents ${GNUEFI_DIRECTORY} /tmp/gnuefi/source && \
	wget --no-hsts --progress dot:mega --output-document /tmp/gnuefi/source.tar.bz2 https://sourceforge.net/projects/gnu-efi/files/gnu-efi-${GNUEFI_VERSION}.tar.bz2/download 2>&1 && \
	tar --verbose --extract --strip-components 1 --file /tmp/gnuefi/source.tar.bz2 --directory /tmp/gnuefi/source && \
	cd /tmp/gnuefi/source && \
	make --jobs ${MAKE_JOB_COUNT} && \
	make PREFIX=${GNUEFI_DIRECTORY} install && \
	mv -v ${GNUEFI_DIRECTORY}/lib/crt0-efi-x86_64.o ${GNUEFI_DIRECTORY}/crt0-efi-x86_64.o && \
	mv -v ${GNUEFI_DIRECTORY}/lib/elf_x86_64_efi.lds ${GNUEFI_DIRECTORY}/elf_x86_64_efi.lds && \
	rm --verbose --recursive /tmp/gnuefi

# Build GRUB
# https://www.gnu.org/software/grub/manual/grub/html_node/Obtaining-and-Building-GRUB.html
#RUN mkdir --verbose --parents ${GRUB_DIRECTORY} /tmp/grub/source /tmp/grub/build && \
#	wget --no-hsts --progress dot:mega --output-document /tmp/grub/source.tar.gz https://ftp.gnu.org/gnu/grub/grub-${GRUB_VERSION}.tar.gz 2>&1 && \
#	tar --verbose --extract --strip-components 1 --file /tmp/grub/source.tar.gz --directory /tmp/grub/source && \
#	cd /tmp/grub/build && \
#	/tmp/grub/source/configure --prefix ${GRUB_DIRECTORY} --disable-nls && \
#	make --jobs ${MAKE_JOB_COUNT} && \
#	make check && \
#	make install && \
#	rm --verbose --recursive /tmp/grub

# Uninstall utilities from package repositories
# NOTE: This is not required, as the final stage only copies the libraries & build tools.
RUN apt-get remove --purge --autoremove --yes \
		ca-certificates wget bzip2 \
		make && \
	rm --verbose --recursive /var/lib/apt/lists/*

###############################################

# Start from the configuration stage for the final stage
FROM config AS final

# Options for the regular user
ARG USER_ID=1000 \
	USER_NAME=user \
	USER_HOME=/home/user

# Create regular user with sudo access & install required utilities
RUN apt-get update && \
	apt-get install --no-install-recommends --yes \
		sudo udev \
		parted dosfstools mtools \
		file \
		grub-common xorriso && \
	mkdir --verbose --parents ${USER_HOME} && \
	adduser --system --disabled-password --disabled-login --shell /bin/bash --no-create-home --home ${USER_HOME} --gecos ${USER_NAME} --group --uid ${USER_ID} ${USER_NAME} && \
	usermod --append --groups sudo ${USER_NAME} && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
	chown --changes --recursive ${USER_ID}:${USER_ID} ${USER_HOME} && \
	rm --verbose --force --recursive /var/lib/apt/lists/*

# Copy the library from the build stage
COPY --from=build --chown=root:root ${GNUEFI_DIRECTORY} ${GNUEFI_DIRECTORY}

# Add the library to the linker path, add the cross-compiler Binutils to the binaries path & disable writing history to file
ENV LD_LIBRARY_PATH=${GNUEFI_DIRECTORY}/lib:$LD_LIBRARY_PATH \
	HISTFILE=/dev/null

# Change to the regular user
WORKDIR ${USER_HOME}
USER ${USER_ID}:${USER_ID}

# Enter into a shell on startup
ENTRYPOINT [ "/bin/bash" ]
