/* GNAT 16 runtime linker script has no place for .eh_frame (from crtbegin/crtend).
   Put it in flash right after .ARM.exidx so it cannot overlap .data's load address. */
SECTIONS
{
 .eh_frame : { KEEP (*(.eh_frame)) *(.eh_frame.*) }
}
INSERT AFTER .ARM.exidx;