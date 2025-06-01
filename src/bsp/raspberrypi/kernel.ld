/*=============================================================================
 * Physical Load Address Symbol
 *------------------------------------------------------------------------------
 * In a bare-metal environment, there is no operating system loader to place
 * the compiled kernel into memory. Instead, the Raspberry Pi's GPU/firmware
 * automatically loads the first binary it finds on the SD card into a known
 * physical address in RAM. For the Pi 4, that address is 0x80000 (512 KB).
 *
 * By defining this symbol, both your code (assembly or Rust) and the
 * linker script agree on where the kernel lives.
 *
 * This assigns the numeric value 0x80000 to the name __rpi_phys_binary_load_addr.
 *=============================================================================
 */

__rpi_phys_binary_load_addr = 0x80000;  /* 0x80000 = 512 KiB */

/*=============================================================================
 * ENTRY Directive
 *------------------------------------------------------------------------------
 * The ENTRY() directive tells the linker exactly which address is the program's
 * entry point. In a typical Linux or Windows program, the loader reads the ELF
 * header to find where to jump. In bare-metal, we skip any OS loader entirely.
 *
 * By specifying ENTRY(__rpi_phys_binary_load_addr), we instruct the final ELF to
 * have its e_entry field set to 0x80000. When the CPU starts executing, it will
 * jump to that address, so whatever bytes are placed there must be valid code.
 *
 * All code sections (.text) code must be placed at or after this address.
 *=============================================================================
 */
ENTRY(__rpi_phys_binary_load_addr)

/*=============================================================================
 * Program Headers (PHDRS)
 *------------------------------------------------------------------------------
 * In the ELF (Executable and Linkable Format), program headers describe how
 * segments (contiguous chunks of memory, like code or data) map into memory when
 * the kernel or executable is loaded.
 *
 * A "segment" is a continuous region in the final output file (binary) that contains
 * one or more input sections. The most common segment types are:
 *   • PT_LOAD: data/code to be loaded into memory
 *   • PT_PHDR / PT_INTERP / PT_DYNAMIC: used by operating systems, not as relevant
 *     in bare-metal.
 *
 * In bare-metal, we care about exactly those parts which must be mapped into RAM.
 * Each segment also has "flags" that indicate permissions:
 *   • PF_R  (4) = Read
 *   • PF_W  (2) = Write
 *   • PF_X  (1) = Execute
 * Flags are ORed together.
 *   • e.g., Read+Execute = 4 + 1 = 5.
 *
 * PHDRS {
 *   <name> <type> FLAGS(<bitmask>);
 * }
 *   • <name> is an internal label for this segment.
 *   • <type> is PT_LOAD because we want code/data to be loaded.
 *   • FLAGS(5) means Read + Execute.
 *
 * Why read+execute? Code must be readable by the CPU but not necessarily writable.
 * Data sections (not shown here) might use FLAGS(6) = Read + Write.
 *
 *=============================================================================
 */

PHDRS
{
    /* segment_code: name of this program header */
    /* PT_LOAD: tells the loader (firmware) to map this segment into RAM at load time */
    /* FLAGS(5): decimal 5 = 0b101 = PF_R | PF_X (readable + executable) */
    segment_code PT_LOAD FLAGS(5);
}

/*=============================================================================
 * Sections Mapping (SECTIONS)
 *------------------------------------------------------------------------------
 * The SECTIONS command describes how individual input sections (.text, .data,
 * .bss, etc.) from object files (.o) are combined and placed into output
 * sections (commonly also named .text, .data, etc.) in the final binary.
 *
 * The layout process:
 *   1. Set the location counter (.) to the desired load address.
 *   2. For each named output section (.text, .rodata, .data, .bss), specify which
 *      input sections should go there and how to align them.
 *   3. Assign the output section to a program header defined in PHDRS.
 *
 * In this minimal script, we only define one output section: .text.
 *
 * The syntax:
 *   SECTIONS {
 *     . = <address>;       sets the location counter to <address>
 *     .text : { <contents> } :<segment_name>
 *   }
 *
 *  • ". = __rpi_phys_binary_load_addr;" sets the starting address for .text to 0x80000.
 *  • ".text : { ... } :segment_code" means: collect specified input sections into
 *     the output .text section, then associate that output section with the
 *     program header named segment_code (which we defined above).
 *
 *  — Location Counter ".":
 *   The "." symbol, called the location counter (LC), indicates the current
 *   virtual address in the output where new data will be placed. By writing
 *     . = __rpi_phys_binary_load_addr;
 *   we say: "From now on, put any following sections at address 0x80000." If you
 *   later do ". = ALIGN(4);" that would round up the location counter to the
 *   next multiple of 4.
 *
 *  — KEEP(...):
 *   When you pass `--gc-sections` to the linker, it discards any code/data
 *   that is not referenced. We use KEEP() to force retention of the specified
 *   input section even if it appears unused. This is critical for the entrypoint,
 *   which might not be explicitly referenced by symbol name from our Rust code.
 *
 *=============================================================================
 */

SECTIONS
{
    /* Set LC to the physical RAM load address (0x80000). */
    . = __rpi_phys_binary_load_addr;

    /***************************************************************************
     * .text – code segment (Read + Execute permissions via PHDRS)
     *
     * The code our CPU executes lives here, beginning at LC (0x80000).
     *
     * KEEP(*(.text._start)) preserves the specific input section .text._start
     * (commonly defined in your assembly or via #[link_section = ".text._start"]).
     *************************************************************************/

    .text :
    {
        KEEP(*(.text._start))
    } :segment_code
}

/*=============================================================================
 * Notes
 *------------------------------------------------------------------------------
 * • If you need data sections (.data, .rodata, .bss), you would:
 *   1) Define additional program headers in PHDRS (e.g., segment_data PT_LOAD FLAGS(6)).
 *   2) In SECTIONS, after .text, set . = ALIGN(8) or similar, then do:
 *        .rodata : { *(.rodata*) } :segment_rodata
 *        .data   : { *(.data*) }   :segment_data
 *        .bss (NOLOAD) : { *(.bss*) *(COMMON) }
 *   3) Use PROVIDE() to give symbols like __bss_start, __bss_end for runtime init.
 *
 * • Location Counter (.) – Think of it as a bookmark in memory. Each section’s
 *   contents are "placed" at the address the LC holds when the linker processes
 *   that section. Changing "." manually moves this bookmark.
 *
 * • A Program "Segment" is a contiguous area of memory in the final program.
 *   Sections (like .text._start, .text.foo) get grouped into segments (like
 *   segment_code). The OS/firmware loads each segment into memory with its flags.
 *
 * • The KEEP() directive is important if you use `--gc-sections`. Otherwise,
 *   the linker removes unreferenced code. Your entrypoint lives in .text._start.
 *
 * • PHDRS vs. SECTIONS: PHDRS creates entries in the ELF program header table.
 *   SECTIONS controls how sections map to virtual addresses in memory. Each
 *   output section can be tied to a PHDRS entry by adding ":<segment_name>".
 *
 *=============================================================================
 */