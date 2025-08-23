qemu-system-x86_64 \
    -S -s \
  -drive file=disk.img,format=raw,if=ide \
  -m 128M -nographic -no-reboot \
  -monitor tcp:127.0.0.1:55555,server,nowait
# qemu-system-x86_64 \
#   -machine pc \
#   -cpu qemu64 \
#   -drive file=disk.img,if=ide,format=raw \
#   -S -gdb tcp::1234,ipv4 \
#   -no-reboot -no-shutdown