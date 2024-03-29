# UEFI Experiments

This is going to be my collection of applications I have made from experimenting with creating UEFI executables.

**There is currently just a single *[Hello World](hello-world/)* application. Check the [0.1.0 release](https://github.com/viral32111/uefi-experiments/releases/tag/0.1.0) for additional information, a screenshot, and downloads. However, I plan to make many more (see application to-do list below) once I have optimised my toolchain.**

## Background

I have always had a passion for low-level programming, and enjoy learning about the complex architecture that makes computers function like we have come to expect them to. Inspiration for this drew from my desire to one day create my own operating system, including userspace applications, kernel, bootloader and maybe even firmware/drivers.

Of course, I have already programmed C many times in the past, and even done a bit of ARM assembly for a University project, but both of those were making standalone executables that run on an existing operating system, Linux in their cases. However, this represents my first time programming in C for making applications that run in UEFI-space (either via an EFI shell or directly booting them).

Much of what I learnt has come from the [OSDev Wiki](https://wiki.osdev.org/UEFI), [x86asm Articles](http://x86asm.net/articles/uefi-programming-first-steps/), and the [UEFI specification](https://uefi.org/sites/default/files/resources/UEFI_Spec_2_9_2021_03_18.pdf).

## To-Do List

These are things I would like to get done at some point in the future. If I start working on one, I may create a project board to track my progress.

### Applications

* Entry-point application (at the EFI boot path) with a menu system that launches the other PE executables for the release disk image containing everything.
* [Application to print out all known vendor and system information](https://uefi.org/sites/default/files/resources/UEFI_Spec_2_9_2021_03_18.pdf#G8.1001756).
* Some sort of text-based or text-user-interface game.
* [Send/receive packets on the network](https://uefi.org/sites/default/files/resources/UEFI_Spec_2_9_2021_03_18.pdf#G33.1050570). <sup>[[1]](https://stackoverflow.com/questions/67045742) [[2]](https://github.com/vinxue/TcpTransport) [[3]](https://stackoverflow.com/questions/65923436)</sup>
* A shell, possibly as a replacement for the entry-point menu system application. Commands can be called, and some commands will run the other PE executables.
* [Simple bootloader that transfers control to a simple custom kernel](https://wiki.osdev.org/Rolling_Your_Own_Bootloader) (or maybe boots Linux?).
* Display Fibonacci sequence up to a certain number.
* Basic multi-threaded application (not sure if this is possible as pthread is a POSIX/Linux thing).
* Access framebuffer and draw 2D shapes to screen (not sure if this is possible).

### Meta

* GitHub Actions workflow to build and publish the huge Docker image so I don't have to.
  * Will have to publish to Docker Hub as the image is too large for the GitHub Container Registry.
* GitHub Actions workflow to build and upload artifacts of all applications.
* GitHub Actions workflow to perform CodeQL/code scanning.

## Running

To run these executables, download the bootable disk image from [latest release](https://github.com/viral32111/uefi-experiments/releases/latest), which containing all of them. Then boot this disk image on any UEFI-compatible system, or virtual machine of your choosing ([QEMU](https://www.qemu.org/) is recommended).

Alternatively, download each PE (`.efi`) executable file from the release and manually create the [GPT disk image](https://wiki.osdev.org/GPT) with a [EFI System Partition (ESP)](https://wiki.osdev.org/EFI_System_Partition) formatted as [FAT32](https://wiki.osdev.org/FAT32) containing all the executables. If your system has no EFI shell, or to make an executable run by default, place it at [`/EFI/BOOT/BOOTX64.EFI`](https://wiki.osdev.org/UEFI#Bootable_UEFI_applications) on the partition.

## Building

To build these executables GCC and the [GNU-EFI library](https://sourceforge.net/projects/gnu-efi/files/) are required.

The included [Docker image](dockerfile) can be built to get these in an isolated environment, as to not bloat your local system.

The [`build-applications.bash`](/scripts/build-applications.bash) script will compile each application.

The [`create-image.bash`](/scripts/create-image.bash) script will create a bootable disk image file containing the applications.

## License

Copyright (C) 2022-2023 [viral32111](https://viral32111.com).

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see https://www.gnu.org/licenses.
