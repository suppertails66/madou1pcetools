
.enumid 8
.enumid pseudoSlot_scriptTextGroup1
.enumid pseudoSlot_scriptTextGroup2

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
   ; pseudo-slot for script text, part 1
   slotsize        $4000
   slot            pseudoSlot_scriptTextGroup1       $8000
   ; pseudo-slot for script text, part 2
   slotsize        $6000
   slot            pseudoSlot_scriptTextGroup2       $8000
.endme

;.rombankmap
;  bankstotal $1A
;  banksize $2000
;  banks $1A
;.endro

.rombankmap
  bankstotal $17
  
  banksize $2000
  banks $C
  
  ; text group 1
  banksize $4000
  banks $1
  
  ; text group 2
  banksize $6000
  banks $1
  
  banksize $2000
  banks $9
.endro

.emptyfill $FF

.background "dungeon_12B1.bin"



;==============================================================================
; code: 16000 (text printing)
;==============================================================================

.bank $0B slot 3

.org $02E3
.include "out/script/include/strings_region0_table.inc"
.org $04B1
.include "out/script/include/strings_region1_table.inc"
.org $058B
.include "out/script/include/strings_region2_table.inc"
.org $045D
.include "out/script/include/strings_region3_table.inc"
.org $1365
.include "out/script/include/strings_region4_table.inc"
.org $136F
.include "out/script/include/strings_region5_table.inc"
.org $1391
.include "out/script/include/strings_region6_table.inc"
.org $13B3
.include "out/script/include/strings_region7_table.inc"
.org $1456
.include "out/script/include/strings_region8_table.inc"
.org $14F3
.include "out/script/include/strings_region9_table.inc"
.org $15AB
.include "out/script/include/strings_region10_table.inc"
.org $166D
.include "out/script/include/strings_region11_table.inc"
.org $179F
.include "out/script/include/strings_region12_table.inc"
.org $17E7
.include "out/script/include/strings_region13_table.inc"
.org $17F1
.include "out/script/include/strings_region14_table.inc"
.org $17FB
.include "out/script/include/strings_region15_table.inc"
.org $1AB8
.include "out/script/include/strings_region16_table.inc"
.org $1B75
.include "out/script/include/strings_region17_table.inc"
.org $1CE6
.include "out/script/include/strings_region18_table.inc"
.org $1CCA
.include "out/script/include/strings_region19_table.inc"
.org $1C42
.include "out/script/include/strings_region20_table.inc"

;==============================================================================
; 18000 (text group 1)
;==============================================================================

;.rombankmap
;  bankstotal $1
;  banksize $4000
;  banks $1
;.endro

/*.rombankmap
  bankstotal $3
  
  banksize $18000
  banks $1
  
  banksize $4000
  banks $1
  
  banksize $18000
  banks $1
.endro */


.bank $C slot pseudoSlot_scriptTextGroup1


;.unbackground $18000 $1BFFF

.unbackground $18000 $1AFB5
; reserve space for the one table that's stored here for some reason...
.unbackground $1AFC6 $1BFFF

; this is not in the same bank as everything else...
.org $2FB6
.include "out/script/include/strings_region21_table.inc"

; script binary data
.include "out/script/include/strings_region0_bin.inc"
.include "out/script/include/strings_region1_bin.inc"
.include "out/script/include/strings_region3_bin.inc"
.include "out/script/include/strings_region4_bin.inc"
.include "out/script/include/strings_region5_bin.inc"
.include "out/script/include/strings_region6_bin.inc"
.include "out/script/include/strings_region7_bin.inc"
.include "out/script/include/strings_region8_bin.inc"
.include "out/script/include/strings_region9_bin.inc"
.include "out/script/include/strings_region10_bin.inc"
.include "out/script/include/strings_region11_bin.inc"
.include "out/script/include/strings_region12_bin.inc"
.include "out/script/include/strings_region13_bin.inc"
.include "out/script/include/strings_region14_bin.inc"
.include "out/script/include/strings_region15_bin.inc"
.include "out/script/include/strings_region16_bin.inc"
.include "out/script/include/strings_region17_bin.inc"
.include "out/script/include/strings_region18_bin.inc"
.include "out/script/include/strings_region19_bin.inc"
.include "out/script/include/strings_region20_bin.inc"
.include "out/script/include/strings_region21_bin.inc"

;.section "skip cancelled voice clip wait time 2" free
;  
;.ends

;==============================================================================
; 1C000 (text group 2)
;==============================================================================

;.rombankmap
;  bankstotal $1
;  banksize $6000
;  banks $1
;.endro

/*.rombankmap
  bankstotal $3
  
  banksize $1C000
  banks $1
  
  banksize $6000
  banks $1
  
  banksize $12000
  banks $1
.endro */

;.unbackground $1C000 $21FFF
; reserve unneeded space at end for main code's use
.unbackground $1C000 $201FF

.bank $D slot pseudoSlot_scriptTextGroup2

.include "out/script/include/strings_region2_bin.inc"





