#include <efi.h>
#include <efilib.h>

unsigned char
inportb(unsigned short port)
{
	unsigned char v;
	asm volatile ("in {%1|%b0}, {%b0|%1}\n" : "=a"(v) : "d"(port));
	return v;
}

EFI_STATUS
EFIAPI
efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
	InitializeLib(ImageHandle, SystemTable);
	Print(L"Hello, world!\n");
	inportb(0x60);
	return EFI_SUCCESS;

}
