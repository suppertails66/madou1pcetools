
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
.endme

.rombankmap
  bankstotal $1
  banksize $2000
  banks $1
.endro

.emptyfill $FF

.background "boot2_1121.bin"

;==============================================================================
; load new intro cutscene AC card data
;==============================================================================

.include "out/include/cutscenes.inc"

.bank $0 slot 5
.org $0006
.section "use new cutscene data 1" overwrite
  .db intro_dataSectorNumLo
  .db intro_dataSectorNumMid
  .db intro_dataSectorNumHi
  .dw intro_dataSectorSize
.ends

;==============================================================================
; fix title cutscene viewer bug
;==============================================================================

/*.unbackground $17F0 $17FF

.bank $0 slot 5
.org $01C0
.section "cutscene viewer fix 1" overwrite
  jsr cutsceneViewerFix
.ends

.bank $0 slot 5
.section "cutscene viewer fix 2" free
  cutsceneViewerFix:
    ; load correct slot2 bank for execution
    lda $2701
    tam #$04
    
    ; make up work
    lda $A023
    rts
.ends */
