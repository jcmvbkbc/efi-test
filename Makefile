CFLAGS = -O2 -W -Wall -ffreestanding -fno-stack-check -fno-stack-protector -fpic -fshort-wchar -mno-red-zone
CPPFLAGS = -I/usr/include/efi -I/usr/include/efi/x86_64 -I/usr/include/efi/protocol

all: myiso.iso
run: myiso.iso
	qemu-system-x86_64 -cpu qemu64 -bios OVMF.fd -m 2G  -monitor stdio -net none -cdrom $<

test.o: test.c Makefile
	cc $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

bootx64.so: test.o
	ld -nostdlib -znocombreloc -zdefs -T/usr/lib/elf_x86_64_efi.lds -shared -Bsymbolic -L /usr/lib /usr/lib/crt0-efi-x86_64.o $< -o $@ -lefi -lgnuefi

bootx64.efi: bootx64.so
	objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym  -j .rel -j .rela -j '.rel.*' -j '.rela.*' -j .reloc --target=efi-app-x86_64 --subsystem=10 $< $@

fat.img: bootx64.efi
	rm -f $@
	dd of=$@ seek=1 bs=64M count=0
	/sbin/mkfs.fat -F 32 $@
	mkdir fat || :
	sudo mount $@ fat
	sudo mkdir -p fat/efi/boot
	sudo cp $< fat/efi/boot/
	sudo umount fat

myiso.iso: fat.img
	genisoimage -v -J -r -V "TEST" -o $@ -eltorito-alt-boot -b $< -no-emul-boot $<

nonbootiso.iso: bootx64.efi
	genisoimage -v -J -r -V "TEST" -o $@ -graft-points efi/boot/=$<
