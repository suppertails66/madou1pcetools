
;.include "sys/pce_arch.s"
;.include "base/macros.s"

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
;   ; pseudo-slot for script text, part 1
;   slotsize        $4000
;   slot            pseudoSlot_scriptTextGroup1       $8000
;   ; pseudo-slot for script text, part 2
;   slotsize        $6000
;   slot            pseudoSlot_scriptTextGroup2       $8000
.endme

.rombankmap
  bankstotal $1A
  banksize $2000
  banks $1A
.endro

.emptyfill $FF

.background "dungeon_12B1.bin"

;==============================================================================
; global defines
; TODO: move to a common include file
;==============================================================================

;===============================================
; bios
;===============================================

.define _A $F8
.define _AL $F8
.define _AH $F9
.define _B $FA
.define _BL $FA
.define _BH $FB
.define _C $FC
.define _CL $FC
.define _CH $FD
.define _D $FE
.define _DL $FE
.define _DH $FF

.define AD_STOP $E042
.define AD_STAT $E045

.define MA_MUL8U $E0BD
.define MA_MUL8S $E0C0
.define MA_MUL16U $E0C3
.define MA_DIV16U $E0C6
.define MA_DIV16S $E0C9

.define patternW 8
.define patternH 8
.define patternSize $20
.define patternSize1bpp 8

;===============================================
; memory
;===============================================

.define scratch0 $0000
.define scratch1 $0001
.define scratch2 $0002
.define scratch3 $0003
.define scratch4 $0004
.define scratch5 $0005
.define scratch6 $0006
.define scratch7 $0007
.define scratch8 $0008
.define scratch9 $0009
.define scratch10 $000A
.define scratch11 $000B
.define scratch12 $000C
.define scratch13 $000D
.define scratch14 $000E
.define scratch15 $000F
  
.define memoryBase $2701

.define buttonsPressed $2228
.define buttonsTriggered $222D

.define scriptStatusArray $30D4
  .define script0Status $30D4
  .define script1Status $30D5
  .define script2Status $30D6

.define adpcmPlayingFlag $30CB

;===============================================
; "global" routines
;===============================================

.define addActiveTask $4509
.define addFrameSyncedTask $4588
.define addIdleTask $4601

;===============================================
; task targets
;===============================================

.define setButtonReaction $6863

;===============================================
; constants
;===============================================
  
.define buttonfield_button1 $01
.define buttonfield_button2 $02

.define memoryBasePage $68

;==============================================================================
; code: 16000
;==============================================================================

.unbackground $17E58 $17FFF

.bank $0B slot 3
.org $0D0E
.section "no adpcm wait text script 1" overwrite
  jmp textScriptAdpcmSkipCheck
.ends

.bank $0B slot 3
.section "no adpcm wait text script 2" free
  textScriptAdpcmSkipCheck:
    tma #$10
    pha
      lda #memoryBasePage+(:cancelAdpcm)
      tam #$10
      
      ; actually, we don't even need to call the check routine.
      ; if this code runs at all, a button was pressed to advance
      ; the box.
      ; we just need to make sure that if a voice clip is not playing,
      ; we don't cancel the whole sequence.
;      jsr checkAdpcmCancelConditions_noScriptCheck
;      bcs @done

      lda adpcmPlayingFlag
      cmp #$00
      beq @done
      
      ; cancel adpcm
      jsr cancelAdpcm
      
      pla
      tam #$10
      jmp $6D13
;      lda (adpcmCancelled+0).w
;      tax
    @done:
    pla
    tam #$10
    ; make up work
    lda $30CB
    jmp $6D11
    
    
.ends





;==============================================================================
; cutscenes
;==============================================================================

.include "out/include/cutscenes.inc"

; intro is in boot2

.bank $17 slot 3
.org $1BE8
.section "use new cutscene data 2" overwrite
  .db preboss_dataSectorNumLo
  .db preboss_dataSectorNumMid
  .db preboss_dataSectorNumHi
  .dw preboss_dataSectorSize
.ends

.bank $17 slot 3
.org $1C4C
.section "use new cutscene data 3" overwrite
  ; would you believe wla-dx categorically cannot output a three-byte int
  ; if you're not targeting the super famicom
;  .dw ending_dataSectorNum
  .db ending_dataSectorNumLo
  .db ending_dataSectorNumMid
  .db ending_dataSectorNumHi
  .dw ending_dataSectorSize
.ends

;==============================================================================
; code: 2A000
;==============================================================================

.unbackground $2D160 $2DFFF

;===============================================
; "local" routines
;===============================================

.define loadSubBank $6752

;===============================================
; free up some space by moving code
; out of the main bank
;===============================================

/*.bank $15 slot 3
.org $03A4
.section "free up space 1" overwrite
  ; ensure page $2C000 is loaded
  tma #$10
  pha
    jsr loadSubBank
    jsr doFreeSpaceThing
  pla
  tam #$10
  rts
  
.ends

.bank $16 slot 4
.section "free up space 2" free
  doFreeSpaceThing:
    stz $6007
    ; loop
    -:
      stz $00FA
      stz $00FB
      lda $6005
      sta $00F8
      lda $6006
      sta $00F9
      lda #$0C
      sta $00FF
      lda #$00
      sta $00FE
      jsr $E03C
      cmp #$00
      bne -
    rts 
.ends

.unbackground $03A4+13 $03C4*/

.bank $15 slot 3
.org $0504
.section "free up space 1" overwrite
  ; ensure page $2C000 is loaded
  jsr loadSubBank
  jmp doFreeSpaceThing
  
.ends

.bank $16 slot 4
.section "free up space 2" free
  doFreeSpaceThing:
    lda #$01
    sta $30CC
    stz $6005
    stz $6006
;    jsr loadSubBank
    jsr $64AF
    ldx $31BD
    lda $6F7F,X
    sta $0046
    lda $6F8E,X
    sta $0047
    lda $6FFF,X
    sta $64DE
    lda $700D,X
    sta $64DF
    lda $31AB
    sta $64DD
    lda $31BD
    cmp #$03
    beq +
      stz $31AB
    +:
    jmp $646C
.ends

.unbackground $2A504+6 $2A540

;===============================================
; "trampoline" for sub bank calls
;===============================================

.bank $15 slot 3
.section "sub bank trampoline" free
  retAddrMem:
    .db $00,$00

  subBankTrampoline:
/*    tma #$10
    pha
      jsr loadSubBank
    pla
    tam #$10
    rts*/
    
    ; save old scratch space
/*    lda $0026
    sta (retAddrMem+0).w
    lda $0027
    sta (retAddrMem+1).w*/
    
    ; pull ret addr to $0026
    pla
    sta $0026
    pla
    sta $0027
    
    ; restore ret addr
    lda $0026
    clc
    adc #$02
    tax
    cla
    adc $0027
    
    pha
    txa
    pha
    
    ; ensure page $2C000 is loaded
    tma #$10
    pha
      jsr loadSubBank
      
      ; push ret addr
      lda #>(@retPos-1)
      pha
      lda #<(@retPos-1)
      pha
      
      ; fetch target routine addr
      ldy #$02
      lda ($0026),Y
      pha
      dey
      lda ($0026),Y
      pha
      
      ; ret into target routine
      rts
    @retPos:
    pla
    tam #$10
    
    ; restore scratch space
/*    lda (retAddrMem+0).w
    sta $0026
    lda (retAddrMem+1).w
    sta $0027*/
    
    rts
    
.ends

;===============================================
; button press cancel condition check
;===============================================

.bank $15 slot 3
.section "generic task runner" free
  genericTaskRunner:
    jsr subBankTrampoline
    genericTaskRunner_taskAddr:
    .dw $0000
    rts
.ends

