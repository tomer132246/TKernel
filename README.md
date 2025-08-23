# TKernel
1. This x86-64 kernel + bootloader was written mainly for studying purposes. please use \ edit \ publish freely. (To be used with qemu-system-x86_64).
2. Compiling the kernel + bootloader can be done by simply running make. (It assumes you are using a self build cross-compiler, read about it online.)
3. Debuggin can be acheived by running the run_qemu.sh script + gdb, I suggest hbreak (ing) after moving to long mode, since gdb acts badly for some reason when trying to change architectures when remote deubgging qemu.
