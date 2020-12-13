
;.include "sys/pce_arch.s"
;.include "base/macros.s"

.memorymap
   defaultslot     0
   ; ROM area
   slotsize        $2000
   slot            0       $0000
   slot            1       $2000
   slot            2       $4000
   slot            3       $6000
   slot            4       $8000
   slot            5       $A000
   slot            6       $C000
   slot            7       $E000
   ; why
   slot            8       $3000
.endme

.rombankmap
  bankstotal $1
  banksize $2000
  banks $1
.endro

.emptyfill $FF

.background "boot_11.bin"

;==============================================================================
; 
;==============================================================================

;==================================
; don't use redundant data track
;==================================

.bank 0 slot 8
.org $01A7
.section "no alt CD_BASE 1" overwrite
  nop
  nop
  nop
.ends

;==================================
; test error messages
;==================================

; force "use an AC card" message
/*.bank 0 slot 8
.org $000D
.section "test 1" overwrite
  nop
  nop
.ends */

/*; force "clear the backup memory" message
.bank 0 slot 8
.org $0098
.section "test 1" overwrite
  jmp $317B
.ends */

; force "delete unneeded files" message
/*.bank 0 slot 8
.org $0098
.section "test 1" overwrite
  jmp $3150
.ends */

