# TKernel

A minimal x86-64 kernel and bootloader implementation written primarily for educational purposes. 

Feel free to use, edit, and publish this code freely.

@TomerAttali

Basically, we have a 2-stage bios based bootloader:
- bootstage1: moves to protected mode, and ljmp to the next stage.
- bootstage2: moves to long mode, jumps to bootmain64
- bootmain64: parses the kernel.elf from disk, loads it to memory.

To debug using GDB, please set an hardware breakpoint (hbreak) on VA(PA, using ID mapping for the first 2MB of memory): 0x15046. (Refer to the bootstage2.map).

*If you wish to run it on using proxmox, jump to the end of the readme, and please note 
that im (as to the date of writing this) using com1 serial for output, so prints will be shown on the debug console of proxmox.

## Prerequisites

- Linux-based development environment
- QEMU (qemu-system-x86_64)
- GDB (for debugging)
- A cross-compiler toolchain (x86_64-elf-gcc, x86_64-elf-as, x86_64-elf-ld)

## Installation

### 1. Install QEMU
```bash
# Ubuntu/Debian
sudo apt install qemu-system-x86

# Arch Linux
sudo pacman -S qemu

# macOS (using Homebrew)
brew install qemu
```

### 2. Install GDB (for debugging)
```bash
# Ubuntu/Debian
sudo apt install gdb

# Arch Linux
sudo pacman -S gdb

# macOS (using Homebrew)
brew install gdb
```

### 3. Build Cross-Compiler Toolchain

Since this kernel requires a cross-compiler targeting x86_64-elf, you'll need to build one. Here's how:

#### Option A: Manual Build (Recommended for Learning)

1. **Download and prepare sources:**
```bash
# Create a workspace
mkdir ~/cross-compiler
cd ~/cross-compiler

# Download binutils and gcc
wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.gz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.gz

# Extract
tar -xzf binutils-2.41.tar.gz
tar -xzf gcc-13.2.0.tar.gz
```

2. **Set environment variables:**
```bash
export PREFIX="$HOME/cross-compiler/x86_64-elf"
export TARGET=x86_64-elf
export PATH="$PREFIX/bin:$PATH"
```

3. **Build binutils:**
```bash
mkdir build-binutils
cd build-binutils
../binutils-2.41/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror
make -j$(nproc)
make install
cd ..
```

4. **Build GCC:**
```bash
mkdir build-gcc
cd build-gcc
../gcc-13.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers
make all-gcc -j$(nproc)
make all-target-libgcc -j$(nproc)
make install-gcc
make install-target-libgcc
```

5. **Add to your PATH:**
```bash
echo 'export PATH="$HOME/cross-compiler/x86_64-elf/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Option B: Using Package Managers

Some distributions provide cross-compiler packages:

```bash
# Arch Linux (AUR)
yay -S x86_64-elf-gcc

# Ubuntu (you may need to build manually)
# Check if available: apt search x86_64-elf-gcc
```

## Usage

### Building the Kernel

1. **Clone the repository:**
```bash
git clone <repository-url>
cd TKernel
```

2. **Build the kernel and bootloader:**
```bash
make
```

This will:
- Assemble the bootloader stages
- Compile the kernel
- Create a disk image (`disk.img`)

3. **Clean build files:**
```bash
make clean      # Remove object files and binaries
make cleanall   # Remove everything including disk.img
```

### Running the Kernel

**Basic execution:**
```bash
qemu-system-x86_64 -drive file=disk.img,format=raw,if=ide -m 128M
```

**With the provided script:**
```bash
./run_qemu.sh
```

This script runs QEMU with debugging support enabled and additional options for development.

### Debugging

The kernel can be debugged using GDB with QEMU's remote debugging feature:

1. **Start QEMU with debugging (using the provided script):**
```bash
./run_qemu.sh
```

2. **In another terminal, start GDB:**
```bash
gdb
(gdb) target remote localhost:1234
(gdb) symbol-file <your-kernel-binary>  # if available
```

3. **Debugging tips:**
- Use `hbreak` (hardware breakpoint) after moving to long mode
- GDB can behave oddly when switching between 16-bit, 32-bit, and 64-bit modes
- Set breakpoints in the 64-bit kernel code for best debugging experience

## Project Structure

```
TKernel/
├── boot64/                 # Bootloader source files
│   ├── bootstage1.s       # First stage bootloader (16-bit)
│   ├── bootstage2.s       # Second stage bootloader (32/64-bit)
│   ├── bootmain64.c       # C code for bootloader
│   ├── protmode_print.inc # Protected mode printing utilities
│   └── *.ld               # Linker scripts
├── kernel64/              # Kernel source files
│   └── kernel_main.c      # Main kernel entry point
├── inc/                   # Header files
│   └── elf.h             # ELF format definitions
├── makefile              # Build configuration
├── run_qemu.sh          # QEMU execution script
└── README.md            # This file
```

## Features

- **Two-stage bootloader:** Loads from 16-bit real mode to 64-bit long mode
- **x86-64 long mode:** Full 64-bit kernel execution
- **QEMU compatible:** Designed to run on QEMU virtualization

## Development Notes

- The kernel is designed for educational purposes and lacks many features of production kernels
- Memory management is minimal
- No user space or process management
- QEMU is the primary target platform

## Troubleshooting

**Cross-compiler not found:**
- Ensure your cross-compiler is in your PATH
- Verify the toolchain with: `x86_64-elf-gcc --version`

**Build errors:**
- Check that all required tools are installed
- Ensure you're using the correct cross-compiler target (x86_64-elf)

**QEMU issues:**
- Verify QEMU installation: `qemu-system-x86_64 --version`
- Check that disk.img was created successfully

## Proxmox
This is the config I used to run it on proxmox:

boot: order=ide2
cores: 1
cpu: x86-64-v2-AES
ide2: local:iso/disk.img,format=raw,size=150K
memory: 2048
meta: creation-qemu=9.0.2,ctime=1756035660
name: os.test.vm
numa: 0
ostype: other
serial0: socket
smbios1: uuid=db442a84-bc5e-44ad-8ad4-924df104fae6
sockets: 1
vga: std
vmgenid: da17882c-5fd3-418f-803f-521da7680884

## License

This project is released under an open license. Feel free to use, modify, and distribute.