.bank $16 slot 4
.section "button press adpcm cancel check" free
  ; this is set after a cancellation to indicate all remaining
  ; voice clips in the sequence should be skipped
  adpcmCancelled:
    .db $00
    
  ; returns carry clear if cancel allowed, set if not allowed
  checkAdpcmCancelConditions:
    ; check if previous cancellation occurred
    lda (adpcmCancelled+0).w
    cmp #$00
    bne @pass
    
    ; if any script is active, do not allow cancel
    ; (this case is handled separately, in the voice sync opcode's logic)
    lda script0Status
    ora script1Status
    ora script2Status
    bne @fail
    
    @remainder:
    
    ; check triggered buttons to see if button 1 has been activated this frame
    lda buttonsTriggered
;    and #(buttonfield_button1|buttonfield_button2)
    and #$FF
    beq @fail
    
    @pass:
    clc
    rts
    
    @fail:
    sec
    rts
  
/*  checkAdpcmCancelConditions_noScriptCheck:
    ; check if previous cancellation occurred
    lda (adpcmCancelled+0).w
    cmp #$00
    bne checkAdpcmCancelConditions@pass
    
    jmp checkAdpcmCancelConditions@remainder */
    
    
  
  cancelAdpcm:
    jsr AD_STOP
    ; ???
;    stz $30CB

    lda #$FF
    sta (adpcmCancelled+0).w
    
    rts
  
  adpcmGapWaitTimer:
    .db $00
  
  startAdpcmGapWaitTask:
    ; initialize timer
    lda #$1E
    sta (adpcmGapWaitTimer+0).w
    
    lda #<(adpcmGapWaitTask_sub-1)
    sta (genericTaskRunner_taskAddr+0).w
    lda #>(adpcmGapWaitTask_sub-1)
    sta (genericTaskRunner_taskAddr+1).w
    
    ldy #$01
    jsr addIdleTask
    lda (genericTaskRunner+0).w
    ldx #$A9
    rts
  
  adpcmGapWaitTask_sub:
    jsr checkAdpcmCancelConditions
    bcs +
      jsr cancelAdpcm
;      jmp @end
      jsr addActiveTask
      lda $608C
      ldx #$A9
      rts
    +:
    
    ; decrement timer
    dec (adpcmGapWaitTimer+0).w
    bne @wait
    
    @end:
      ; go to next clip
      ldy #$01
      jsr addIdleTask
      lda $608C
      ldx #$A9
      rts
    
    @wait:
      ; continue loop
      ldy #$01
      jsr addIdleTask
      lda (genericTaskRunner+0).w
      ldx #$A9
      rts
    
    
.ends

;===============================================
; allow adpcm cancel with button press
; (?)
;===============================================

/*.bank $15 slot 3
.org $022B
.section "button press adpcm cancel 1-1" overwrite
  jsr subBankTrampoline
  .dw buttonPressAdpcmCancelCheck1-1
  rts
  
.ends

.bank $16 slot 4
.section "button press adpcm cancel 1-2" free
  buttonPressAdpcmCancelCheck1:
    jsr checkAdpcmCancelConditions
    bcs @noCancel
    
    ; cancel adpcm
    jsr cancelAdpcm
    
    ; go on with normal stuff
;    jmp $63DF
    ; better yet, drop through -- this will allow the normal idle loop
    ; to continue until the stop command has fully processed
    ; (the manual warns of a slight delay due to the playback rate)
    
    @noCancel:
    ; make up work
    ldy #$01
    jsr addIdleTask
    lda $6217
    ldx #$A9
    rts
.ends */

;===============================================
; allow adpcm cancel with button press
; (map, many others)
;===============================================

;.bank 3 slot 1
;.org $01DF
;.section "titlecursor" overwrite
;  ld d,$58  ; x-position (orig: 60)
;.ends

.bank $15 slot 3
.org $03D4
.section "button press adpcm cancel 2-1" overwrite
  ; ensure page $2C000 is loaded
/*  lda #memoryBasePage+$16
  tam #$10
  jmp buttonPressAdpcmCancelCheck*/
  
/*  tma #$10
  pha
    jsr loadSubBank
  pla
  tam #$10
  rts */
  
  jsr subBankTrampoline
  .dw buttonPressAdpcmCancelCheck2-1
  rts
  
.ends

.bank $16 slot 4
.section "button press adpcm cancel 2-2" free
  buttonPressAdpcmCancelCheck2:
    jsr checkAdpcmCancelConditions
    bcs @noCancel
    
      ; cancel adpcm
      jsr cancelAdpcm
    
    ; go on with normal stuff
;    jmp $63DF
    ; better yet, drop through -- this will allow the normal idle loop
    ; to continue until the stop command has fully processed
    ; (the manual warns of a slight delay due to the playback rate)
    
    @noCancel:
    ; make up work
    ldy #$01
    jsr addIdleTask
    lda $63C5
    ldx #$A9
    rts
  
/*  doFullAdpcmCancellationCheck2:
    ; default wait time
    ldy #$1E
    
    pha
      lda (adpcmCancelled+0).w
      cmp #$00
      beq @done
      
      ; cancelled previously -- set wait time to 1
      ; (the actual clip will be skipped by other logic)
;      jmp $63E8
      ldy #$01
    @done:
    pla
    
    ; launch voice clip list processing task?
    jsr addIdleTask
    lda $608C
    ldx #$A9
    rts */
    
  doPostAdpcmUncancel2:
    stz (adpcmCancelled+0).w
    jmp $646C
.ends

; if cancellation occurred, skip all subsequent voice clips

.bank $15 slot 3
.org $03EB
.section "button press adpcm cancel 2-3" overwrite
  ; triggered when NOT at end of voice clip list
  
  ; this is safe -- sub bank is loaded immediately before
;  jmp doFullAdpcmCancellationCheck2
  
  ; use a new, alternate task instead
/*  ldy #$01
;  jsr addIdleTask
  jsr addActiveTask
  lda (startAdpcmGapWaitTask+0).w
  ldx #$A9
  rts */
  jmp startAdpcmGapWaitTask
  
.ends

.bank $15 slot 3
.org $03E8
.section "button press adpcm cancel 2-4" overwrite
  ; triggered when at end of voice clip list
  
  ; this is safe -- sub bank is loaded immediately before
  jmp doPostAdpcmUncancel2
  
.ends

;===============================================
; allow adpcm cancel with button press
; (?)
;===============================================

/*.bank $15 slot 3
.org $0402
.section "button press adpcm cancel 3-1" overwrite
  jsr subBankTrampoline
  .dw buttonPressAdpcmCancelCheck3-1
  rts
  
.ends

.bank $16 slot 4
.section "button press adpcm cancel 3-2" free
  
  buttonPressAdpcmCancelCheck3:
    jsr checkAdpcmCancelConditions
    bcs @noCancel
    
    ; cancel adpcm
    jsr cancelAdpcm
    
    @noCancel:
    ; make up work
    ldy #$01
    jsr addIdleTask
    lda $63F6
    ldx #$A9
    rts
.ends */

;===============================================
; allow adpcm cancel with button press
; (?)
;===============================================

/*.bank $15 slot 3
.org $04F9
.section "button press adpcm cancel 4-1" overwrite
  jsr subBankTrampoline
  .dw buttonPressAdpcmCancelCheck4-1
  rts
  
.ends

.bank $16 slot 4
.section "button press adpcm cancel 4-2" free
  buttonPressAdpcmCancelCheck4:
    jsr checkAdpcmCancelConditions
    bcs @noCancel
    
    ; cancel adpcm
    jsr cancelAdpcm
    
    ; go on with normal stuff
;    jmp $63DF
    ; better yet, drop through -- this will allow the normal idle loop
    ; to continue until the stop command has fully processed
    ; (the manual warns of a slight delay due to the playback rate)
    
    @noCancel:
    ; make up work
    ldy #$01
    jsr addIdleTask
    lda $64E0
    ldx #$A9
    rts
.ends */

;===============================================
; eliminate certain wait times after voice
; cancellation
;===============================================

;.bank 3 slot 1
;.org $01DF
;.section "titlecursor" overwrite
;  ld d,$58  ; x-position (orig: 60)
;.ends

.bank $15 slot 3
.org $026E
.section "skip cancelled voice clip wait time 1" overwrite
  jmp cancelledVoiceWaitSkipCheck
.ends

.bank $16 slot 4
.section "skip cancelled voice clip wait time 2" free
  cancelledVoiceWaitSkipCheck:
    ; make up work
    sta $6004
    ldy #$0A
    
    pha
      lda (adpcmCancelled+0).w
      cmp #$00
      beq +
        ; short wait time
;        ldy #$01
        
        pla
        jsr addActiveTask
        lda $627C
        ldx #$A9
        rts
      +:
    pla
    
    jmp $6273
.ends



;==============================================================================
; code: 16000 (text printing)
;==============================================================================

.if 1 == 1

  ; old pattern transfer area + 1bpp temp storage
  .unbackground $16771 $16810
  ; old character conversion
  .unbackground $169AB $169FF

  ;=============================
  ; defines
  ;=============================

  ; literal font characters are defined starting from this index
  .define literalCharsBaseIndex $40
  ; dictionary characters start from this index
  .define dictionaryCharsBaseIndex $A0
  
  .define endOpIndex $A
  
  .define spaceCharIndex $40
  .define digitCharsStartIndex $41
  .define goldSymbolCharIndex $9A
  .define space1pxCharIndex $8E
  .define space8pxCharIndex $9F
  .define space12pxCharIndex $9E
  
  ; width of the primary space character
  .define spaceCharWidth 4

  .define smallMsgBoxPixelW 144
  .define largeMsgBoxPixelW 304
  .define smallMsgBoxPatternW smallMsgBoxPixelW/8
  .define largeMsgBoxPatternW largeMsgBoxPixelW/8
  ; add 1 to account for possible overflow from left box from spaces in
  ; dynamic word wrapping
  .define smallMsgBoxSrcPatternOffsetW smallMsgBoxPatternW+1
  .define largeMsgBoxSrcPatternOffsetW largeMsgBoxPatternW
  .define msgBoxPixelH 48

  ; height of a text row in pixels
  .define textCharRowHeight 12

  ; number of character rows in the text box
  ; (original is 3)
  .define numBoxCharRows 4

  .define fontCharW 12
  .define fontCharH 11
  .define storedFontCharW 16
  .define storedFontCharH 11
  .define bytesPerStoredFontCharRow 2
  .define bytesPerStoredFontChar storedFontCharW*storedFontCharH/8
  
  ; width/height in patterns of the total area that is transferred to VRAM
  ; after a character is added.
  ; this needs to be sufficiently wide to span the maximum number of patterns that
  ; the newly transferred character may cover.
;  .define outputPatternTransferAreaPatternW 4
  ; 3 is the minimum for 1 char per frame.
  ; 4 is the minimum for 2 chars per frame.
  ; 7 is the maximum (i think?) due to use of the X register as an index
  .define outputPatternTransferAreaPatternW 4
  .define outputPatternTransferAreaPatternH 2
  ; various definitions derived from the above
  .define outputPatternTransferAreaNumPatterns outputPatternTransferAreaPatternW * outputPatternTransferAreaPatternH
  .define outputPatternTransferAreaByteSize outputPatternTransferAreaNumPatterns*32
  .define outputPatternTransferAreaPixelW outputPatternTransferAreaPatternW*8
  .define outputPatternTransferAreaPixelH outputPatternTransferAreaPatternH*8

  ; add 8 pixels for possible overflow due to dynamic word wrapping
  .define textCompAreaPixelW largeMsgBoxPixelW+8
  .define textCompAreaPixelH msgBoxPixelH
  .define textCompAreaPatternW textCompAreaPixelW/8
  .define textCompAreaPatternH textCompAreaPixelH/8
  .define textCompAreaNumPatterns textCompAreaPatternW*textCompAreaPatternH
  ;.define textCompAreaSize textCompAreaNumPatterns*64/8
  .define textCompAreaSize textCompAreaPixelW*textCompAreaPixelH/8
  .define textCompAreaRowBytes textCompAreaPixelW/8
  .define textCompAreaLargeBoxRowBytes largeMsgBoxPixelW/8
  .define textCompAreaSmallBoxRowBytes smallMsgBoxPixelW/8
  .define textCompAreaCharRowBytes textCharRowHeight*textCompAreaRowBytes
  
  ; separation between lines of box tilemap data
  .define vramBoxTilemapLineSeparation $40
  
  ; arrays for VRAM address line separation of pattern rows in text box,
  ; i.e. add this to a VRAM address to move to the next row for that
  ; box type
  .define vramLineSeparationLeftBox $120
  .define vramLineSeparationRightBox $120
  .define vramLineSeparationCenterBox $260
  ; same thing only for tilemap ID numbers (i.e. >> 4)
  .define vramTilemapLineSeparationLeftBox vramLineSeparationLeftBox>>4
  .define vramTilemapLineSeparationRightBox vramLineSeparationRightBox>>4
  .define vramTilemapLineSeparationCenterBox vramLineSeparationCenterBox>>4
  ; base VRAM address of each line for each box type
  .define vramBaseAddrLeftBox $0900
  .define vramBaseAddrRightBox $1020
  .define vramBaseAddrCenterBox $0900
  ; base VRAM address of the tilemap data for each line for each box type
  .define vramBaseTilemapAddrLeftBox $0581
  .define vramBaseTilemapAddrRightBox $0595
  .define vramBaseTilemapAddrCenterBox $0581

  .define numBoxTypes 3
  .define boxTypeLeft $00
  .define boxTypeRight $01
  .define boxTypeCenter $02
    
  .define dynamicStringBufferSize $F
  .define dynamicStringBufferNumberLabelSize $2
  .define dynamicStringBufferNonNumberPartSize dynamicStringBufferSize-dynamicStringBufferNumberLabelSize
  
  .define dynamicStringBuffer $71FC
  .define addToScratch4 $70D1

  ;=============================
  ; existing memory
  ;=============================

  .define extraTaskParam $0022
    .define scriptPtr extraTaskParam
  
  .define boxXArray $30DA
  .define boxYArray $30DD

  ;=============================
  ; existing routines
  ;=============================

  .define addInterpreterTaskWithCustomIdle $7032
  .define doubleIncScriptPtr $72DB
  .define incScriptPtr $72E1

  ;==============================================================================
  ; extra script strings
  ;==============================================================================
  
  .bank $10 slot 4
  .include "out/script/include/strings_region100_bin.inc"

  ; wla-dx does not allow this as a build-time check because it's not an
  ; immediate value, so we'll just have to hope
;  .define longestExtraStringSize strings_region100_1-strings_region100_0-1
;  .if (longestExtraStringSize > dynamicStringBufferNonNumberPartSize)
;    .print "Error: longestExtraStringSize too large for buffer"
;    .fail
;  .endif

  .define longestExtraDynamicStringSize strings_region100_0_size
  .if longestExtraDynamicStringSize > dynamicStringBufferNonNumberPartSize
    .print "Error: longestExtraStringSize too large for buffer"
    .fail
  .endif

  ;=============================
  ; free code
  ;=============================

  .bank $B slot 3
  .section "new text code" free
    ;=====
    ; memory
    ;=====
    
;    dteOn:
;      .db $00
    ; DTE state byte
    ; 0 = inactive, 1 = active
    ; if active, next char should be drawn from second byte of current
    ; position's entry
    dteState:
      .db $00
    
    ; array for low byte of pixel-level x-positions within each window box
    boxPixelXArrayLo:
      .rept numBoxTypes
        .db $00
      .endr
    
    ; array for high byte of pixel-level x-positions within each window box
    boxPixelXArrayHi:
      .rept numBoxTypes
        .db $00
      .endr
    
    ;=====
    ; data
    ;=====
    
    
    
    ;=====
    ; code
    ;=====
    
    ; shortcut for loading the extra resource bank
    loadNewTextRsrcBank:
      ; target slot 4
      lda #memoryBasePage+(:textCompArea)
      tam #$10
      rts
      
  .ends

  ;=============================
  ; correctly detect literal characters
  ; (and also dictionary entries)
  ;=============================

  .bank $B slot 3
  .org $0890
  .section "use new literal detection 1" overwrite
  ;  cmp #$80
    cmp #literalCharsBaseIndex
  .ends
  
  ;=============================
  ; skip normal automatic line wrapping
  ;=============================

  .bank $B slot 3
  .org $08DF
  .section "skip old box sanity checks 1" overwrite
;    jmp $690B
    ; do the auto-box-break check in case it turns out to be necessary
    jmp $68ED
  .ends

;  .bank $B slot 3
;  .org $091A
;  .section "do not increment script after literal read 1" overwrite
;    nop
;    nop
;    nop
;  .ends
  
  ;=============================
  ; fix dynamic number generation
  ;=============================

  .bank $B slot 3
  .org $118E
  .section "fix dynamic number generation 1" overwrite
    ; this is a conversion table for raw digits to SJIS values.
    ; the final entry is a space, because the game uses A as a placeholder
    ; value for "don't display this digit".
    ; we only need the low byte of each character.
    .rept 10 index count
      .dw digitCharsStartIndex+count
    .endr
    .dw space8pxCharIndex
  .ends

  .bank $B slot 3
  .org $11BB
  .section "fix dynamic number generation 2" overwrite
    ; copy only one digit when doing conversion from BCD
    nop
    nop
    nop
    nop
  .ends

  .bank $B slot 3
  .org $11BF
  .section "fix dynamic number generation 3" overwrite
    ; account for change in counter mechanics caused by previous change
;    cpy #$04
    cpy #$02
  .ends

  .bank $B slot 3
  .org $11EB
  .section "fix gold number generation 1" overwrite
    nop
    nop
    nop
    nop
  .ends

  .bank $B slot 3
  .org $11D7
  .section "fix gold number generation 2" overwrite
    ; adjust counter
;    ldy #$02
    ldy #$01
  .ends

  .bank $B slot 3
  .org $11EF
  .section "fix gold number generation 3" overwrite
    ; account for change in counter mechanics caused by previous change
;    cpy #$04
    cpy #$02
  .ends

  ;=============================
  ; revia final boss fix
  ;=============================

  ; revia's animation is extremely short.
  ; normally, it's always followed by the enemy's attack message.
  ; however, against the final boss (only), using revia at the start of
  ; the battle, before it has fully advanced forward and become vulnerable,
  ; generates no message.
  ; what happens at this point is that the game attempts to immediately
  ; move on to the next turn.
  ; it triggers the "it's arle's turn" message and then, crucially,
  ; attempts to open the menu without waiting for any pending messages
  ; to complete.
  ; now, it just so happens that, with the original game's messages,
  ; the game can get everything printed juuust a frame or two before
  ; the menu opens, which works "correctly" aside from making the message
  ; virtually impossible to read.
  ; however, with our new timing, it takes a few extra frames to get everything
  ; printed... and this causes the menu to open while we're in the middle of
  ; printing.
  ; this blows everything up.
  ; so, to solve this, we add a delay of a few extra frames to the end of the
  ; revia animation.
  
  ; if you think that's a long explanation, you should have seen how long it
  ; took me to figure out the problem.
  ; (and how much longer it took to fix it)

;  .bank $9 slot 4
;  .org $17EE
;  .section "revia final boss fix 1" overwrite
;    ; number of frames to sustain final frame of revia animation
;    .db #$05+5
;  .ends
  
  .unbackground $13C00 $13FFF
  
  .bank $8 slot 3
  .org $0A33
  .section "revia final boss fix 1" overwrite
    .dw newReviaAnimData
  .ends
  
;  .bank $9 slot 4
;  .org $17EC
;  .section "revia final boss fix 2" overwrite
;    .dw newReviaFinalFrame
;  .ends
  
  .bank $9 slot 4
  .section "revia final boss fix 3" free
    newReviaAnimData:
      ; ???
      .db $04
      ; stuff
      .db $FE $FF $06 $D2 $80 $03 $DB $80 $03 $E4 $80 $03 $F5 $80 $03
      .db $06 $81 $03 $F5 $80 $03 $28 $81 $03 $39 $81 $03 $4A $81 $03 $6B
      .db $81 $05 $84 $81 $05
      ; old final frame
      .dw $9D81
      .db $05
      ; new final frame, which is simply empty.
      ; yes, this was necessary.
      .dw newReviaFinalFrame
      .db $0A ; extra delay before animation is considered complete
      ; terminator
      .dw $FFFF
      .db $03
  
    newReviaFinalFrame:
      .db $00 ; subcomponent count?
      
      ; subframe 0
/*      .dw $0090 ; ?
      .dw $00E8 ; ?
      .dw $0200 ; ?
      .dw $3185 ; ?
      
      ; subframe 1
      .dw $0090 ; ?
      .dw $0108 ; ?
      .dw $0220 ; ?
      .dw $3185 ; ?
      
      ; subframe 2
      .dw $0090 ; ?
      .dw $0128 ; ?
      .dw $0240 ; ?
      .dw $3085 ; ? */
      
      ; subframe 3
;      .dw $0090 ; ?
;      .dw $0128 ; ?
;      .dw $0240 ; ?
;      .dw $3085 ; ?
  .ends
  
  ;=============================
  ; op21 fixes
  ;=============================

  .bank $B slot 3
  .org $10E0
  .section "op21 fixes 1" overwrite
    tma #$10
    pha
      jsr loadNewTextRsrcBank
      jsr doNewOp21Logic
    pla
    tam #$10
    jmp $7145
  .ends
  
  ; in extra bank!
  .bank $10 slot 4
  .section "op21 fixes 2" free
    doNewOp21Logic:
      ; get ?
      lda $30AA
      asl
      asl
      tay
      ; ?
      lda $30AB,Y
      tay
      lda $313B,Y
      bne @fileInUse
        tii strings_region100_4,dynamicStringBuffer,strings_region100_4_size
        lda #strings_region100_4_size
        jsr addToScratch4
        bra @done
      @fileInUse:
      
      ; add right-alignment padding
      pha
        tii strings_region100_5,dynamicStringBuffer,strings_region100_5_size
        lda #strings_region100_5_size
        jsr addToScratch4
      pla
      
      ; get floor number
      lda $313F,Y
      ina
      cmp #$0B
      bcc @notBasement
      @basement:
        sbc #$0A
        pha
          tii strings_region100_2,dynamicStringBuffer+strings_region100_5_size,strings_region100_2_size
          lda #strings_region100_2_size
          jsr addToScratch4
        pla
        
        ; floor number
        jsr $E0B4
        bit #$F0
        bne +
          ora #$A0
        +:
        jsr $71CC
        
        bra @addFloorMarker
      @notBasement:
        ; bcd conversion
        jsr $E0B4
        bit #$F0
        bne +
          ora #$A0
        +:
        jsr $71A4
      @addFloorMarker:
      cly
      -:
        lda strings_region100_3.w,Y
        sta (scratch4)
        
        inc scratch4
        bne ++
          inc scratch5
        ++:
        
        iny
        cpy #strings_region100_3_size
        bne -
      
      @done:
      rts
  .ends

  ;=============================
  ; op18 fixes
  ;=============================

  .bank $B slot 3
  .org $114B
  .section "op18 fixes 1" overwrite
    tma #$10
    pha
      jsr loadNewTextRsrcBank
      jsr doNewOp18Logic
    pla
    tam #$10
    jmp $716F
  .ends
  
  ; in extra bank!
  .bank $10 slot 4
  .section "op18 fixes 2" free
    doNewOp18Logic:
      ; get floor number
      lda $312B
      ina
      cmp #$0B
      bcc @notBasement
      @basement:
        sbc #$0A
        pha
          ; "basement floor "
          tii strings_region100_0,dynamicStringBuffer,strings_region100_0_size
          
          lda #strings_region100_0_size
          jsr addToScratch4
        pla
        bra @done
      @notBasement:
        pha
          ; "floor "
          tii strings_region100_1,dynamicStringBuffer,strings_region100_1_size
          
          lda #strings_region100_1_size
          jsr addToScratch4
        pla
      @done:
      
      ; make up work
      jsr $E0B4
      bit #$F0
      bne +
        ora #$A0
      +:
      jsr $71CC
      
      rts
  .ends

  ;=============================
  ; op11 fixes
  ;=============================

  .bank $B slot 3
  .org $109D
  .section "op11 fixes 1" overwrite
    ; don't prepend gold symbol to amount
    jmp $70AD
  .ends

  .bank $B slot 3
  .org $10C9
  .section "op11 fixes 2" overwrite
    ; append new gold symbol to amount
    jmp op11AppendGoldSymbol
  .ends

  .bank $B slot 3
  .section "op11 fixes 3" free
    op11AppendGoldSymbol:
      lda #goldSymbolCharIndex
      sta (scratch4)
      inc scratch4
      bne +
        inc scratch5
      +:
      
      ; make up work
      lda #$0A
      sta (scratch4)
      jmp $70CD
  .ends

  ;=============================
  ; correctly compute word width
  ; for dynamic wrapping with
  ; use of dynamic insertion
  ; opcodes
  ;=============================

  ; we need to account for material that may be appended to a
  ; dynamic word (e.g. monster names) after the subscript containing
  ; the name has executed (most commonly, one or more punctuation marks).
  ; we do this by pre-reading the characters following the target op
  ; and writing their width to a location that the sub-script can use
  ; when computing its own width.
  ; we must take care that this value is kept at zero when not in use
  
  .bank $B slot 3
  .org $1219
  .section "dynamic word wrap post-insertion fix 1" overwrite
    jsr checkSubScriptWordWrapContent
  .ends
  
  .bank $B slot 3
  .org $1232
  .section "dynamic word wrap post-insertion fix 2" overwrite
    jsr checkSubScriptWordWrapContentEnd
  .ends

  .bank $B slot 3
  .section "dynamic word wrap post-insertion fix 3" free
    parentScriptTrailerContentWidth:
      .db $00
    
    checkSubScriptWordWrapContent:
      phy
      ; address of new script: must save
      lda scratch2
      pha
      lda scratch3
      pha
        ; if space not yet seen, do nothing.
        ; (space not seen implies we are already in the middle of a word,
        ; in which case we're screwed anyway, or are at the start of the
        ; line, in which case this word cannot possibly wrap anyway)
        lda dynamicWordWrap_spaceSeen.w
        bne +
          stz parentScriptTrailerContentWidth.w
          bra @skip
        +:
          ; save script state
          jsr dynamicWordWrap_saveScriptPos
          
          ; fetch next char
          lda (scriptPtr)
          
          ; advance script ptr
          tay
            jsr loadNewTextRsrcBank
          tya
          jsr processInputCharacterAndUpdateScriptPtr
          
          ; evaluate size
          jsr dynamicWordWrap_computeWordWidth
          
          ; save low byte of size (should not be more than 256 pixels wide!)
          lda scratch11
          sta parentScriptTrailerContentWidth.w
          
          ; restore original script state
          jsr dynamicWordWrap_restoreScriptPos
        @skip:
      pla
      sta scratch3
      pla
      sta scratch2
      ply
      
      ; make up work
      ldx $681B.w
      rts
    
    checkSubScriptWordWrapContentEnd:
      stz parentScriptTrailerContentWidth.w
      
      ; make up work
      dec $681B.w
      rts
  .ends
  
  ;=============================
  ; new literal handler logic
  ;=============================
  
  .bank $B slot 3
  .org $090B
  .section "extra literal prep 1" overwrite
    jmp doExtraLiteralPrep
  .ends

  .bank $B slot 3
  .section "extra literal prep 2" free
    
    ; X = box type
    ; Y = next character's raw ID
    doExtraLiteralPrep:
      jsr doDynamicWordWrapCheck
      
      ; handle autobreak
      lda dynamicWordWrap_autoBreakOccurred.w
      beq +
        ; increment Y-pos
;        inc $30DD,X
        ; reset x-pos
;        jsr resetCurrentBoxPixelX_withMakeup
        ; hand this off to the wait-for-box-input routine,
        ; as the original game does
        jmp $6950
      +:
      
      tma #$10
      pha
        phx
          jsr loadNewTextRsrcBank
          jsr processInputCharacterAndUpdateScriptPtr
          
        ; make sure the box type is preserved
        plx
        phx
        
          ;=====
          ; now, A = next character's index
          ; and X = box type
          ;=====
          
          ; character composition + conversion...
          jsr addCharAndSetUpTransfer
        
        ; restore window type index
        plx
        
      pla
      tam #$10
      
      ;=====
      ; determine if we can transfer a second character
      ; (we want to double printing speed to two characters per frame)
      ;=====
      
      ; fetch next character
      lda (scriptPtr)
      tay
      
      jsr doDynamicWordWrapCheck
      
      ; if autobreak will occur for the next character,
      ; no second transfer is possible
      ; (because the new character would be noncontiguous with the previous,
      ; and we only do one transfer to VRAM).
      ; so just ignore until the next iteration
      lda dynamicWordWrap_autoBreakOccurred.w
      bne @noSecondCharTransfer
      
      ; permanently swap in new rsrc bank
      jsr loadNewTextRsrcBank
      
      ; if next char is not an opcode, do another character transfer,
      ; preserving first one's src params
      cpy #literalCharsBaseIndex
      bcc @noSecondCharTransfer
        ; save old src params
        lda inputPatternTransferPatternX.w
        pha
        lda inputPatternTransferPatternY.w
        pha
        lda outputPatternTransferPatternX.w
        pha
        lda outputPatternTransferPatternY.w
        pha
          phx
            jsr processInputCharacterAndUpdateScriptPtr
            
          ; make sure the box type is preserved
          plx
          phx
            ; character composition + conversion...
            jsr addCharAndSetUpTransfer
          ; restore window type index
          plx
        ; restore old src params
        pla
        sta outputPatternTransferPatternY.w
        pla
        sta outputPatternTransferPatternX.w
        pla
        sta inputPatternTransferPatternY.w
        pla
        sta inputPatternTransferPatternX.w
      @noSecondCharTransfer:
      
      ;=====
      ; set up for output
      ;=====
      
      jsr loadNewTextRsrcBank
      jsr formatSrcCharAreaForOutput
      
      ;=====
      ; flag transfer as active?
      ;=====
      
      lda #$01
      sta $30D7,X

      ;=====
      ; done
      ;=====
      
      @done:
      
      jmp $691D
      
    
    maxBoxPixelXArrayLo:
      .db <smallMsgBoxPixelW
      .db <smallMsgBoxPixelW
      .db <largeMsgBoxPixelW
    maxBoxPixelXArrayHi:
      .db >smallMsgBoxPixelW
      .db >smallMsgBoxPixelW
      .db >largeMsgBoxPixelW
    
    dynamicWordWrap_spaceSeen:
      .db $00
    dynamicWordWrap_autoBreakOccurred:
      .db $00
;    dynamicWordWrap_currentWidth:
;      .db $00
    
    ; X = box type
    ; Y = next raw input index
    doDynamicWordWrapCheck:
      ;=====
      ; ignore opcodes
      ;=====
      
      cpy #literalCharsBaseIndex
      bcs +
        stz dynamicWordWrap_autoBreakOccurred.w
        rts
      +:
      
      ;=====
      ; save initial script pos
      ;=====
      
      jsr dynamicWordWrap_saveScriptPos
      
      ;=====
      ; what mode are we in?
      ;=====
      
      lda dynamicWordWrap_spaceSeen.w
;      cmp #$00
      beq @spaceNotSeen
      
      ;=====
      ; space previously encountered
      ;=====
      
      @spaceSeen:
        
        ;=====
        ; get first char's index
        ;=====
        
        jsr loadNewTextRsrcBank
        jsr processInputCharacterAndUpdateScriptPtr
        
        ;=====
        ; if a space, do nothing
        ;=====
        
        cmp #spaceCharIndex
        beq @cancel
        
        ;=====
        ; determine word's width
        ;=====
        
        jsr dynamicWordWrap_computeWordWidth
        
        ;=====
        ; decide if linebreak needed
        ;=====
        
        @doFinalChecks:
        
        ;=====
        ; does new width exceed width of line?
        ;=====
          
        ; X is still the box type

        ; add current pixel x-pos to this word's width
        lda boxPixelXArrayLo.w,X
        clc
        adc scratch11
        sta scratch11
        lda boxPixelXArrayHi.w,X
        adc scratch12
        sta scratch12
        
        ; subtract total width from maximum
        lda maxBoxPixelXArrayLo.w,X
        sec
        sbc scratch11
        lda maxBoxPixelXArrayHi.w,X
        sbc scratch12
        
        ; if no overflow, we don't need to break the line
        bcs @cancel
          
;          ; break the line (FIXME: no overflow check!!)
;          ; increment Y-pos
;          inc $30DD,X
;          ; reset x-pos
;          jsr resetCurrentBoxPixelX_withMakeup
        
        ; flag that autobreak occurred
        lda #$01
        sta dynamicWordWrap_autoBreakOccurred.w
        bra @done
      
      ;=====
      ; space not yet encountered
      ;=====
      
      @spaceNotSeen:
        ;=====
        ; get first char's index
        ;=====
        
        jsr loadNewTextRsrcBank
        jsr processInputCharacterAndUpdateScriptPtr
        
        ;=====
        ; if not a space, do nothing
        ;=====
        
        cmp #spaceCharIndex
        bne @cancel
        
        ;=====
        ; space found: switch mode
        ;=====
        inc dynamicWordWrap_spaceSeen.w
        ; !!!!! DROP THROUGH !!!!!
      @cancel:
      stz dynamicWordWrap_autoBreakOccurred.w
      @done:
;      jmp dynamicWordWrap_restoreScriptPos
      ; !!!!! DROP THROUGH !!!!!
      dynamicWordWrap_restoreScriptPos:
        ; restore initial script state
        lda scratch14
        sta scriptPtr+0
        lda scratch15
        sta scriptPtr+1
        lda scratch4
        sta dteState.w
        ; initial index
        ldy scratch5
        ; slot
        lda scratch13
        tam #$10
        rts
        
      dynamicWordWrap_saveScriptPos:
        ; scratch14 = initial script ptr
        lda scriptPtr+0
        sta scratch14
        lda scriptPtr+1
        sta scratch15
        ; scratch4 = initial dte state
        lda dteState.w
        sta scratch4
        
        ; scratch5 = initial index
        sty scratch5
        
        ; scratch13 = slot 4 bank
        tma #$10
        sta scratch13
        rts
      
      ; returns scratch11-12 as pixel width of current word
      dynamicWordWrap_computeWordWidth:
        ; scratch11-12 = width of read input
        stz scratch11
        stz scratch12
        
        ; do nothing if first char is op
        cmp #literalCharsBaseIndex
        bcc @end
        
        ; do nothing if first char is space
        cmp #spaceCharIndex
        beq @done
        
        @wordSearchLoop:
          ; Y = physical index of target character
          sec
          sbc #literalCharsBaseIndex
          tay
          ; add width of character to total width
          lda fontWidthTable.w,Y
          clc
          adc scratch11
          sta scratch11
          cla
          adc scratch12
          sta scratch12
          
          ; fetch next char
          lda scratch13
          tam #$10
          lda (scriptPtr)
          
          ; if we encounter an opcode, done
          cmp #literalCharsBaseIndex
          bcc @done
          
          ; process raw input
          tay
          jsr loadNewTextRsrcBank
          jsr processInputCharacterAndUpdateScriptPtr
          
          ; if we encounter a space character, done
          cmp #spaceCharIndex
;          beq @done
;          bra @wordSearchLoop
          bne @wordSearchLoop
        @done:
        
        ; if we encountered an end op, account for parent script's
        ; trailing content
        cmp #endOpIndex
        bne +
          lda parentScriptTrailerContentWidth.w
          clc
          adc scratch11
          sta scratch11
          cla
          adc scratch12
          sta scratch12
        +:
        
        @end:
        rts
      
/*      ;=====
      ; if next char is an opcode, do nothing
      ;=====
      cpy #literalCharsBaseIndex
      bcs +
        rts
      +:
      
      ;=====
      ; save initial script pos
      ;=====
      
      ; scratch5 = initial index
      sty scratch5
      
      ; scratch14 = initial script ptr
      lda scriptPtr+0
      sta scratch14
      lda scriptPtr+1
      sta scratch15
      ; scratch4 = initial dte state
      lda dteState.w
      sta scratch4
      
      ; scratch13 = slot 4 bank
      tma #$10
      sta scratch13
      
      ;=====
      ; get first char's index
      ;=====
      
      jsr loadNewTextRsrcBank
      jsr processInputCharacterAndUpdateScriptPtr
      
      ;=====
      ; if not a space, do nothing
      ;=====
      
      cmp #spaceCharIndex
      bne @cancel
      
      ;=====
      ; advance forward until we find a non-space character
      ;=====
      
      ; scratch11-12 = width of read input
      stz scratch11
      stz scratch12
      
      @spaceSearchLoop:
        ; scratch6-8 = script state of first non-space char
        lda scriptPtr+0
        sta scratch6
        lda scriptPtr+1
        sta scratch7
        lda dteState.w
        sta scratch8
        
        ; fetch next char
        lda scratch13
        tam #$10
        lda (scriptPtr)
        
        ; if we encounter an opcode before a non-space character, cancel
        cmp #literalCharsBaseIndex
        bcc @cancel
        
        ; process raw input
        tay
        jsr loadNewTextRsrcBank
        jsr processInputCharacterAndUpdateScriptPtr
        
        ; done when we encounter a non-space character
        cmp #spaceCharIndex
        bne +
        
        ; FIXME
        ; add width of space to total width
        lda #spaceCharWidth
        clc
        adc scratch11
        sta scratch11
        cla
        adc scratch12
        sta scratch12
        
        bra @spaceSearchLoop
      +:
      
      ; now we need to read the next word and determine its width
      @wordSearchLoop:
        ; fetch next char
        lda scratch13
        tam #$10
        lda (scriptPtr)
        
        ; if we encounter an opcode, done
        cmp #literalCharsBaseIndex
        bcc @doFinalChecks
        
        ; process raw input
        tay
        jsr loadNewTextRsrcBank
        jsr processInputCharacterAndUpdateScriptPtr
        
        ; done when we encounter a space character
        cmp #spaceCharIndex
        beq @doFinalChecks
        
        ; Y = physical index of target character
        sec
        sbc #literalCharsBaseIndex
        tay
        ; add width of character to total width
        lda scratch13
        tam #$10
        lda fontWidthTable.w,Y
        clc
        adc scratch11
        sta scratch11
        cla
        adc scratch12
        sta scratch12
        
        bra @wordSearchLoop
      
      @cancel:
      ; restore initial script state
      lda scratch14
      sta scriptPtr+0
      lda scratch15
      sta scriptPtr+1
      lda scratch4
      sta dteState.w
      ; initial index
      ldy scratch5
      ; slot
      lda scratch13
      tam #$10
      rts
      
      @doFinalChecks:
      
      ;=====
      ; does new width exceed width of line?
      ;=====
      
      ; X is still the box type
      
      ; scratch13 = current box's pixel x-pos
;      lda boxPixelXArrayLo,X
;      sta scratch13
;      lda boxPixelXArrayHi,X
;      sta scratch14

      ; add current pixel x-pos to this word's width
      lda boxPixelXArrayLo.w,X
      clc
      adc scratch11
      sta scratch11
      lda boxPixelXArrayHi.w,X
      adc scratch12
      sta scratch12
      
      ; subtract total width from maximum
      lda maxBoxPixelXArrayLo.w,X
      sec
      sbc scratch11
      lda maxBoxPixelXArrayHi.w,X
      sbc scratch12
      
      ; if no overflow, we don't need to break the line
      bcs @cancel
        
      ; break the line (FIXME: no overflow check!!)
      ; increment Y-pos
      inc $30DD,X
      ; reset x-pos
      jsr resetCurrentBoxPixelX_withMakeup
      
      ; use word start script state as new state
      lda scratch6
      sta scriptPtr+0
      lda scratch7
      sta scriptPtr+1
      lda scratch8
      sta dteState.w
      ; initial index
      lda (scriptPtr)
      tay
      ; slot
      lda scratch13
      tam #$10
      
      rts */
  .ends

  ;=============================
  ; new character transfer logic
  ;=============================

  .bank $B slot 3
  .org $0A69
  .section "new char transfer logic 1" overwrite
    phx
      jsr loadNewTextRsrcBank
      jsr queueNewCharTransfer
    plx
    jmp $6B1E
  .ends

  ;=============================
  ; EXECUTES AS INTERRUPT
  ; new char tile to vram logic
  ;=============================

  .bank $B slot 3
  .org $0B37
  .section "new char tile to vram logic 1" SIZE $22 overwrite
    newCharTileToVramOverwrite:
      sta @aRestore+1.w
      
      ; save old bank
      tma #$10
      pha
        jsr loadNewTextRsrcBank
        @aRestore:
        lda #$00
        jsr doNewCharVramTransfer
      pla
      tam #$10
      jmp $6B59
  .ends

  ;=============================
  ; transfer 3 tiles to tilemap
  ; per char instead of 2
  ;=============================

;  .bank $B slot 3
;  .org $0B79
;  .section "send 3 tilemap entries per char 1" overwrite
;;    cpx #$02
;    cpx #$03
;  .ends

  .bank $B slot 3
  .org $0B69
  .section "fix tilemap generation logic 1" overwrite
    jmp finishFixTilemapGeneration
  .ends

  .bank $B slot 3
  .section "fix tilemap generation logic 2" free
    finishFixTilemapGeneration:
      ; counter
      clx
      -:
        ; default high byte of tilemap
        lda #$10
        ; if low byte < 0x90, assume high byte needs to be 0x11
        ; (original game did not account for the possibility that
        ; this might occur during the loop, since it couldn't.
        ; but now it can.)
        cpy #$90
        bcs +
          ina
        +:
        
        ; write
        sty $0002.w
        sta $0003.w
        iny
        inx
;        cpx #$02
        ; 3 patterns per transfer
        cpx #outputPatternTransferAreaPatternW
        bcc -
      
      rts
  .ends

  ;=============================
  ; fix freeze caused by button reaction
  ; "race condition"
  ;=============================
  
  ; 
  
  .bank $B slot 3
  .org $0CF5
  .section "fix wait-for-box-input button reaction freeze 1" overwrite
    jmp finishWaitForBoxButtonReactionSetup
  .ends

  .bank $B slot 3
  .section "fix wait-for-box-input button reaction freeze 2" free
    finishWaitForBoxButtonReactionSetup:
      ; set up original task (switch to wait-for-box-input button reaction
      ; in 5 frames)
      ; ID
      lda #$02
      ; ?
      ldx #$00
      ; frames before activation
      ldy #$05
      jsr addIdleTask
      lda setButtonReaction.w
      lda #$31
      
      ; but the game is still checking inputs for the current reaction in the
      ; meantime...
      ; and some of those reactions can reset the reaction mode,
      ; with an idle delay first!
      ; so depending on the timing, we can get a sequence where our switch
      ; to the "box wait" reaction goes through, but is immediately followed
      ; by an already-queued reaction command that changes the reaction to
      ; something else entirely.
      ; to resolve this, immediately shut off the reaction first.
      ; somehow, the original game's timing manages to resolve in such a way
      ; that the wait-for-input reaction takes priority.
      ; i did nothing to purposely change this, so i really have no idea what
      ; the problem is.
      ; but it took me 4 fucking hours to find and fix so wonderful
      
      lda #$FF
      ; other params don't matter
;      ldx #$00
;      ldy #$05
      jsr addActiveTask
      lda setButtonReaction.w
      lda #$31
      
/*      lda #$FE
      ; other params don't matter
;      ldx #$00
      ldy #$01
      jsr addIdleTask
      lda setButtonReaction.w
      lda #$31
      
      lda #$FE
      ; other params don't matter
;      ldx #$00
      ldy #$02
      jsr addIdleTask
      lda setButtonReaction.w
      lda #$31
      
      lda #$FE
      ; other params don't matter
;      ldx #$00
      ldy #$03
      jsr addIdleTask
      lda setButtonReaction.w
      lda #$31 */
      
      rts
  .ends

  ;=============================
  ; correctly handle a lower-
  ; rows-only clear
  ;=============================

  ; add a vsync task that directly
  ; blanks out the bottom 4 pixels of the second row
  ; (zeroes bytes 8-15 and 24-31 of each pattern)
  
  .bank $B slot 3
  .org $0D6C
  .section "fix lower-rows-only clear 1" overwrite
    jmp finishLowerRowsOnlyClear
  .ends

  .bank $B slot 3
  .section "fix lower-rows-only clear 2" free
    .define patternLine1VramBaseAddrLeftBox vramBaseAddrLeftBox+vramLineSeparationLeftBox+(patternSize/8)
    .define patternLine1VramBaseAddrRightBox vramBaseAddrRightBox+vramLineSeparationRightBox+(patternSize/8)
    .define patternLine1VramBaseAddrCenterBox vramBaseAddrCenterBox+vramLineSeparationCenterBox+(patternSize/8)
    
    patternLine1VramBaseAddrArrayLo:
      .db <patternLine1VramBaseAddrLeftBox
      .db <patternLine1VramBaseAddrRightBox
      .db <patternLine1VramBaseAddrCenterBox
    patternLine1VramBaseAddrArrayHi:
      .db >patternLine1VramBaseAddrLeftBox
      .db >patternLine1VramBaseAddrRightBox
      .db >patternLine1VramBaseAddrCenterBox
    patternLine1ClearTileCountArray:
      .db smallMsgBoxPatternW
      .db smallMsgBoxPatternW
      .db largeMsgBoxPatternW
    
    ; X = box type
    finishLowerRowsOnlyClear:
      phx
        ; Y-param = tile count
        lda patternLine1ClearTileCountArray.w,X
        sta @rowBlankTaskParams+5.w
        ; XA-param = vram target
        lda patternLine1VramBaseAddrArrayLo.w,X
        ldy patternLine1VramBaseAddrArrayHi.w,X
        sxy
        jsr addFrameSyncedTask
        @rowBlankTaskParams:
          lda finishLowerRowsOnlyClear_task.w ; task addr
          ldx $0059.w ; Y param + identifier
      plx
      
      ; make up work
      ldy #$03
      jmp addInterpreterTaskWithCustomIdle
      
      
    ;=============================
    ; EXECUTES AS INTERRUPT
    ;
    ; XA = target vram base address
    ; Y = tile count
    ;=============================
    
    ; for transfer
    finishLowerRowsOnlyClear_zeroData:
      .rept 8
        .db $00
      .endr
    
    finishLowerRowsOnlyClear_task:
      -:
;        phx
;          pha
            ; set MAWR = XA
            st0 #$00
            sta $0002.w
            stx $0003.w
            
            ; target VWR
            st0 #$02
            
            ; write 4 words of zero
            tia finishLowerRowsOnlyClear_zeroData,$0002,8
            
            ; advance target write position to bitplanes 2/3
            ; (cannot overflow)
            clc
            adc #(patternSize/4)
            
            ; set MAWR = XA
            st0 #$00
            sta $0002.w
            stx $0003.w
            
            ; target VWR
            st0 #$02
            
            ; write 4 words of zero
            tia finishLowerRowsOnlyClear_zeroData,$0002,8
            
            ; advance target write position
            clc
            adc #(patternSize/4)
            sax
            adc #$00
            sax
            
;          pla
;          ; move to next pattern
;          clc
;          adc #(patternSize/2)
;          tax
;        pla
;        adc #$00
;        sax
        
        dey
        bne -
      
      rts
  .ends
  
/*  .bank $B slot 3
  .org $0D6C
  .section "fix lower-rows-only clear 1" overwrite
    jmp finishLowerRowsOnlyClear
  .ends

  .bank $B slot 3
  .section "fix lower-rows-only clear 2" free
    ; number of transfers required to cover a full row of a box
    ; of each type
    neededFirstLineRefreshSendsPerBoxTypeArray:
      ; left
      .db (smallMsgBoxPatternW+(outputPatternTransferAreaPatternW-1))/outputPatternTransferAreaPatternW
      ; right
      .db (smallMsgBoxPatternW+(outputPatternTransferAreaPatternW-1))/outputPatternTransferAreaPatternW
      ; center
      .db (largeMsgBoxPatternW+(outputPatternTransferAreaPatternW-1))/outputPatternTransferAreaPatternW
    
    ; number of sends remaining to complete row
;    lowerRowOnlyClear_refreshCounter:
;      .db $00
;    ; pattern x-position of next src
;    lowerRowOnlyClear_srcXPos:
;      .db $00
;    ; pattern x-position of next dst
;    lowerRowOnlyClear_dstXPos:
;      .db $00
    
    ; X = box type
    finishLowerRowsOnlyClear:
      ; get count of transfers needed for box type
      lda neededFirstLineRefreshSendsPerBoxTypeArray.w,X
      ; save for task's use
;      sta lowerRowOnlyClear_refreshCounter.w
      
      ; reset dst xpos
      
;      ; y-pos
;      lda #$00
;      ; x-pos
;      ldy #$00
;      jsr setUpCharTransferSrcAndDst
      
      ; Y-param
;      stx @lowerRowsOnlyClear_task+5.w
;      lda scratch4
;      ldx scratch5

      ; X-param = box type
      
      ; Y-param = transfer counter
      sta @lowerRowsOnlyClear_task+5.w
      
      ; extra param: scriptptr
      lda scriptPtr+0
      sta @lowerRowsOnlyClear_task+7.w
      lda scriptPtr+1
      sta @lowerRowsOnlyClear_task+8.w

      ; A-param = x-pos
      cla
      
      ; number of idle frames before resume
;      ldy #$03
      ; FIXME: is this safe?
      ; original game waits 3 frames, but this seems to work...
      ldy #$01
      
;      jsr addActiveTask
      jsr addIdleTask
      @lowerRowsOnlyClear_task:
        lda lowerRowsOnlyClear_task.w ; task addr
        ldx $0059.w ; Y param + identifier
        ldy $0000.w ; extra param
      
      rts
    
    ; A = x-pos
    ; X = box type
    ; Y = transfer counter
    lowerRowsOnlyClear_task:
      ; pre-update x-position
      pha
        clc
        adc #outputPatternTransferAreaPatternW
        sta @nextX+1.w
        
        jsr loadNewTextRsrcBank
      pla
      
      ; set up params
      phy
        ; x-pos
        tay
        ; y-pos
        cla
        jsr setUpCharTransferSrcAndDst
      ply
      
      ; queue transfer
;      pha
      phx
      phy
        jsr formatSrcCharAreaForOutput
        
        ; flag transfer as active?
        lda #$01
        sta $30D7,X
        
        jsr queueNewCharTransfer
      ply
      plx
;      pla
      
      ; done?
      dey
      bne +
        @done:
        ; make up work
;        ldy #$03
        ldy #$01
        jmp addInterpreterTaskWithCustomIdle
      +:
      
      ;=====
      ; add idle task for next transfer
      ;=====

      ; X-param = box type
      
      ; Y-param = transfer counter
      sty @lowerRowsOnlyClear_task+5.w
      
      ; extra param: scriptptr
      lda scriptPtr+0
      sta @lowerRowsOnlyClear_task+7.w
      lda scriptPtr+1
      sta @lowerRowsOnlyClear_task+8.w

      ; A-param = x-pos
      ; (self-modifying)
      @nextX:
      lda #$00
      
      ; number of idle frames before resume
      ldy #$01
      
      jsr addIdleTask
      @lowerRowsOnlyClear_task:
        lda lowerRowsOnlyClear_task.w ; task addr
        ldx $0059.w ; Y param + identifier
        ldy $0000.w ; extra param
      
      rts
  .ends */
  
  

  ;=============================
  ; clear comp area where needed
  ;=============================

  .bank $B slot 3
  .org $000B
  .section "do comp area clear 1" overwrite
    jsr doCompAreaClear1
  .ends

  .bank $B slot 3
  .section "do comp area clear 2" free
    doCompAreaClearShortcut:
      tma #$10
      pha
        jsr loadNewTextRsrcBank
        jsr clearTextCompAreaForBoxType
      pla
      tam #$10
      rts
    
    doCompAreaClearShortcut_special:
      tma #$10
      pha
        jsr loadNewTextRsrcBank
        jsr clearTextCompAreaForBoxType_special
      pla
      tam #$10
      rts
    
    doCompAreaClear1:
      phx
      phy
        ; check mode
        ; do nothing if closing window
        cpy #$00
        beq @done
        
        ; if "special", do first-row-preserving clear
        cpy #$02
        bne +
          jsr doCompAreaClearShortcut_special
          bra @done
        +:
        
        ; otherwise, normal window open
        jsr doCompAreaClearShortcut
        
        @done:
      ply
      plx
      ; make up work
      lda $6000.w,Y
      rts
  .ends

  ;=============================
  ; reset new pixel-level window x-pos where needed
  ;=============================
  
  .bank $B slot 3
  .section "reset box pixel x 2" free
    ; X = box type
    resetCurrentBoxPixelX_withMakeup:
      stz boxPixelXArrayLo.w,X
      stz boxPixelXArrayHi.w,X
      
      ; reset dynamic word wrap
      stz dynamicWordWrap_spaceSeen.w
;      stz dynamicWordWrap_currentWidth
      
      ; make up work
      stz $30DA,X
      rts
  .ends
  
  ;=====
  ; linebreak
  ;=====
  
  .bank $B slot 3
  .org $0953
  .section "reset box pixel x 1" overwrite
    jsr resetCurrentBoxPixelX_withMakeup
  .ends
  
  ;=====
  ; clear (except line 1)
  ;=====
  
  .bank $B slot 3
  .org $0042
  .section "reset box pixel x 3" overwrite
    jsr resetCurrentBoxPixelX_withMakeup
  .ends
  
  ;=====
  ; clear
  ;=====
  
  .bank $B slot 3
  .org $007F
  .section "reset box pixel x 4" overwrite
    jsr resetCurrentBoxPixelX_withMakeup
  .ends
  
  ;=====
  ; clear
  ;=====
  
  .bank $B slot 3
  .org $00EE
  .section "reset box pixel x 5" overwrite
    jsr resetCurrentBoxPixelX_withMakeup
  .ends

  ;=============================
  ; increase number of rows in box
  ;=============================
  
  .bank $B slot 3
  .org $08F0
  .section "increase rows per box 1" overwrite
    cmp #numBoxCharRows
  .ends
  
  .bank $B slot 3
  .org $0959
  .section "increase rows per box 2" overwrite
    cmp #numBoxCharRows
  .ends
  
  .bank $B slot 3
  .org $0D2B
  .section "increase rows per box 3" overwrite
    cmp #numBoxCharRows
  .ends


  ;==============================================================================
  ; 18000 (text group 1)
  ;==============================================================================



  ;==============================================================================
  ; 1C000 (text group 2)
  ;==============================================================================

  ; this space would normally be for text, but isn't used any more,
  ; so it's now been freed up for our extra needs
  .unbackground $20200 $21FFF

  .bank $10 slot 4
  .section "new text resources" free

    ;==============================================================================
    ; memory
    ;==============================================================================
    
    ; area to compose output text (1bpp)
    textCompArea:
      .rept textCompAreaSize
        .db $00
      .endr
    .define leftWindowCompAreaBase textCompArea
    .define rightWindowCompAreaBase textCompArea+smallMsgBoxSrcPatternOffsetW
    .define centerWindowCompAreaBase textCompArea
    
    ; area to store converted text patterns for transfer to vram
    outputPatternTransferArea:
      .rept outputPatternTransferAreaByteSize
        .db $00
      .endr
    
    ; src pattern x/y for next transfer
    inputPatternTransferPatternX:
      .db $00
    inputPatternTransferPatternY:
      .db $00
    ; dst pattern x/y for next transfer
    outputPatternTransferPatternX:
      .db $00
    outputPatternTransferPatternY:
      .db $00

    ;==============================================================================
    ; data
    ;==============================================================================
    
    ; DTE dictionary
    scriptDictionary:
      .incbin "out/script/dictionary.bin"
      
    ; 1bpp font data
    fontData:
      .incbin "out/font/font.bin"
    
    ; width table for font
    fontWidthTable:
      .incbin "out/font/fontwidth.bin"
    
    tableMaxTransferSrcPatternX_array:
      ; left
      .db smallMsgBoxPatternW-outputPatternTransferAreaPatternW
      ; right
      .db (smallMsgBoxSrcPatternOffsetW+smallMsgBoxPatternW)-outputPatternTransferAreaPatternW
      ; center
      .db largeMsgBoxPatternW-outputPatternTransferAreaPatternW
    
    tableMaxTransferDstPatternX_array:
      ; left
      .db smallMsgBoxPatternW-outputPatternTransferAreaPatternW
      ; right
;      .db ((smallMsgBoxPixelW*2)/8)-outputPatternTransferAreaPatternW
      .db smallMsgBoxPatternW-outputPatternTransferAreaPatternW
      ; center
      .db largeMsgBoxPatternW-outputPatternTransferAreaPatternW

    ;==============================================================================
    ; routines
    ;==============================================================================
    
    ;=============================
    ; fetch DTE pointer to scratch2
    ;
    ; Y = index
    ;=============================
    
    getDtePtr:
      tya
      sec
      sbc #dictionaryCharsBaseIndex
      
      ; multiply by 2
      clc
      rol A
      
      clc
      adc #<scriptDictionary
      sta scratch2
      cla
      adc #>scriptDictionary
      sta scratch3
      
      rts
    
    ;=============================
    ; fetch first char of a DTE pair
    ;
    ; Y = index
    ; returns A = char literal
    ;=============================
    
    getFirstDteChar:
      jsr getDtePtr
      lda (scratch2)
      rts
    
    ;=============================
    ; fetch second char of a DTE pair
    ;
    ; Y = index
    ; returns A = char literal
    ;=============================
    
    getSecondDteChar:
      jsr getDtePtr
      ldy #$01
      lda (scratch2),Y
      rts
    
    ;=============================
    ; convert raw char ID to a
    ; literal ID, and update the
    ; script pointer as needed
    ;
    ; Y = input character
    ; returns A = actual target
    ; character (after decompression,
    ; etc.)
    ;=============================
    
    processInputCharacterAndUpdateScriptPtr:
      ;=====
      ; check if a DTE character
      ;=====
      
      cpy #dictionaryCharsBaseIndex
      bcc @notDteChar
        ;=====
        ; if a dte command, update DTE state
        ;=====
        
        lda dteState.w
        cmp #$00
        bne +
          ; state is zero = need first character
          
          ; switch to state 1
          ina
          sta dteState.w
          
          ; script pointer is not incremented, so we'll see this command
          ; again on the next iteration
          
          jsr getFirstDteChar
          
          bra @next
        +:
          ; state is nonzero = need second character
          
          ; switch to state 0
          stz dteState.w
          
          ; increment script pointer past dte command
          jsr incScriptPtr
          
          jsr getSecondDteChar
          
          bra @next
        ++:
          
      @notDteChar:

      ;=====
      ; literal
      ;=====
      
      jsr incScriptPtr
      tya
      
      @next:
    rts
    
    ;=============================
    ; EXECUTES AS INTERRUPT
    ; new logic for sending tile
    ; char to vram.
    ;
    ; XA = target vram base address
    ; Y = window index
    ;=============================
    
    doNewCharVramTransfer:
      ; set MAWR = XA
      st0 #$00
      sta $0002.w
      stx $0003.w
      
      ; target VWR
      st0 #$02
      
      ; save target address
;      sta scratch2
;      stx scratch3
      phx
        pha
          ; ???
          lda $30D7,Y
          cmp #$01
          bne +
            ; transfer top half
            tia outputPatternTransferArea,$0002,patternSize*outputPatternTransferAreaPatternW
          +:
        pla
        ; offset target address by the size of a line for this window
  ;      lda boxVramLineSeparationArrayLo.w,Y
        clc
        adc boxVramLineSeparationArrayLo.w,Y
        tax
      pla
      adc boxVramLineSeparationArrayHi.w,Y
      
      ; set MAWR = AX
      st0 #$00
      stx $0002.w
      sta $0003.w
      
      ; target VWR
      st0 #$02
      
      ; ???
      lda $30D7,Y
      cmp #$01
      bne +
        ; transfer bottom half
        tia outputPatternTransferArea+(patternSize*outputPatternTransferAreaPatternW),$0002,patternSize*outputPatternTransferAreaPatternW
      +:
      
      lda #$00
      sta $30D7,Y
      
      rts
    
    ;=============================
    ; queues a previously set up
    ; char vram transfer
    ;
    ; X = box type
    ;=============================
    
    queueNewCharTransfer:
      ; scratch9 = box type
      stx scratch9
      
      ;=====
      ; determine base vram target
      ;=====
      
      ; scratch2 = pointer to table for target box type
      lda boxLineBaseVramArrayPointerArrayLo.w,X
      sta scratch2
      lda boxLineBaseVramArrayPointerArrayHi.w,X
      sta scratch3
      
      ; get target line number
      lda outputPatternTransferPatternY.w
      ; index into table
      asl
      tay
      ; scratch4 = VRAM base addr of target line
      lda (scratch2),Y
      sta scratch4
      iny
      lda (scratch2),Y
      sta scratch5
      
      ; multiply dstX by pattern size (/2, since this is a word-based address)
      ; to get offset for target data
      lda outputPatternTransferPatternX.w
      sta _AL
      lda #(patternSize/2)
      sta _BL
      phx
        jsr MA_MUL8U
      plx
      
      ; add result to line's base addr to get true target
      lda _CL
      clc
      adc scratch4
      sta scratch4
      lda _CH
      adc scratch5
      sta scratch5
      
      ;=====
      ; set up and run tile transfer task
      ;=====
      
      ; Y-param = box type
      stx @tileTransferTaskParams+5.w
      ; XA-param = vram target
      lda scratch4
      ldx scratch5
      jsr addFrameSyncedTask
      @tileTransferTaskParams:
        lda $6B37.w ; task addr
        ldx $0059.w ; Y param + identifier
      
      ;=====
      ; tilemap
      ;=====
      
      ; X = window type
      ldx scratch9
      
      ; look up tilemap base address
      
      ; scratch2 = pointer to table for target box type
      lda boxLineBaseTilemapVramArrayPointerArrayLo.w,X
      sta scratch2
      lda boxLineBaseTilemapVramArrayPointerArrayHi.w,X
      sta scratch3
      
      ; scratch6 = pointer to low byte of target line's tilemap identifier
      lda boxLineBaseTileIdVramArrayPointerArrayLo.w,X
      sta scratch6
      lda boxLineBaseTileIdVramArrayPointerArrayHi.w,X
      sta scratch7
      
      ; get target line number
      ldy outputPatternTransferPatternY.w
      
      ; scratch8 = low byte of target line's tilemap identifier
      lda (scratch6),Y
      sta scratch8
      
      ; scratch4 = base address for target line's tilemap
      tya
      asl
      tay
      lda (scratch2),Y
      sta scratch4
      iny
      lda (scratch2),Y
      sta scratch5
      
      ; apply offsets according to x-position
      ldy outputPatternTransferPatternX.w
      -:
        beq +
          ; tilemap addr += 1
          inc scratch4
          bne ++
            inc scratch5
          ++:
          
          ; low byte of tilemap identifier += 1
          inc scratch8
          
          dey
          bra -
      +:
      
      ;=====
      ; set up and run tilemap transfer tasks
      ;=====
      
      ; Y = low byte of tilemap identifier
      lda scratch8
      sta @tilemapTransferTaskParams+5.w
      ; XA = target address
      lda scratch4
      ldx scratch5
      
      
      cly
      ; task queue loop
      -:
        phy
          phx
            pha
              
              jsr addFrameSyncedTask
              @tilemapTransferTaskParams:
                lda $6B5F.w ; task addr
                ldx $0059.w ; Y param + identifier
                
              ; target next row and set up another transfer
;              lda @tilemapTransferTaskParams+5.w
;              clc
;              adc #(vramBoxTilemapLineSeparation>>4)
              
              ; tilemap identifier += tile line separation
              ; retrieve box type
              ldy scratch9
              ; look up tile line separation
              lda boxVramTilemapLineSeparationArrayLo.w,Y
              clc
              adc @tilemapTransferTaskParams+5.w
              
              sta @tilemapTransferTaskParams+5.w
              
              
            pla
            ; target address += line separation
            clc
            adc #<vramBoxTilemapLineSeparation
            tax
          pla
          adc #>vramBoxTilemapLineSeparation
          sax
        ply
        iny
        cpy #$01
        beq -
      
      
      
      rts
    
    ;=====
    ; data tables
    ;=====
    
    boxVramLineSeparationArrayLo:
      .db <vramLineSeparationLeftBox
      .db <vramLineSeparationRightBox
      .db <vramLineSeparationCenterBox
    boxVramLineSeparationArrayHi:
      .db >vramLineSeparationLeftBox
      .db >vramLineSeparationRightBox
      .db >vramLineSeparationCenterBox
    
    boxVramTilemapLineSeparationArrayLo:
      .db <vramTilemapLineSeparationLeftBox
      .db <vramTilemapLineSeparationRightBox
      .db <vramTilemapLineSeparationCenterBox
    boxVramTilemapLineSeparationArrayHi:
      .db >vramTilemapLineSeparationLeftBox
      .db >vramTilemapLineSeparationRightBox
      .db >vramTilemapLineSeparationCenterBox
    
    leftBoxLineBaseVramAddrArray:
      .rept 6 index count
        .dw vramBaseAddrLeftBox+(count*vramLineSeparationLeftBox)
      .endr
    rightBoxLineBaseVramAddrArray:
      .rept 6 index count
        .dw vramBaseAddrRightBox+(count*vramLineSeparationRightBox)
      .endr
    centerBoxLineBaseVramAddrArray:
      .rept 6 index count
        .dw vramBaseAddrCenterBox+(count*vramLineSeparationCenterBox)
      .endr
    
    ; table of the above
    boxLineBaseVramArrayPointerArrayLo:
      .db <leftBoxLineBaseVramAddrArray
      .db <rightBoxLineBaseVramAddrArray
      .db <centerBoxLineBaseVramAddrArray
    boxLineBaseVramArrayPointerArrayHi:
      .db >leftBoxLineBaseVramAddrArray
      .db >rightBoxLineBaseVramAddrArray
      .db >centerBoxLineBaseVramAddrArray
    
    leftBoxLineBaseTilemapVramAddrArray:
      .rept 6 index count
        .dw vramBaseTilemapAddrLeftBox+(count*vramBoxTilemapLineSeparation)
      .endr
    rightBoxLineBaseTilemapVramAddrArray:
      .rept 6 index count
        .dw vramBaseTilemapAddrRightBox+(count*vramBoxTilemapLineSeparation)
      .endr
    centerBoxLineBaseTilemapVramAddrArray:
      .rept 6 index count
        .dw vramBaseTilemapAddrCenterBox+(count*vramBoxTilemapLineSeparation)
      .endr
    
    ; table of the above
    boxLineBaseTilemapVramArrayPointerArrayLo:
      .db <leftBoxLineBaseTilemapVramAddrArray
      .db <rightBoxLineBaseTilemapVramAddrArray
      .db <centerBoxLineBaseTilemapVramAddrArray
    boxLineBaseTilemapVramArrayPointerArrayHi:
      .db >leftBoxLineBaseTilemapVramAddrArray
      .db >rightBoxLineBaseTilemapVramAddrArray
      .db >centerBoxLineBaseTilemapVramAddrArray
    
   ; low bytes of tile identifiers for start of each line
    leftBoxLineBaseVramTileIdArrayLo:
      .rept 6 index count
        .db <((vramBaseAddrLeftBox+(count*vramLineSeparationLeftBox))>>4)
      .endr
    rightBoxLineBaseVramTileIdArrayLo:
      .rept 6 index count
        .db <((vramBaseAddrRightBox+(count*vramLineSeparationRightBox))>>4)
      .endr
    centerBoxLineBaseVramTileIdArrayLo:
      .rept 6 index count
        .db <((vramBaseAddrCenterBox+(count*vramLineSeparationCenterBox))>>4)
      .endr
    
    ; table of the above
    boxLineBaseTileIdVramArrayPointerArrayLo:
      .db <leftBoxLineBaseVramTileIdArrayLo
      .db <rightBoxLineBaseVramTileIdArrayLo
      .db <centerBoxLineBaseVramTileIdArrayLo
    boxLineBaseTileIdVramArrayPointerArrayHi:
      .db >leftBoxLineBaseVramTileIdArrayLo
      .db >rightBoxLineBaseVramTileIdArrayLo
      .db >centerBoxLineBaseVramTileIdArrayLo
      
    
    ;=============================
    ; adds a character to the
    ; indicated box, and sets up
    ; the transfer area for sending
    ; the newly transferred content
    ; to VRAM
    ;
    ; A = char ID (raw)
    ; X = box type
    ;=============================
    
    addCharAndSetUpTransfer:
      phx
        ; character composition + conversion...
        
        ; convert char ID from raw to index
        sec
        sbc #literalCharsBaseIndex
        
        phx
          pha
            ; compute offset of target character within font data
            sta _AL
            lda #bytesPerStoredFontChar
            sta _BL
            ; CX = result of multiplication
            jsr MA_MUL8U
            
            ; scratch2 = pointer to source character bitmap
            lda _CL
            clc
            adc #<fontData
            sta scratch2
            lda _CH
            adc #>fontData
            sta scratch3
          pla
          
          ; scratch4 = character's width
          tax
          lda fontWidthTable.w,X
          sta scratch4
        plx
        
        ; scratch6 = current box's pixel x-pos
        ; also copy to scratch10 for later use
        lda boxPixelXArrayLo.w,X
        sta scratch6
        sta scratch10
        lda boxPixelXArrayHi.w,X
        sta scratch7
        sta scratch11
        
        ; compute current line's byte offset
        ; get row number
        lda boxYArray.w,X
        ; multiply by row height (12)
        sta scratch8
          ; *2
          asl A
          clc
          ; *3
          adc scratch8
          ; *6
          asl A
          ; *12
          asl A
        ; save for future use
        sta scratch15
        ; multiply by bytes per row
        sta _AL
        lda #textCompAreaRowBytes
        sta _BL
        phx
          ; CX = result of multiplication
          jsr MA_MUL8U
        plx
        
        ; YA = pointer to base composition area
        jsr getWindowTypeBaseCompArea
        
        ; scratch8 = add line offset to base position to get base dstaddr
        clc
        adc _CL
        sta scratch8
        tya
        adc _CH
        sta scratch9
        
        ; scratch10 = pixel x-pos / 8 (x-offset within comp area)
        lsr scratch11
        ror scratch10
;        lsr scratch11
;        ror scratch10
;        lsr scratch11
;        ror scratch10
        ; pixel X should never exceed 304, so everything after this is 8-bit
        lda scratch10
        lsr A
        lsr A
        ; this value is also the pattern offset within the box,
        ; so save it to scratch5 for later use
        sta scratch5
        
        ; add to base offset to get base destination
        clc
        adc scratch8
        sta scratch8
        cla
        adc scratch9
        sta scratch9
        
        ; scratch10 = (pixelX % 8) = number of bits to shift each input line
        lda scratch6
        and #$07
        sta scratch10
        
        ; scratch11 = number of bytes to copy per line
        ; get width in pixels
        lda scratch4
        ; add number of bits shifted
        clc
        adc scratch10
        ; round up
        clc
        adc #$07
        ; divide by 8
        lsr A
        lsr A
        lsr A
        sta scratch11
        
        ;=====
        ; blit new char to comp area
        ;=====
        
        ; now:
        ; scratch2 = srcptr
        ; scratch4 = src char's width in pixels
        ; scratch5 = nominal dst pattern offset
        ;            (will need to be checked to avoid exceeding
        ;            end of box before use)
        ; scratch6 = dst pixel X
        ; scratch8 = dstaddr
        ; scratch10 = number of bits to shift each input line
        ; scratch11 = number of bytes to copy per line
        ; scratch15 = y-offset in pixels
        
        ldx #storedFontCharH
        @yLoop:
          
          ; read input line to scratch12-scratch13
          lda (scratch2)
          sta scratch12
          ldy #$01
          lda (scratch2),Y
          sta scratch13
          ; zero final byte for use in bitshift
          stz scratch14
          
          ; bitshift input by needed amount (requires 3 bytes)
          ldy scratch10
          cpy #$00
          beq +
          @inputShiftLoop:
            lsr scratch12
            ror scratch13
            ror scratch14
            
            dey
            bne @inputShiftLoop
          +:
          
          ; number of bytes to copy = ((charW + 7) / 8)
          ; TODO: if speed actually matters, we can add 2 bytes of padding
          ; to each dst row and unconditionally copy all 3 bytes
          phx
            ldx scratch11
            cly
              ; next input char
              lda (scratch8),Y
              ; OR with next
              ora scratch12
              ; save
              sta (scratch8),Y
              
              ; done?
              dex
              beq @copyDone
              
              ; repeat
              iny
              lda (scratch8),Y
              ora scratch13
              sta (scratch8),Y
              
              ; done?
              dex
              beq @copyDone
              
              ; repeat
              iny
              lda (scratch8),Y
              ora scratch14
              sta (scratch8),Y
          @copyDone:
          plx
          
          ;=====
          ; move to next row
          ;=====
          
          ; src: 2 bytes
          inc scratch2
          bne +
            inc scratch3
          +:
          inc scratch2
          bne +
            inc scratch3
          +:
          
          ; dst
          lda scratch8
          clc
          adc #<textCompAreaRowBytes
          sta scratch8
          lda #>textCompAreaRowBytes
          adc scratch9
          sta scratch9
          
          ;=====
          ; loop until done
          ;=====
          
          dex
          bne @yLoop
    
      ;=====
      ; finish up
      ;=====
        
      ; restore box type
      plx
      
      ;=====
      ; update dst pixel X
      ;=====
      
      lda boxPixelXArrayLo.w,X
      clc
      adc scratch4
      sta boxPixelXArrayLo.w,X
      cla
      adc boxPixelXArrayHi.w,X
      sta boxPixelXArrayHi.w,X
    
      ;=====
      ; determine transfer src/dst pattern x/y
      ;=====
      
      ; retrieve y-offset in pixels
      lda scratch15
      ; divide by 8 to get target pattern y offset
      lsr A
      lsr A
      lsr A

      ; retrieve x-offset in patterns
      ldy scratch5
      
/*      ; scratch3 = src pattern y offset
;      sta scratch3
      sta inputPatternTransferPatternY.w
      ; which is also the dst y-offset
      sta outputPatternTransferPatternY.w
      
      ; retrieve x-offset in patterns
      lda scratch5
      ; if greater than maximum allowable source for this window type,
      ; reduce to that maximum
      cmp tableMaxTransferDstPatternX_array.w,X
      bcc +
        lda tableMaxTransferDstPatternX_array.w,X
      +:
      ; dst x-offset
      sta outputPatternTransferPatternX.w
      
      ; now determine src x-offset
      ; this is the same as the dst x-offset unless targeting the
      ; right box, in which case it's offset by the width of a small box
      cpx #boxTypeRight
      bne +
        clc
        adc #(smallMsgBoxPixelW/8)
      +:
      ; scratch2 = src x offset
;      sta scratch2
      sta inputPatternTransferPatternX.w
      
      rts */
      
      jmp setUpCharTransferSrcAndDst
    
    ;=============================
    ; sets up src/dst for char
    ; transfer
    ;
    ; A = y-offset in patterns
    ; X = box type
    ; Y = x-offset in patterns
    ;
    ; see [input/output]PatternTransferPattern[X/Y]
    ;=============================
    
    setUpCharTransferSrcAndDst:
      ; src/dst y-offset are the same
      sta inputPatternTransferPatternY.w
      sta outputPatternTransferPatternY.w
      
      ; A = x src
      tya
      ; if greater than maximum allowable source for this window type,
      ; reduce to that maximum
      cmp tableMaxTransferDstPatternX_array.w,X
      bcc +
        lda tableMaxTransferDstPatternX_array.w,X
      +:
      ; dst x-offset
      sta outputPatternTransferPatternX.w
      
      ; now determine src x-offset
      ; this is the same as the dst x-offset unless targeting the
      ; right box, in which case it's offset by the width of a small box
      cpx #boxTypeRight
      bne +
        clc
;        adc #(smallMsgBoxPixelW/8)
        adc #smallMsgBoxSrcPatternOffsetW
      +:
      sta inputPatternTransferPatternX.w
      
      rts
    
    ;=============================
    ; formats the specified char
    ; area for output to vram
    ;
    ; see [input/output]PatternTransferPattern[X/Y]
    ;=============================
      
    formatSrcCharAreaForOutput:
  
      ;=====
      ; format for output
      ;=====
      
      ; scratch 2 = src x/y
      lda inputPatternTransferPatternX.w
      sta scratch2
      lda inputPatternTransferPatternY.w
      sta scratch3
      
      phx
    
        ;=====
        ; compute the src address
        ;=====
        
        ; now:
        ; - scratch2 = src X offset (patterns)
        ; - scratch3 = src Y offset (patterns)
        
        ; multiply Y by size of comp area line
        lda scratch3
        ; multiply by 8 (pattern height)
        asl A
        asl A
        asl A
        sta _AL
        lda #textCompAreaRowBytes
        sta _BL
        jsr MA_MUL8U
        
        ; add result to base comp area
        ; and write to scratch4
        lda _CL
        clc
        adc #<textCompArea
        sta scratch4
        lda _CH
        adc #>textCompArea
        sta scratch5
        
        ; add src X offset to get base src address
        lda scratch2
        clc
        adc scratch4
        sta scratch4
        cla
        adc scratch5
        sta scratch5
    
        ;=====
        ; format src into orderly 1bpp patterns for conversion
        ;=====
        
        ; scratch6 = src
        lda scratch4
        sta scratch6
        lda scratch5
        sta scratch7
        
        clx
        -:
          ldy #0
          
          lda (scratch6),Y
          sta bitPackedConversionBuffer.w,X
          inx
          
          .rept outputPatternTransferAreaPatternW-1
            iny
            lda (scratch6),Y
            sta bitPackedConversionBuffer.w,X
            inx
          .endr
          
          ; move to next source row
          lda scratch6
          clc
          adc #<textCompAreaRowBytes
          sta scratch6
          cla
          adc scratch7
          sta scratch7
          
          ; copy all patterns of 1bpp data
          cpx #(patternSize1bpp*outputPatternTransferAreaNumPatterns)
          bne -
      
        ;=====
        ; convert target area from 1bpp to standard patterns
        ;=====
        
        jsr do1bppTo4bppConversion
      plx
      
      rts
    
    bitPackedConversionBuffer:
      .rept patternSize1bpp*outputPatternTransferAreaNumPatterns
        .db $00
      .endr
    
    ;=============================
    ; 1bpp->4bpp conversion
    ;=============================
    
    do1bppTo4bppConversion:
      clx
      cly
      @loop:
        ; left
        lda bitPackedConversionBuffer,Y
        sta outputPatternTransferArea+(patternSize*0)+$00.w,X
        sta outputPatternTransferArea+(patternSize*0)+$10.w,X
        inx
        sta outputPatternTransferArea+(patternSize*0)+$00.w,X
        sta outputPatternTransferArea+(patternSize*0)+$10.w,X
/*        dex
        
        ; center
        iny
        lda bitPackedConversionBuffer,Y
        sta outputPatternTransferArea+(patternSize*1)+$00.w,X
        sta outputPatternTransferArea+(patternSize*1)+$10.w,X
        inx
        sta outputPatternTransferArea+(patternSize*1)+$00.w,X
        sta outputPatternTransferArea+(patternSize*1)+$10.w,X
        dex
        
        ; right
        iny
        lda bitPackedConversionBuffer,Y
        sta outputPatternTransferArea+(patternSize*2)+$00.w,X
        sta outputPatternTransferArea+(patternSize*2)+$10.w,X
        inx
        sta outputPatternTransferArea+(patternSize*2)+$00.w,X
        sta outputPatternTransferArea+(patternSize*2)+$10.w,X */
        
        .rept outputPatternTransferAreaPatternW-1 index count
          dex
          iny
          lda bitPackedConversionBuffer,Y
          sta outputPatternTransferArea+(patternSize*(count+1))+$00.w,X
          sta outputPatternTransferArea+(patternSize*(count+1))+$10.w,X
          inx
          sta outputPatternTransferArea+(patternSize*(count+1))+$00.w,X
          sta outputPatternTransferArea+(patternSize*(count+1))+$10.w,X
        .endr
        
        inx
        iny
        
        ; done after all patterns converted
        cpy #(patternSize1bpp*outputPatternTransferAreaNumPatterns)
        bcs @done
          ; when halfway done, reload X so we target the lower half
          ; of the output
          cpy #(patternSize1bpp*outputPatternTransferAreaPatternW)
          bne @loop
            ldx #(patternSize*outputPatternTransferAreaPatternW)
            bra @loop
      @done:
        
      rts
    
    ;=============================
    ; X = window type
    ;
    ; returns YA = base address
    ; of target window area
    ;=============================
    
    getWindowTypeBaseCompArea:
      lda #<leftWindowCompAreaBase
      ldy #>leftWindowCompAreaBase
      cpx #boxTypeRight
      bne +
        ; if right box
        lda #<rightWindowCompAreaBase
        ldy #>rightWindowCompAreaBase
      +:
      rts
    
    ;=============================
    ; set up params to clearTextCompArea
    ; for given box type
    ;
    ; X = box type
    ;=============================
    
    setClearTextCompAreaParamsForBoxType:
      ;=====
      ; set base address of clear area
      ;=====
      
      ; YA = base address of clear
;      lda #<leftWindowCompAreaBase
;      ldy #>leftWindowCompAreaBase
;      cpx boxTypeRight
;      bne +
;        ; if right box
;        lda #<rightWindowCompAreaBase
;        ldy #>rightWindowCompAreaBase
;      +:
      jsr getWindowTypeBaseCompArea
      ; scratch2 = base address of clear
      sta scratch2
      sty scratch3
      
      ; scratch4 = current address of clear
  ;    sta scratch4
  ;    sty scratch5
      
      ;=====
      ; set width of clear area
      ;=====
      
      lda #textCompAreaSmallBoxRowBytes
      cpx #boxTypeCenter
      bne +
        ; if center box
        lda #textCompAreaLargeBoxRowBytes
      +:
      
      ; scratch4 = width of clear area
      sta scratch4
      
      ; scratch5 = height of clear area
      lda #textCompAreaPixelH
      sta scratch5
      
      rts
    
    ;=============================
    ; do clear of everything but
    ; first row for target box
    ;
    ; X = box type
    ;=============================
    
    .define textCompFontRowSize textCharRowHeight*textCompAreaRowBytes
    
    clearTextCompAreaForBoxType_special:
      jsr setClearTextCompAreaParamsForBoxType
      
      ; add height of one character row to base address
      lda scratch2
      clc
      adc #<textCompFontRowSize
      sta scratch2
      lda scratch3
      adc #>textCompFontRowSize
      sta scratch3
      
      ; subtract height of one character row from clear height
      lda scratch5
      sec
      sbc #textCharRowHeight
      sta scratch5
      
      jmp clearTextCompArea
      
    
    ;=============================
    ; fully clear the current
    ; box's text composition area
    ;
    ; X = box type
    ;=============================
    
    clearTextCompAreaForBoxType:
      jsr setClearTextCompAreaParamsForBoxType
    ;!!!!!! DROP THROUGH !!!!!!
    ;=============================
    ; fully clear the current
    ; box's text composition area
    ;
    ; scratch2 = base address of clear
    ; scratch4 = width of clear area
    ; scratch5 = height of clear area
    ;=============================
    
    clearTextCompArea:
      
      ;=====
      ; perform the clear
      ;=====
      
      phx
        ; X = height counter
        ldx scratch5
        @yLoop:
;          lda #$00
          cla
          ; Y = width counter
          ldy scratch4
          @xLoop:
            dey
            sta (scratch2),Y
  ;          cpy #$00
            bne @xLoop
          
          ; move to next row
          lda scratch2
          clc
          adc #textCompAreaRowBytes
          sta scratch2
          cla
          adc scratch3
;          adc #$00
          sta scratch3
          
          dex
          bne @yLoop
      plx    
      
      rts
    
  .ends

.endif