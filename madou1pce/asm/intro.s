
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
  bankstotal $1A
  banksize $2000
  banks $1A
.endro

.emptyfill $FF

.background "intro_21.bin"

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

.define EX_VSYNC $E07B

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
; constants
;===============================================

.define memoryBasePage $68

.define paletteLineSize $20
.define linesPerPaletteGroup $10
.define halfPaletteSize paletteLineSize*linesPerPaletteGroup
.define fullPaletteSize halfPaletteSize*2

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
  
;.define memoryBase $2701

.define localBasePalette $29C5
.define localBaseTilePalette $29C5+(halfPaletteSize*0)
.define localBaseSpritePalette $29C5+(halfPaletteSize*1)

;===============================================
; "global" routines
;===============================================

.define addActiveTask $42A3
;.define addFrameSyncedTask 
.define addIdleTask $4380

;===============================================
; task targets
;===============================================

;.define setButtonReaction $6863

;==============================================================================
; unbackground empty space
;==============================================================================

; bank 0
.unbackground $16F7 $1FFF
; bank 3
.unbackground $7E80 $7FFF
; bank 7
.unbackground $FDC0 $FFFF
; bank 8
.unbackground $11CB4 $11FFF
; bank B
.unbackground $17A00 $17FFF

;==============================================================================
; code: 0
;==============================================================================

;===============================================
; ensure subtitle palette is always loaded
;===============================================

.define subtitleSpritePaletteIndex $1F

.bank $00 slot 2
.org $14AB
.section "palette force 1" overwrite
  jsr doSubtitlePaletteForce
    nop
.ends

.bank $00 slot 2
.section "palette force 2" free
  forcedSubtitlePaletteData:
    ; grayscale palette
    .rept $10 INDEX count
      .dw (count/2)|((count/2)<<3)|((count/2)<<6)
    .endr
    @end:
  .define forcedSubtitlePaletteData_size forcedSubtitlePaletteData@end-forcedSubtitlePaletteData
  
  doSubtitlePaletteForce:
    tii forcedSubtitlePaletteData,localBasePalette+(subtitleSpritePaletteIndex*paletteLineSize),forcedSubtitlePaletteData_size
    
    ; make up work
    stz $2C
    stz $2D
    rts
  
  doSubtitlePaletteForce2:
    tii forcedSubtitlePaletteData,localBasePalette+(subtitleSpritePaletteIndex*paletteLineSize),forcedSubtitlePaletteData_size
    
    ; make up work
    lda $35
    tam #$20
    rts
  
  ; FIXME: since we're targeting the last palette, this could be done
  ; more efficiently by reducing the count of palettes checked,
  ; then directly copying the final one
/*  doSubtitlePaletteFadeCheck:
    ; fetch current palette line number
    lda $25
    ; if not handling subtitle palette line, do usual behavior
    cmp #subtitleSpritePaletteIndex
    beq +
      ; make up work
      lda ($1E),Y
      sta $24
      jmp $61F3
    +:
    
    ; if handling subtitle palette, copy values directly,
    ; without doing the normal brightness manipulation
    lda ($1E),Y
    sta ($20),Y
    iny
    lda ($1E),Y
    sta ($20),Y
    jmp $623C */
  
  forceSubtitlePaletteAtSceneStart:
    ; TODO: this changes the bank in slot 5. is that safe?
    ; copy back palettes to front with brightness of zero
    ; (subtitle palette is special-cased to always be full brightness)
    cla
    jsr $61C0
    
    ; force subtitle palette to be transferred
    ; flag last palette as modified
    lda #$80
    sta $5390
    ; flag refresh as needed?
    ; ...doooon't do this
;    inc $00
    ; wait for vsync; interrupt handler takes care of the rest
;    jsr EX_VSYNC
    
    ; make up work
    lda #$00
    ldy #$08
    jmp $409F
.ends

; initial palette
.bank $00 slot 2
.org $12E5+(subtitleSpritePaletteIndex*paletteLineSize)
.section "palette force 3" overwrite
  ; grayscale palette
  .rept $10 INDEX count
    .dw (count/2)|((count/2)<<3)|((count/2)<<6)
  .endr
.ends

.bank $00 slot 2
.org $13B7
.section "palette force 4" overwrite
  jsr doSubtitlePaletteForce2
  nop
.ends

;; make subtitle palette immune to fade-outs
;.bank $01 slot 3
;.org $01EF
;.section "palette force 5" overwrite
;  jmp doSubtitlePaletteFadeCheck
;.ends

.bank $00 slot 2
.org $009B
.section "palette force 5" overwrite
  jmp forceSubtitlePaletteAtSceneStart
.ends

;===============================================
; make subtitle palette immune to fade-outs
;===============================================

.define nominalDisplayPaletteStart $A200
.define trueDisplayPaletteStart $A600

.bank $01 slot 3
.org $025C
.section "subtitle palette no fade-out 1" overwrite
  ; number of palettes to copy.
  ; subtitle palette is last, so we skip it
  cmp #$20-1
.ends

.bank $01 slot 3
.org $0265
.section "subtitle palette no fade-out 2" overwrite
  jmp copySubtitlePalette
.ends

.bank $00 slot 2
.section "subtitle palette no fade-out 3" free
  copySubtitlePalette:
    tii forcedSubtitlePaletteData,trueDisplayPaletteStart+(subtitleSpritePaletteIndex*paletteLineSize),paletteLineSize
    
    ; make up work
    sta $538C
    rts
.ends

;===============================================
; there's a copy of the intro load params here.
; don't know if it's used, but change it to
; to the new location to be safe
;===============================================

.include "out/include/cutscenes.inc"

.bank $08 slot 3
.org $1C93
.section "intro load params copy overwrite 1" overwrite
  .db intro_dataSectorNumLo
  .db intro_dataSectorNumMid
  .db intro_dataSectorNumHi
  .dw intro_dataSectorSize
.ends

;===============================================
; fix title screen scene viewer bug
;===============================================

; the game was intended, like many other PCE games,
; to have cheat codes at the title screen allowing
; the visual scenes to be viewed (hold button 1 or
; 2 while pressing Run at the title screen).
; however, due to what must have been a catastrophically
; bad testing cycle, they don't actually work and the game
; just crashes if they're used.
; might as well fix them!

.bank $08 slot 3
.org $1355
.section "fix title scene viewer preboss" overwrite
  ; this is supposed to be the load specifier for the ending cutscene.
  ; but someone screwed the parameters up pretty badly, resulting in
  ; the scene player not getting loaded but the game trying to jump
  ; to it anyway, immediately hitting a BRK, and crashing.
  ; so yeah, holding button 1 or 2 and pressing run at the title screen
  ; just straight up crashes it.
  ; somehow i get the feeling this game wasn't tested very carefully.
;  .db $00 $00 $00 $21 $05 $00 $3A $01 $00 $21 $00 $00 $31 $00 $00 $00 $00 $00 $00 $00 $01 $00 $40 $01

  ; here are the correct parameters, from the normal in-game code...
  .db $00 $00 $00
;  .db $21 $05 $00
;  .db $3A $01
  .db preboss_dataSectorNumLo
  .db preboss_dataSectorNumMid
  .db preboss_dataSectorNumHi
  .dw preboss_dataSectorSize
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $21 $00 $00 $31
.ends

.bank $08 slot 3
.org $137E
.section "fix title scene viewer ending" overwrite
;  .db $00 $00 $00 $21 $09 $00 $FC $00 $00 $21 $00 $00 $31 $00 $00 $00 $00 $00 $00 $00 $01 $00 $40 $01

  .db $00 $00 $00
;  .db $21 $09 $00
;  .db $FC $00
  .db ending_dataSectorNumLo
  .db ending_dataSectorNumMid
  .db ending_dataSectorNumHi
  .dw ending_dataSectorSize
  .db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $21 $00 $00 $31
  
.ends

;==============================================================================
; subtitles
;==============================================================================

;===============================================
; defines
;===============================================

; special bank token marking new ops
; (which have to be special-cased due to
; the use of fixed-size jump tables)
.define newCutOpBankToken $FF

; bank new ops' code is placed in
;.define newCutOpBankNum $0B
; anything with script params must go in bank 0 or 8
.define newCutOpBankNum $08

.define spritesOffFlag $3A
.define scriptPtr $41
.define satBaseAddr $2214

;===============================================
; old opcodes
;===============================================

; first byte = bank number
; second byte = task ID

;===========
; bank 4
;===========

; ? set up scrolling speed/target?
;.define cut_scroll $0408

;===========
; bank 8
;===========

; main interpreter loop
.define cut_interpret $0801

; read from AC card to memory
.define cut_acToBuf $0804
; read from AC card to VRAM
; (in increments of no more than 0x2000 bytes per frame)
.define cut_acToVram $0805
; copy from memory to VRAM
.define cut_memToVram $0806

; set the scene wait timer and idle until it expires
.define cut_setTimerAndWait $080B
; idle until the scene wait timer expires
.define cut_waitForTimer $080C
.define cut_checkButtons $080D

.define cut_fadeIn $080F
.define cut_fadeOut $0810

; zero-fill memory
.define cut_zeroFill $0818

; jump script execution to an arbitrary offset
.define cut_bra $081C
; jump to arbitrary code
.define cut_exec $081D

; disable sprites
.define cut_spritesOff $0822
; enable sprites
.define cut_spritesOn $0823

; set address of sprite attribute table in VRAM
; FIXME: this is not used in actual scripts;
; i don't trust it to work correctly
.define cut_setSatAddr $0826

;===============================================
; new SAT generation code to show subtitles
;===============================================

.define subtitleBaseX $20+32
;.define subtitleBaseY 192+64
.define subtitleBaseY 192+0
; flags: palette F, high priority
.define subtitleFlags $008F

.bank $00 slot 2
.org $10AA
.section "subtitle SAT generation 1" overwrite
  jsr generateSubtitleSat
  nop
  nop
.ends

.bank $00 slot 2
.section "subtitle SAT generation 2" free
  subtitleSatCurInputPattern:
    .dw $0000

  ; X = current input slot position?
  ;     make sure this is zero at end of routine
  ; Y = ???
  ;     from $16
  ; $17 = current VRAM address of SAT target
  ; $19 = current target SAT index
  generateSubtitleSat:
    ; make up work
    lda $2215.w
    sta $18
    
    ; check if subtitle is active, and do nothing if not
;    lda subtitleNumPatterns.w
;    beq @done
    lda subtitlesAreOn.w
    beq @done
;    bne +
;      jmp @done
;    +:
    
    lda subtitleNumPatterns.w
    
    ;=====
    ; subtitle is active: add to SAT.
    ; SAT is currently empty.
    ;=====
    
;    phx
    phy
    
      ; X = counter for input sprites
      asl
      tax
      
      ; the game does not want the first two sprites used, so skip them
      
      ; slotnum += 2
      inc $19
      inc $19
      
      ; write address += 8
      lda $17
      clc
      adc #8
      sta $17
      cla
      adc $18
      sta $18
      
      
      ; reset input pattern num to base
      lda subtitleBasePattern+0.w
      sta subtitleSatCurInputPattern+0.w
      lda subtitleBasePattern+1.w
      sta subtitleSatCurInputPattern+1.w
      
      @loop:
        ;=====
        ; set write address
        ;=====
        
        st0 #$00
        
        ; postincrement
        
        lda $17
        sta $0002.w
        clc
        adc #4
        sta $17
        
        lda $18
        sta $0003.w
        adc #$00
        sta $18
        
        ; start write
        st0 #$02
        
        ;=====
        ; word 0: y-pos
        ;=====
      
        ; A = y-offset
        dex
        lda subtitleAttrBuffer.w,X
        
        ; add offset
        clc
        adc #<subtitleBaseY
        sta $0002.w
        cla
        adc #>subtitleBaseY
        sta $0003.w
        
        ;=====
        ; word 1: x-pos
        ;=====
        
        ; A = x-offset
        dex 
        lda subtitleAttrBuffer.w,X
        
        ; add offset
        clc
        adc #<subtitleBaseX
        sta $0002.w
        cla
        adc #>subtitleBaseX
        sta $0003.w
        
        ;=====
        ; word 2: pattern num
        ;=====
        
        ; increment after write
        
/*        lda subtitleSatCurInputPattern+0.w
        sta $0002.w
        clc
        adc #2
        sta subtitleSatCurInputPattern+0.w
        
        lda subtitleSatCurInputPattern+1.w
        sta $0003.w
        adc #$00
        sta subtitleSatCurInputPattern+1.w */
        
        ; predecrement
        
        lda subtitleSatCurInputPattern+0.w
        sec
        sbc #2
        sta $0002.w
        sta subtitleSatCurInputPattern+0.w
        
        lda subtitleSatCurInputPattern+1.w
        sbc #$00
        sta $0003.w
        sta subtitleSatCurInputPattern+1.w
        
        ;=====
        ; word 3: flags
        ;=====
        
;        lda #<subtitleFlags
;        sta $0002.w
;        lda #>subtitleFlags
;        sta $0003.w
        
        st1 #<subtitleFlags
        st2 #>subtitleFlags
        
        ;=====
        ; increment target slot index
        ;=====
        
        inc $19
        
        ;=====
        ; loop until all sprites added
        ;=====
        
        cpx #$00
        bne @loop
    
    ply
;    plx
    
    ldx $19
    
    @done:
    rts
.ends

;===============================================
; alter game's high-priority sprite object
; generation to free up some initial slots
; for the subtitles
;===============================================

; this command is used only for one dialogue
; scene, which has only a few patterns' worth
; of text, and in the credits, so we can get
; away with not providing much space

.bank $00 slot 2
.org $0FFB
.section "free up high-priority slots 1" overwrite
  jsr freeHighPrioritySlots
.ends

.bank $00 slot 2
.section "free up high-priority slots 2" free
  freeHighPrioritySlots:
    ; make up work
    stx $15
    
    ; if scene 1 (preboss), use higher initial slot number,
    ; leaving lower indices for subtitles.
    ; otherwise (credits), use default of 0.
    clx
    pha
      lda sceneId.w
      cmp #1
      bne +
        ldx #12
      +:
    pla
    
    rts
.ends


;===============================================
; use new cutscene ops
;===============================================

.bank $00 slot 2
.org $00C7
.section "extra cutscene ops 1" overwrite
  jmp extraOpsCheck_active
.ends

.bank $00 slot 2
.section "extra cutscene ops 2" free
  ; X = slot index
  extraOpsCheck_active:
    ; make up work
    ; A = banknum
    lda $2865.w,X
    
    ; check bank number for special token
    cmp #newCutOpBankToken
    beq +
      jmp $40CA
    +:
    
    ; load bank for new ops
    lda #newCutOpBankNum
    ; add bank base
    clc
    adc $2701.w
    tam #$08
    
    ; read real jump target from new table
    
    ; get op ID
    lda $2845.w,X
    ; convert to offset
    asl
    tax
    ; fetch jump target
    lda newOpJumpTable+0.w,X
    sta $40E2.w
    lda newOpJumpTable+1.w,X
    sta $40E3.w
    
    jmp $40E1
    
.ends

;===============================================
; load data less frequently on "tall" panning
; vertical scenes
;===============================================

; the game has the ability to do automatic procedural loading
; of graphics for top-to-bottom vertical panning scenes
; (and only those).
; my god, you would not believe how much trouble this thing is.
; and it's used for exactly _one scene_ in the entire game.
; which of course is one of the ones we have to put subtitles over.
; well, to hell with it.
; i'm just turning off the automatic graphics loading and doing
; it manually where required instead.
; automatic tilemap loading remains.

.bank 3 slot 3
.org $1B4B
.section "no vertical pan autoload 1" overwrite
  jmp $7B5A
.ends
  

/*.define tallSceneAutoGraphicsLoadTotalSize $5000

; number of bytes of pattern data loaded to VRAM each time autoload triggered
.define tallSceneAutoGraphicsLoadSizeBytes $800
; mask value for scroll position to trigger autoload.
; when (ypos & mask) == 0, new graphics are loaded
;.define tallSceneAutoGraphicsLoadTriggerMask $7F
.define tallSceneAutoGraphicsLoadTriggerMask $3F
.define tallSceneAutoGraphicsLoadTotalNumTransfers tallSceneAutoGraphicsLoadTotalSize/tallSceneAutoGraphicsLoadSizeBytes/2


.define tallSceneAutoGraphicsLoadSizeWords tallSceneAutoGraphicsLoadSizeBytes/2

.bank 3 slot 3
.org $1B6A
.section "smaller vertical panning load intervals 1" overwrite
  and #tallSceneAutoGraphicsLoadTriggerMask
.ends

.bank 3 slot 3
.org $1C32
.section "smaller vertical panning load intervals 2" overwrite
  ; size of transfer (bytes)
  tia $8000,$0002,tallSceneAutoGraphicsLoadSizeBytes
  
  ; offset from old dstaddr
  clc
  lda $7906.w
  adc #<tallSceneAutoGraphicsLoadSizeWords
  sta $7906.w
  lda $7907.w
  adc #>tallSceneAutoGraphicsLoadSizeWords
  sta $7907.w
  
  ; offset from old srcaddr
  lda $78FE.w
  clc 
  adc #<tallSceneAutoGraphicsLoadSizeBytes
  sta $78FE.w
  lda $78FF.w
  adc #>tallSceneAutoGraphicsLoadSizeBytes
  sta $78FF.w
  lda $7900.w
  ; top byte of 24-bit value; will always be 0
  adc #$00
  sta $7900.w
  
  ; increment counter
  lda $7908.w
  ina
  sta $7908.w
  cmp #tallSceneAutoGraphicsLoadTotalNumTransfers
  bcs +
    lda #$33
    ldy #$03
    ldx #$01
    jsr $4307
    rts
  +:
  rts
.ends

.define panningLoadInitialVramDstTableScaleFactor 2
.define panningLoadInitialVramDstTableSize 3*panningLoadInitialVramDstTableScaleFactor

.bank 3 slot 3
.org $1BF4
.section "smaller vertical panning load intervals 3" overwrite
  lda tallSceneTopByteDstAddrTable.w,X
.ends

.bank 3 slot 3
.org $1BFB
.section "smaller vertical panning load intervals 4" overwrite
  cpx #panningLoadInitialVramDstTableSize
.ends

.bank 3 slot 3
.section "smaller vertical panning load intervals 5" free
  tallSceneTopByteDstAddrTable:
    .rept panningLoadInitialVramDstTableSize INDEX count
      .db $08+$28+(count*($28/panningLoadInitialVramDstTableScaleFactor))
    .endr
.ends */

;===============================================
; new ops
;===============================================

.define cut_showSubs    (newCutOpBankToken<<8)|$00
.define cut_clearSubs   (newCutOpBankToken<<8)|$01
.define cut_setUpScene  (newCutOpBankToken<<8)|$02
.define cut_loadSubs    (newCutOpBankToken<<8)|$03
.define cut_initProgressiveAcToVramWrite (newCutOpBankToken<<8)|$04
.define cut_doProgressiveAcToVramWrite (newCutOpBankToken<<8)|$05
.define cut_showSubsDelayed (newCutOpBankToken<<8)|$06
.define cut_showSubsDelayed_subtask (newCutOpBankToken<<8)|$07
.define cut_clearSubsDelayed (newCutOpBankToken<<8)|$08
.define cut_clearSubsDelayed_subtask (newCutOpBankToken<<8)|$09
.define cut_waitStd (newCutOpBankToken<<8)|$0A
.define cut_wait1FrameStd (newCutOpBankToken<<8)|$0B

.define spritePatternSize 128
.define memBaseOffset $2701

; subtitles may use up to 32 sprites.
; we store the following fields:
; - 1b x
; - 1b y
.define maxSubtitleSprites 32
.define subtitleAttrSize 2
.define subtitleAttrBufferSize maxSubtitleSprites*subtitleAttrSize

.bank 0 slot 2
.section "new cutscene ops globals" free
  subtitleAttrBuffer:
    .ds subtitleAttrBufferSize,$00
  subtitleNumPatterns:
    .db $00
  subtitleBasePattern:
    .dw $0000
  subtitlesAreOn:
    .db $00
  sceneId:
    .db $FF
.ends

.bank $B slot 3
.section "cutscene data tables 1" free
  .include "asm/include/cutscene_tables.inc"
    
  ; A = scene ID
  ;     0 = intro
  ;     1 = preboss
  ;     2 = ending
  setUpSceneById:
    sta sceneId.w
    asl
    tax
    
;    lda sceneGrpBaseTable+0.w,X
;    sta getPointerToCurrentSceneGrpByIndex@curCutsceneGrpArrayCmd+1.w
;    lda sceneGrpBaseTable+1.w,X
;    sta getPointerToCurrentSceneGrpByIndex@curCutsceneGrpArrayCmd+2.w
    
    lda sceneGrpBaseTable+0.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_srcCmd+1.w
    lda sceneGrpBaseTable+1.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_srcCmd+2.w
    
    lda sceneVramDstBaseTable+0.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_dstCmd+1.w
    lda sceneVramDstBaseTable+1.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_dstCmd+2.w
    
    lda scenePatternSizeBaseTable+0.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_sizeCmd+1.w
    lda scenePatternSizeBaseTable+1.w,X
    sta prepSubLoadArgs@prepSubLoadArgs_sizeCmd+2.w
    
    lda sceneAttrBaseTable+0.w,X
    sta loadSubAttributes@loadSubAttributes_srcCmd+1.w
    lda sceneAttrBaseTable+1.w,X
    sta loadSubAttributes@loadSubAttributes_srcCmd+2.w
    
    lda sceneNumPatternsBaseTable+0.w,X
    sta loadSubAttributes@loadSubAttributes_sizeCmd+1.w
    lda sceneNumPatternsBaseTable+1.w,X
    sta loadSubAttributes@loadSubAttributes_sizeCmd+2.w
    
    rts
  
  argLoadTemp:
    .db $00
  
  ; A = subtitle ID
  prepSubLoadArgs:
    pha
      ;=====
      ; src
      ;=====
      
      ; multiply by 3
      sta argLoadTemp.w
      asl
      clc
      adc argLoadTemp.w
      tax
      
      ldy #$03
      -:
      @prepSubLoadArgs_srcCmd:
        lda $0000.w,X
        pha
        inx
        dey
        bne -
      ; high
      pla
      sta $20
      ; mid
      pla
      sta $1F
      ; lo
      pla
      sta $1E
    pla
    
    pha
      ;=====
      ; dst
      ;=====
      
      asl
      tax
      
      ldy #$02
      -:
      @prepSubLoadArgs_dstCmd:
        lda $0000.w,X
        pha
        inx
        dey
        bne -
      ; high
      pla
      sta $25
      sta subtitleBasePattern+1.w
      ; lo
      pla
      sta $24
      sta subtitleBasePattern+0.w
      
      ; reduce raw address to pattern num
      .rept 5
        lsr subtitleBasePattern+1.w
        ror subtitleBasePattern+0.w
      .endr
    pla
    
    ;=====
    ; size
    ;=====
    
    asl
    tax
    
    ldy #$02
    -:
    @prepSubLoadArgs_sizeCmd:
      lda $0000.w,X
      pha
      inx
      dey
      bne -
    ; high
    pla
    sta $23
    ; lo
    pla
    sta $22
    
    ; add to base pattern num because this is the dumb format
    ; i wrote the routine to expect
    lda lastLoadedSubNumPatterns.w
    asl
    clc
    adc subtitleBasePattern+0.w
    sta subtitleBasePattern+0.w
    cla
    adc subtitleBasePattern+1.w
    sta subtitleBasePattern+1.w
    
    rts
  
  lastLoadedSubNumPatterns:
    .db $00
  
  loadSubAttributes:
    pha
      ;=====
      ; src
      ;=====
      
      ; multiply by 3
      sta argLoadTemp.w
      asl
      clc
      adc argLoadTemp.w
      tax
      
      ldy #$03
      -:
      @loadSubAttributes_srcCmd:
        lda $0000.w,X
        pha
        inx
        dey
        bne -
      ; high
      pla
      sta $1A04.w
      ; mid
      pla
      sta $1A03.w
      ; lo
      pla
      sta $1A02.w
    pla
    
    ; zero offset reg
    stz $1A05.w
    stz $1A06.w
    
    ;=====
    ; size
    ;=====
    
    tax
    
    @loadSubAttributes_sizeCmd:
    ; this value will not exceed 32
    lda $0000.w,X
    sta lastLoadedSubNumPatterns.w
;    pha
      sta subtitleNumPatterns.w
      asl
      sta @transferCommand+5.w
  ;    stz @transferCommand+6.w
;    pla
    
    @transferCommand:
    tai $1A00,subtitleAttrBuffer,$0000
    
    rts

  ; A = index
  ; returns YXA = address
/*  getPointerToCurrentSceneGrpByIndex:
    asl
    asl
    tax
    ldy #$02
    -:
    @curCutsceneGrpArrayCmd:
      lda $0000,X
      pha
      inx
      dey
      bne -
    ; high byte
    pla
    tay
    ; low byte
    pla
    rts */
.ends

;.bank newCutOpBankNum slot 3
.bank 0 slot 2
.section "new cutscene ops 1" free
  ;=====
  ; helper routines
  ;=====
  
  continueInterpreter:
    ; interpreter loop
    lda #$01
    ldy #$08
    jmp addActiveTask
  
  loadScriptDataBank:
    lda #$08
    clc
    adc memBaseOffset.w
    tam #$08
    rts
  
  fetchScriptByte:
    lda (scriptPtr)
    inc scriptPtr
    bne +
      inc scriptPtr+1
    +:
    rts
  
  ; assumes bank 8 loaded in slot 3.
  ; call as subroutine;
  ; if button pressed, caller is cancelled
  ; and interpreter continues
  cancelIfButtonPressed:
    pha
    lda $2228.w
    and $45
    
    beq +
      pla
      pla
      pla
      bra continueInterpreter
    +:
    pla
    rts
  
  ;=====
  ; op table
  ;=====
    
  newOpJumpTable:
    ; op 00
    .dw cut_showSubs_def
    ; op 01
    .dw cut_clearSubs_def
    ; op 02
    .dw cut_setUpScene_def
    ; op 03
    .dw cut_loadSubs_def
    ; op 04
    .dw cut_initProgressiveAcToVramWrite_def
    ; op 05
    .dw cut_doProgressiveAcToVramWrite_def
    ; op 06
    .dw cut_showSubsDelayed_def
    ; op 07
    .dw cut_showSubsDelayed_subtask_def
    ; op 08
    .dw cut_clearSubsDelayed_def
    ; op 09
    .dw cut_clearSubsDelayed_subtask_def
    ; op 0A
    .dw cut_waitStd_def
    ; op 0B
    .dw cut_wait1FrameStd_def
  
  ;=====
  ; op logic
  ;=====
  
  cut_showSubs_def:
/*    jsr loadScriptDataBank
    
    ; 2b vram baseaddr
    lda (scriptPtr)
    sta subtitleBasePattern+0.w
    ldy #$01
    lda (scriptPtr),Y
    sta subtitleBasePattern+1.w
    
    ; 1b numpatterns
    iny
    lda (scriptPtr),Y
    sta subtitleNumPatterns.w
    
    ; advance scriptptr
    lda #$03
    clc
    adc scriptPtr+0
    sta scriptPtr+0
    cla
    adc scriptPtr+1
    sta scriptPtr+1 */
    
    jsr loadScriptDataBank
    jsr cancelIfButtonPressed
    
    lda #$FF
    sta subtitlesAreOn.w
    
    ; interpreter loop
    jmp continueInterpreter
  
  cut_clearSubs_def:
;    jsr loadScriptDataBank
;    jsr cancelIfButtonPressed
    
    stz subtitlesAreOn.w
    
    ; interpreter loop
    jmp continueInterpreter
  
  cut_setUpScene_def:
    ; fetch script byte = scene ID
    jsr loadScriptDataBank
    jsr fetchScriptByte
    
    ; call setup routine with ID as param
    pha
      lda #:setUpSceneById
      clc
      adc memBaseOffset.w
      tam #$08
    pla
    jsr setUpSceneById
    
    jmp continueInterpreter
  
  cut_loadSubs_def:
    ; fetch script byte = subtitle ID
    jsr loadScriptDataBank
    jsr fetchScriptByte
    jsr cancelIfButtonPressed
    
    tax
      lda #:loadSubAttributes
      clc
      adc memBaseOffset.w
      tam #$08
    txa
    pha
      jsr loadSubAttributes
    pla
    
    jsr prepSubLoadArgs
    
    ; execute the normal tile load logic
    lda #$08
    clc
    adc memBaseOffset.w
    tam #$08
    jmp $61EB
    
;    jmp continueInterpreter
  
  progAcToVramSrc:
    .ds 3,$00
  progAcToVramDst:
    .dw $0000
  progAcToVramSize:
    .dw $0000
  progAcToVramWordSize:
    .dw $0000
  
  cut_initProgressiveAcToVramWrite_def:
    jsr loadScriptDataBank
    
    ; 3b src
    lda (scriptPtr)
    sta progAcToVramSrc+0.w
    ldy #$01
    lda (scriptPtr),Y
    sta progAcToVramSrc+1.w
    iny
    lda (scriptPtr),Y
    sta progAcToVramSrc+2.w
    
    ; 2b dst
    iny
    lda (scriptPtr),Y
    sta progAcToVramDst+0.w
    iny
    lda (scriptPtr),Y
    sta progAcToVramDst+1.w
    
    ; 2b size
    iny
    lda (scriptPtr),Y
    sta progAcToVramSize+0.w
    sta progAcToVramWordSize+0.w
    iny
    lda (scriptPtr),Y
    sta progAcToVramSize+1.w
    sta progAcToVramWordSize+1.w
    
    ; word size = byte size/2
    lsr progAcToVramWordSize+1.w
    ror progAcToVramWordSize+0.w
    
    ; advance scriptptr
    lda #$07
    clc
    adc scriptPtr+0
    sta scriptPtr+0
    cla
    adc scriptPtr+1
    sta scriptPtr+1
    
    jmp continueInterpreter
  
  cut_doProgressiveAcToVramWrite_def:
    jsr loadScriptDataBank
    jsr cancelIfButtonPressed
    
    ; set up params
    
    ; src
    
    lda progAcToVramSrc+0.w
    sta $1E
    clc
    adc progAcToVramSize+0.w
    sta progAcToVramSrc+0.w
    
    lda progAcToVramSrc+1.w
    sta $1F
    adc progAcToVramSize+1.w
    sta progAcToVramSrc+1.w
    
    lda progAcToVramSrc+2.w
    sta $20
    adc #$00
    sta progAcToVramSrc+2.w
    
    ; dst
    
    lda progAcToVramDst+0.w
    sta $24
    clc
    adc progAcToVramWordSize+0.w
    sta progAcToVramDst+0.w
    
    lda progAcToVramDst+1.w
    sta $25
    adc progAcToVramWordSize+1.w
    sta progAcToVramDst+1.w
    
    ; size
    
    lda progAcToVramSize+0.w
    sta $22
    lda progAcToVramSize+1.w
    sta $23
    
    jmp $61EB
    
  subDelayCounter:
    .db $00
  
  cut_showSubsDelayed_def:
    jsr loadScriptDataBank
    jsr fetchScriptByte
    jsr cancelIfButtonPressed
    
    sta subDelayCounter.w
    bsr cut_showSubsDelayed_subtask_def@addSelf
    
    jmp continueInterpreter
    
  cut_showSubsDelayed_subtask_def:
    jsr loadScriptDataBank
;    jsr cancelIfButtonPressed
    
    dec subDelayCounter.w
    bne +
      lda #$FF
      sta subtitlesAreOn.w
      rts
    +:
    @addSelf:
    ; ID
    lda #<cut_showSubsDelayed_subtask
    ; bank (token)
    ldy #newCutOpBankToken
    ; delay
    ldx #$01
    jmp addIdleTask
    
  subClearDelayCounter:
    .db $00
  
  cut_clearSubsDelayed_def:
    jsr loadScriptDataBank
    jsr fetchScriptByte
    jsr cancelIfButtonPressed
    
    sta subClearDelayCounter.w
    bsr cut_clearSubsDelayed_subtask_def@addSelf
    
    jmp continueInterpreter
    
  cut_clearSubsDelayed_subtask_def:
    jsr loadScriptDataBank
;    jsr cancelIfButtonPressed
    
    dec subClearDelayCounter.w
    bne +
      stz subtitlesAreOn.w
      rts
    +:
    @addSelf:
    ; ID
    lda #<cut_clearSubsDelayed_subtask
    ; bank (token)
    ldy #newCutOpBankToken
    ; delay
    ldx #$01
    jmp addIdleTask
  
  cut_waitStd_def:
    jsr loadScriptDataBank
    
    ; time
    lda (scriptPtr)
    sta $43
    ldy #$01
    lda (scriptPtr),Y
    sta $44
    
    ; advance scriptptr
    lda scriptPtr
    clc
    adc #$02
    sta scriptPtr
    cla
    adc scriptPtr+1
    sta scriptPtr+1
    
    @finish:
    ; flag as not yet pressed
    stz $6651
    ; buttons to check
    lda #$08
    sta $45
    
    jmp $6671
  
  cut_wait1FrameStd_def:
    jsr loadScriptDataBank
    
    ; time
    lda #$01
    sta $43
    stz $44
    bra cut_waitStd_def@finish
    
  
.ends

;==============================================================================
; modifications to script data
;==============================================================================

.bank $08 slot 3

;===============================================
; intro
;===============================================

/*;=====
; 00
;=====

.org $1206
.section "intro cut mod 00_0" overwrite
  .dw cut_bra,cutmod_00
.ends

.section "intro cut mod 00_1" free
  cutmod_00:
    ; test
;    .dw cut_setSatAddr
;      .dw $1000
;    .dw cut_spritesOn
    
    .dw cut_acToVram
      ; ac card src
      .db intro_sub00PatternsOffsetLo
      .db intro_sub00PatternsOffsetMid
      .db intro_sub00PatternsOffsetHi
      ; vram dst
      .dw $7800
      ; size
      .dw intro_sub00PatternsSize
    
    .dw cut_acToBuf
      ; ac card src
      .db intro_sub00AttributesOffsetLo
      .db intro_sub00AttributesOffsetMid
      .db intro_sub00AttributesOffsetHi
      ; dst
      .dw subtitleAttrBuffer
      ; size
      .dw intro_sub00AttributesSize
    
    .dw cut_setSatAddr $7700
    .dw cut_spritesOn
    
    .dw cut_showSubs
      .dw ($7800/spritePatternSize*4)+(intro_sub00NumPatterns*2)
      .db intro_sub00NumPatterns
    
    ; make up work
;    .dw cut_waitStd
;      .dw $384
;      .db $08
      
    .dw cut_waitStd
      .dw $40
    
    .dw cut_clearSubs
      
    .dw cut_waitStd
      .dw $344
    
    .dw cut_bra,$720B
.ends */

;===============
; 00
;===============

.define intro_scene0_satOffset $7700
.define intro_scene0_patternOffset $7800

.org $11F6
.section "intro cut mod 00 0" overwrite
  .dw cut_bra,cutmod_00_0
.ends

.section "intro cut mod 00 1" free
  cutmod_00_0:
    ; test
;    .dw cut_setSatAddr
;      .dw $1000
;    .dw cut_spritesOn
    
    ; set up for intro
    .dw cut_setUpScene
      .db $00
    
    ; load subtitle 1
    .dw cut_loadSubs
      .db $00
    
/*    .dw cut_acToVram
      ; ac card src
      .db intro_sub00PatternsOffsetLo
      .db intro_sub00PatternsOffsetMid
      .db intro_sub00PatternsOffsetHi
      ; vram dst
      .dw intro_scene0_patternOffset
      ; size
      .dw intro_sub00PatternsSize
    
    .dw cut_acToBuf
      ; ac card src
      .db intro_sub00AttributesOffsetLo
      .db intro_sub00AttributesOffsetMid
      .db intro_sub00AttributesOffsetHi
      ; dst
      .dw subtitleAttrBuffer
      ; size
      .dw intro_sub00AttributesSize */
    
    .dw cut_setSatAddr intro_scene0_satOffset
    .dw cut_spritesOn
    
;    .dw cut_showSubs
    .dw cut_showSubsDelayed
      .db 22
    
    ; make up work
    .dw $0818
      .dw $2BC5
      .dw $0200
    .dw cut_bra,$71FC
.ends

;===============
; 00-03
; total target time for section: 900 frames
;===============


.bank $08 slot 3
.org $1206
.section "intro cut mod 00 2" overwrite
  .dw cut_bra,cutmod_00_1
.ends

.section "intro cut mod 00 3" free
  cutmod_00_1:
    ; test
;    .dw cut_setSatAddr
;      .dw $1000
;    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 299
    
    ; end line 00
    .dw cut_clearSubs
      
    .dw cut_wait1FrameStd
      
;    .dw cut_checkButtons
;      .db $7310
    
    ;=====
    ; 01
    ;=====
    
    .dw cut_loadSubs
      .db $01
    
    .dw cut_showSubs
    
    ; make up work
;    .dw cut_waitStd
;      .dw $384
;      .db $08
      
    .dw cut_waitStd
      .dw 405
    
    ; end line 01
    .dw cut_clearSubs
      
    .dw cut_wait1FrameStd
    
    ;=====
    ; 02
    ;=====
    
    .dw cut_loadSubs
      .db $02
    
    .dw cut_showSubs
      
    .dw cut_waitStd
      .dw 193
    
    ; end line 02
;    .dw cut_clearSubs
    .dw cut_clearSubsDelayed
      .db 10
      
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$720B
.ends

;===============
; 03-10
; target time: 1470 frames
;===============

; this might look bad, but it was twice as long before i
; optimized the scripting system, so be glad you're
; not looking at that

.define intro_scene1_satOffset_0 $0800
.define intro_scene1_patternOffset_0 $6200
.define intro_scene1_satOffset_1 $0E00+$800
.define intro_scene1_patternOffset_1 $0E00
.define intro_scene1_satOffset_2 $1700
.define intro_scene1_patternOffset_2 $2200
.define intro_scene1_satOffset_3 $3800
.define intro_scene1_patternOffset_3 $3900
.define intro_scene1_satOffset_4 $4F00
.define intro_scene1_patternOffset_4 $4900
.define intro_scene1_satOffset_5 $6700
.define intro_scene1_patternOffset_5 $7000
.define intro_scene1_satOffset_6 $0800
.define intro_scene1_patternOffset_6 $2000
;.define intro_scene1_satOffset_2 $5000+$800
;.define intro_scene1_patternOffset_2 $5000

.bank $08 slot 3
.org $1253
.section "intro cut mod 04 1" overwrite
  .dw cut_bra,cutmod_04_0
.ends

.bank $00 slot 2
.section "intro cut mod 04 2" free
  cutmod_04_0:
    ;=====
    ; 03
    ;=====
      
    .dw cut_wait1FrameStd
      
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_loadSubs
      .db 3
    
    .dw cut_showSubs
    
    .dw cut_setSatAddr intro_scene1_satOffset_0
    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 249
    
    .dw cut_clearSubs
      
    .dw cut_wait1FrameStd
      
    .dw cut_checkButtons
      .dw $7310
    
    ;=====
    ; 04
    ;=====
    
    .dw cut_spritesOff
    
    ; copy the proper graphics back over the data we previously overwrote
    ; with subtitle sprites
    .dw cut_acToVram
      ; ac card src
      .db $01,$30,$14
      ; vram dst
      .dw $6200
      ; size
      .dw $600*2
    
    .dw cut_waitStd
      .dw 44
    
    .dw cut_loadSubs
      .db 4
    
    .dw cut_showSubs
      
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_setSatAddr intro_scene1_satOffset_1
    .dw cut_spritesOn
      
    .dw cut_waitStd
;      .dw 98-10
      .dw 88
    
    .dw cut_clearSubs
    
    .dw cut_spritesOff
    
    ; transfer next $5000 bytes of tile data,
    ; slowly enough not to cause lag
    
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01
      .db $6C
      .db $14
      ; vram dst
      .dw $0800
      ; size
      .dw $0800
    .rept 10
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
      
    
    ;=====
    ; 05
    ;=====
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_loadSubs
      .db 5
    
    .dw cut_showSubs
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_setSatAddr intro_scene1_satOffset_2
    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 188
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    .dw cut_spritesOff
    
    .dw cut_checkButtons
      .dw $7310
      
    ; repair the graphics we damaged with the subtitles
    .dw cut_acToVram
      ; ac card src
      ; LOW 16 BITS MUST NOT OVERFLOW
      .dw $6C01+$3400
      .db $14
      ; vram dst
      .dw intro_scene1_patternOffset_2
      ; size
      .dw $0600*2
    .dw cut_wait1FrameStd
    .dw cut_checkButtons
      .dw $7310
    .dw cut_acToVram
      ; ac card src
      ; LOW 16 BITS MUST NOT OVERFLOW
      .dw $6C01+$1E00
      .db $14
      ; vram dst
      .dw intro_scene1_satOffset_2
      ; size
      .dw $0100*2
    .dw cut_wait1FrameStd
    .dw cut_checkButtons
      .dw $7310
    
    ;=====
    ; 06
    ;=====
    
    .dw cut_waitStd
      .dw 45
      
    ;===
    ; left half 1
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01
      .db $BC
      .db $14
      ; vram dst
      .dw $3000
      ; size
      .dw $800
    .rept 2
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    ;===
    ; right half 1
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01
      .db $E4
      .db $14
      ; vram dst
      .dw $4400
      ; size
      .dw $800
    .rept 2
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    
    .dw cut_loadSubs
      .db 6
    
    .dw cut_showSubs
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_setSatAddr intro_scene1_satOffset_3
    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 153
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    .dw cut_spritesOff
    
    ;=====
    ; 07
    ;=====
    
    ;===
    ; left half 2
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01,$C4,$14
      ; vram dst
      .dw $3000+(1*$400)
      ; size
      .dw $800
    .rept 4
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    ;===
    ; right half 2
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01,$EC,$14
      ; vram dst
      .dw $4400+(1*$400)
      ; size
      .dw $800
    .rept 4
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    
    .dw cut_loadSubs
      .db 7
    
    .dw cut_showSubs
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_setSatAddr intro_scene1_satOffset_4
    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 200
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    .dw cut_spritesOff
    
    ;=====
    ; 08
    ;=====
    
    ;===
    ; right half 2
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01,$EC,$14
      ; vram dst
      .dw $4400+(1*$400)
      ; size
      .dw $800
    .rept 4
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
      
    ; THIS IS THE START OF FRAME 1000
    
    .dw cut_waitStd
      .dw 97
    
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01,$0C,$15
      ; vram dst
      .dw $0800+($2800*2)
      ; size
      .dw $800
    .rept 10
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    
    .dw cut_loadSubs
      .db 8
    
    .dw cut_showSubs
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_setSatAddr intro_scene1_satOffset_5
    .dw cut_spritesOn
      
    .dw cut_waitStd
      .dw 218
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    .dw cut_spritesOff
    
    .dw cut_initProgressiveAcToVramWrite
      ; ac card src
      .db $01,$3C,$15
      ; vram dst
      .dw $7000
      ; size
      .dw $800
    .rept 2
      .dw cut_checkButtons
        .dw $7310
      .dw cut_doProgressiveAcToVramWrite
      .dw cut_wait1FrameStd
    .endr
    
    ; time: 1328 frames
    
    ;=====
    ; 09
    ;=====
    
    .dw cut_waitStd
;      .dw 142
      .dw 65
    
    .dw cut_loadSubs
      .db 9
    
    .dw cut_showSubs
    
    ; FINALLY reset to default
    .dw cut_setSatAddr intro_scene1_satOffset_6
    .dw cut_spritesOn
    
    .dw cut_waitStd
      .dw 77
    
    ;=====
    ; blink animation
    ;=====
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_acToVram
      ; ac card src
      .db $01,$5E,$15
      ; vram dst
      .dw $1000
      ; size
      .dw $2000
    
;    .dw cut_spritesOn
    ; trigger animation?
    .dw $0318
    .dw cut_waitStd
;      .dw 450
;      .dw 393
      .dw 150
    
    ;=====
    ; 10
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 80
    
    .dw cut_loadSubs
      .db 10
    
    .dw cut_showSubs
    
    .dw cut_waitStd
;      .dw 247
      .dw 230
    
    .dw cut_clearSubs
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_bra,$726E
.ends

;===============
; 11-13
;===============

.bank $08 slot 3
;.org $127A
.org $12AC
.section "intro cut mod 11 1" overwrite
  .dw cut_bra,cutmod_11_0
.ends

.bank $00 slot 2
.section "intro cut mod 11 2" free
  cutmod_11_0:
    ; make up work
/*    .dw cut_checkButtons
      .db $10
      .dw $7310
    
    .dw cut_acToVram
      .db $01,$80,$15
      .dw $0000
      .dw $1000 */
    
;    .dw cut_waitStd
;      .dw $96
    
    ;=====
    ; 11
    ;=====
    
    .dw cut_loadSubs
      .db 11
    .dw cut_showSubs
    
    .dw cut_wait1FrameStd
    
    .dw cut_checkButtons
      .dw $7310
    
    ; make up work
    .dw cut_fadeIn
      .db $08,$FF,$FF,$FF,$FF,$01
    
    .dw cut_waitStd
      .dw 7
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 12
    ;=====
    
    .dw cut_loadSubs
      .db 12
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 75
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 13
    ;=====
    
    .dw cut_loadSubs
      .db 13
    .dw cut_showSubs
    
    .dw cut_waitStd
;      .dw 66
      .dw 50
;      .dw 60
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 14
    ;=====
    
/*    .dw cut_loadSubs
      .db 14
    
    ; this needs to show up partway through a fadeout
    .dw cut_showSubsDelayed
      .db 60 */
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_bra,$72B9
.ends

;===============
; 14-15
;===============

.bank $08 slot 3
.org $12F5
.section "intro cut mod 14 1" overwrite
  .dw cut_bra,cutmod_14_0
.ends

.bank $00 slot 2
.section "intro cut mod 14 2" free
  cutmod_14_0:
/*    .dw cut_waitStd
      .dw $258 */
    
;    .dw cut_clearSubsDelayed
;      .db 60
    
    ;=====
    ; 14
    ;=====
    
    .dw cut_waitStd
      .dw 0
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_loadSubs
      .db 14
    .dw cut_showSubs
    
    .dw cut_clearSubsDelayed
      .db 45
    
    .dw cut_checkButtons
      .dw $7310
    
    ; make up work
    .dw cut_fadeIn
      .db $08,$FF,$FF,$FF,$FF,$01
    
;    .dw cut_waitStd
;      .dw 60
;      .db $08
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1
;      .db $08
    
    .dw cut_waitStd
      .dw 25
    
    ;=====
    ; 15
    ;=====
    
    .dw cut_loadSubs
      .db 15
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 127
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ; total frames: 259
    
    .dw cut_waitStd
      .dw 341+10
    
    .dw cut_checkButtons
      .dw $7310
    
    .dw cut_bra,$7302
.ends

;===============================================
; preboss
;===============================================

.bank $08 slot 3

;=====
; 01-03
; target time: 1260 frames
;=====

.org $13A2
.section "preboss cut mod 00 0" overwrite
  .dw cut_bra,cutmod_preboss_00_0
.ends

.section "preboss cut mod 00 1" free
  cutmod_preboss_00_0:
    ; set up for preboss
    .dw cut_setUpScene
      .db $01
    
    ;=====
    ; 01
    ;=====
    
    .dw cut_waitStd
      .dw 276
    
    .dw cut_checkButtons
      .dw $790C
    
    .dw cut_loadSubs
      .db $01
    .dw cut_showSubs
    
    .dw cut_setSatAddr $0800
    .dw cut_spritesOn
    
    .dw cut_waitStd
      .dw 307
    
    ;=====
    ; 02
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db $02
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 374
    
    ;=====
    ; 03
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db $03
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 242
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 59
    
    
    
    
    
    
    
;    .dw cut_waitStd
;      .dw $4EC
;      .db $08
    
    .dw cut_bra,$73A7
.ends

;=====
; 04-
; target time: 300 frames
;=====

.org $13EC
.section "preboss cut mod 04 0" overwrite
  .dw cut_bra,cutmod_preboss_04_0
.ends

.section "preboss cut mod 04 1" free
  cutmod_preboss_04_0:
    
    .dw cut_waitStd
      .dw $1E
    
    ; ?
    .dw $040B
    
    ;=====
    ; 04
    ;=====
    
    .dw cut_waitStd
      .dw 35
    
    .dw cut_loadSubs
      .db $04
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 58
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 04 (*2)
    ;=====
    
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 50
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 05
    ;=====
    
    .dw cut_loadSubs
      .db $05
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 92
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 06
    ;=====
    
    .dw cut_loadSubs
      .db $06
    .dw cut_showSubs
    
    .dw cut_waitStd
;      .dw 83
      .dw 61
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1
;      .db $08
    
    .dw cut_clearSubsDelayed
      .db 6
    
;    .dw cut_waitStd
;      .dw $12C
;      .db $08

    
    .dw cut_bra,$73F8
.ends

;=====
; load patch tilemap 0
;=====

.org $1418
.section "preboss cut mod patch0 0" overwrite
  .dw cut_bra,cutmod_preboss_patch0_0
.ends

.section "preboss cut mod patch0 1" free
  cutmod_preboss_patch0_0:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$40,$01
      ; dst
      .dw $5000
      ; size
      .dw $6000
    
    ; load patch graphics
    .dw cut_acToVram
      ; src
      .db preboss_patch0GrpOffsetLo
      .db preboss_patch0GrpOffsetMid
      .db preboss_patch0GrpOffsetHi
      ; dst
      .dw $7A00
      ; size
      .dw preboss_patch0GrpSize
    
    .dw cut_bra,$7421
.ends

;=====
; 07-
; target time: 240 frames
;=====

.org $143C
.section "preboss cut mod 07 0" overwrite
  .dw cut_bra,cutmod_preboss_07_0
.ends

.section "preboss cut mod 07 1" free
  cutmod_preboss_07_0:
    ;=====
    ; 07
    ;=====
    
    .dw cut_loadSubs
      .db $07
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 134
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 08
    ;=====
    
    .dw cut_loadSubs
      .db $08
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 95
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 1+36
    
    ;=====
    ; 09
    ;=====
    
    .dw cut_loadSubs
      .db $09
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 2
    
    
    
    .dw cut_bra,$7441
.ends

;=====
; 09 cutoff
; target time: 300 frames
;=====

.org $1456
.section "preboss cut mod 09 2" overwrite
  ; do not overwrite the bottom half of the tilemap (which contains
  ; the sprite table and subtitle graphics, and isn't visible anyway)
  .dw $2000/2
.ends

.org $1480
.section "preboss cut mod 09 0" overwrite
  .dw cut_bra,cutmod_preboss_09_0
.ends

.section "preboss cut mod 09 1" free
  cutmod_preboss_09_0:
    
    .dw cut_waitStd
      .dw 106
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 1+193-15
    
    .dw cut_bra,$7485
    
.ends

;=====
; 10
; target time: 120 frames
;=====

.org $1491
.section "preboss cut mod 10 0" overwrite
  .dw cut_bra,cutmod_preboss_10_0
.ends

.section "preboss cut mod 10 1" free
  cutmod_preboss_10_0:
    ; load patch tilemap
    .dw cut_acToVram
      ; src
      .db preboss_patch1MapOffsetLo
      .db preboss_patch1MapOffsetMid
      .db preboss_patch1MapOffsetHi
      ; dst
      .dw $0000
      ; size
      .dw preboss_patch1MapSize
    
    ; load main graphics
    .dw cut_acToVram
      ; src
      .db $01,$C0,$00
      ; dst
      .dw $1000
      ; size
      .dw $8000
    
    ; load sprite graphics
    .dw cut_acToVram
      ; src
      .db $01,$66,$02
      ; dst
      .dw $5000
      ; size
      .dw $6000
    
    ; load patch graphics
    .dw cut_acToVram
      ; src
      .db preboss_patch1GrpOffsetLo
      .db preboss_patch1GrpOffsetMid
      .db preboss_patch1GrpOffsetHi
      ; dst
      .dw $7A80
      ; size
      .dw preboss_patch1GrpSize
    
    .dw cut_bra,$74AC
    
.ends

.org $14D0
.section "preboss cut mod 10 2" overwrite
  .dw cut_bra,cutmod_preboss_10_1
.ends

.section "preboss cut mod 10 3" free
  cutmod_preboss_10_1:
    ;=====
    ; 10
    ;=====
    
    .dw cut_waitStd
      .dw 5
    
    .dw cut_loadSubs
      .db 10
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 60
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 40
    
    .dw cut_bra,$74D5
.ends

;=====
; 11
; target time: 360 frames
;=====

.org $1519
.section "preboss cut mod 11 0" overwrite
  .dw cut_bra,cutmod_preboss_11_0
.ends

.section "preboss cut mod 11 1" free
  cutmod_preboss_11_0:
    ;=====
    ; 11
    ;=====
    
    .dw cut_loadSubs
      .db 11
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 359
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$751E
.ends

;=====
; 13
; target time: 780 frames
;=====

.org $1562
.section "preboss cut mod 13 0" overwrite
  .dw cut_bra,cutmod_preboss_13_0
.ends

.section "preboss cut mod 13 1" free
  cutmod_preboss_13_0:
    .dw cut_waitStd
      .dw 125
      
    ;=====
    ; 13
    ;=====
    
    .dw cut_loadSubs
      .db 13
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 254
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
      
    ;=====
    ; 14
    ;=====
    
    .dw cut_loadSubs
      .db 14
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 256
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 1+143
    
    .dw cut_bra,$7567
.ends

;=====
; 16-18
; target time: 410 frames
;=====

.org $15B3
.section "preboss cut mod 16 0" overwrite
  .dw cut_bra,cutmod_preboss_16_0
.ends

.section "preboss cut mod 16 1" free
  cutmod_preboss_16_0:
    ;=====
    ; 16
    ;=====
    
    .dw cut_waitStd
      .dw 115
    
    .dw cut_loadSubs
      .db 16
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 94
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 17
    ;=====
    
    .dw cut_loadSubs
      .db 17
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 75
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1+125
;      .db $08
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 1+77
    
    ;=====
    ; 18
    ;=====
    
    .dw cut_loadSubs
      .db 18
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 47
    
    .dw cut_clearSubs
    
    .dw cut_wait1FrameStd
      
    .dw cut_checkButtons
      .dw $790C
    
    .dw cut_bra,$75B8
.ends

;=====
; 19
; target time: 60 frames
; (yes it's that short)
;=====

.org $160D
.section "preboss cut mod 19 0" overwrite
  .dw cut_bra,cutmod_preboss_19_0
.ends

.section "preboss cut mod 19 1" free
  cutmod_preboss_19_0:
    
    ;=====
    ; 19
    ;=====
    
    .dw cut_loadSubs
      .db 19
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 59
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1
;      .db $08
    .dw cut_clearSubsDelayed
      .db 7
    
    .dw cut_bra,$7612
.ends

;=====
; 20
; target time: 300 frames
;=====

.org $1656
.section "preboss cut mod 20 0" overwrite
  .dw cut_bra,cutmod_preboss_20_0
.ends

.section "preboss cut mod 20 1" free
  cutmod_preboss_20_0:
    
    ;=====
    ; 20
    ;=====
    
    .dw cut_waitStd
      .dw 20
    
    .dw cut_loadSubs
      .db 20
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 279
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1
;      .db $08
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$765B
.ends

;=====
; 21
; target time: 120 frames
;=====

.org $169F
.section "preboss cut mod 21 0" overwrite
  .dw cut_bra,cutmod_preboss_21_0
.ends

.section "preboss cut mod 21 1" free
  cutmod_preboss_21_0:
    
    ;=====
    ; 21
    ;=====
    
    .dw cut_loadSubs
      .db 21
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 119+1
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1
;      .db $08
    .dw cut_clearSubsDelayed
      .db 7
    
    .dw cut_bra,$76A4
.ends

;=====
; 22-28
; target time: 2730 frames
;=====

.org $16E8
.section "preboss cut mod 22 0" overwrite
  .dw cut_bra,cutmod_preboss_22_0
.ends

.section "preboss cut mod 22 1" free
  cutmod_preboss_22_0:
    
    ;=====
    ; 22
    ;=====
    
    .dw cut_waitStd
      .dw 42
    
    .dw cut_loadSubs
      .db 22
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 72
    
    ;=====
    ; 23
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 26
    
    .dw cut_loadSubs
      .db 23
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 297
    
    ;=====
    ; 24
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 60
    
    .dw cut_loadSubs
      .db 24
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 483
    
    ;=====
    ; 25
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 57
    
    .dw cut_loadSubs
      .db 25
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 282
    
    ;=====
    ; 26
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 26
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 168
    
    ;=====
    ; 27
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 165
    
    .dw cut_loadSubs
      .db 27
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 374
    
    ; 2027/2730
    
    ;=====
    ; 28
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 53
    
    .dw cut_loadSubs
      .db 28
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 76
    
    ;=====
    ; 29
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 37
    
    .dw cut_loadSubs
      .db 29
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 162
    
    ; 2355/2730
    
    ;=====
    ; 30
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 38
    
    .dw cut_loadSubs
      .db 30
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 358-21
    
    .dw cut_clearSubsDelayed
      .db 7
    
/*    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 165
    
    .dw cut_loadSubs
      .db 28
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 374 */
    
    ; 2566/2730
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 1+164
;      .db $08
    
;    .dw cut_waitStd
;      .dw 2730
;      .db $08
    
    .dw cut_bra,$76ED
.ends

;=====
; 31
; target time: 90 frames
;=====

.org $1731
.section "preboss cut mod 31 0" overwrite
  .dw cut_bra,cutmod_preboss_31_0
.ends

.section "preboss cut mod 31 1" free
  cutmod_preboss_31_0:
    
    ;=====
    ; 31
    ;=====
    
    .dw cut_loadSubs
      .db 31
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 89
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    ;=====
    ; 32
    ;=====
    
    .dw cut_loadSubs
      .db 32
    .dw cut_showSubsDelayed
      .db 12
    
    .dw cut_bra,$7736
.ends

;=====
; 32-33
; target time: 330 frames
;=====

.org $177A
.section "preboss cut mod 32 0" overwrite
  .dw cut_bra,cutmod_preboss_32_0
.ends

.section "preboss cut mod 32 1" free
  cutmod_preboss_32_0:
    
    .dw cut_waitStd
      .dw 58
    
    ;=====
    ; 33
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 20
    
    .dw cut_loadSubs
      .db 33
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 252
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    
    .dw cut_bra,$777F
.ends

;=====
; 34-39
; target time: 1230 frames
;=====

.org $17C3
.bank $08 slot 3
.section "preboss cut mod 34 0" overwrite
  .dw cut_bra,cutmod_preboss_34_0
.ends

.bank $00 slot 2
.section "preboss cut mod 34 1" free
  cutmod_preboss_34_0:

    ;=====
    ; 34
    ;=====
    
    .dw cut_waitStd
      .dw 24
    
    .dw cut_loadSubs
      .db 34
    .dw cut_showSubs
    
;    .dw cut_waitStd
;      .dw 1229
;      .db $08
    
    .dw cut_waitStd
      .dw 83

    ;=====
    ; 35
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 106
    
    .dw cut_loadSubs
      .db 35
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 50

    ;=====
    ; 36
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 28
    
    .dw cut_loadSubs
      .db 36
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 249

    ;=====
    ; 37
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 37
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 266

    ;=====
    ; 38
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 39
    
    .dw cut_loadSubs
      .db 38
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 49

    ;=====
    ; 39
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 32
    
    .dw cut_loadSubs
      .db 39
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 267+10
    
    ; 1170
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 26
    
    
    .dw cut_bra,$77C8
.ends

;=====
; 40-41
; target time: 540 frames
;=====

.org $180C
.bank $08 slot 3
.section "preboss cut mod 40 0" overwrite
  .dw cut_bra,cutmod_preboss_40_0
.ends

.bank $00 slot 2
.section "preboss cut mod 40 1" free
  cutmod_preboss_40_0:
    ;=====
    ; 40
    ;=====
    
;    .dw cut_clearSubs
;    .dw cut_waitStd
;      .dw 32
;      .db $08
    
    .dw cut_loadSubs
      .db 40
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 201
    
    ;=====
    ; 41
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 35
    
    .dw cut_loadSubs
      .db 41
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 318
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    
    .dw cut_bra,$7811
.ends

/*.org $1831
.bank $08 slot 3
.section "preboss cut mod 40 2" overwrite
  .dw cut_bra,cutmod_preboss_40_1
.ends

.bank $00 slot 2
.section "preboss cut mod 40 3" free
  cutmod_preboss_40_1:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$28,$09
      ; dst
      .dw $1000
      ; size
      .dw $A000
    
    ;=====
    ; 42
    ;=====
    
    .dw cut_loadSubs
      .db 42
    .dw cut_showSubsDelayed
      .db 5
    
    .dw cut_bra,$783A
.ends */

;=====
; 42-45
; target time: 540 frames
;=====

.org $1831
.bank $08 slot 3
.section "preboss cut mod 42 0" overwrite
  .dw cut_bra,cutmod_preboss_42_0
.ends

.bank $00 slot 2
.section "preboss cut mod 42 1" free
  cutmod_preboss_42_0:
    ;=====
    ; 42
    ;=====
    
    .dw cut_loadSubs
      .db 42
    .dw cut_showSubsDelayed
      .db 6
    
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$28,$09
      ; dst
      .dw $1000
      ; size
      .dw $A000
      
    ; load patch tilemap
    .dw cut_acToVram
      ; src
      .db preboss_patch2MapOffsetLo
      .db preboss_patch2MapOffsetMid
      .db preboss_patch2MapOffsetHi
      ; dst
      .dw $0000
      ; size
      .dw preboss_patch2MapSize
    
    ; load patch graphics
    .dw cut_acToVram
      ; src
      .db preboss_patch2GrpOffsetLo
      .db preboss_patch2GrpOffsetMid
      .db preboss_patch2GrpOffsetHi
      ; dst
      .dw $7800
;      .dw $3400
      ; size
      .dw preboss_patch2GrpSize
    
    ; make up work
;    .dw cut_fadeIn
;      .db $01,$FF,$FF,$FF,$FF,$01
    
    .dw cut_bra,$783A
.ends

.org $18CC
.bank $08 slot 3
.section "preboss cut mod 42 2 0" overwrite
  .dw cut_bra,cutmod_preboss_42_0_0
.ends

.bank $00 slot 2
.section "preboss cut mod 42 2 1" free
  cutmod_preboss_42_0_0:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$28,$09
      ; dst
      .dw $1000
      ; size
      .dw $A000
      
    ; load patch tilemap
    .dw cut_acToVram
      ; src
      .db preboss_patch3MapOffsetLo
      .db preboss_patch3MapOffsetMid
      .db preboss_patch3MapOffsetHi
      ; dst
      .dw $0000
      ; size
      .dw preboss_patch3MapSize
    
    ; load patch graphics
    .dw cut_acToVram
      ; src
      .db preboss_patch3GrpOffsetLo
      .db preboss_patch3GrpOffsetMid
      .db preboss_patch3GrpOffsetHi
      ; dst
;      .dw $7800
      .dw $1000
      ; size
      .dw preboss_patch3GrpSize
    
    .dw cut_bra,$78D5
.ends

.org $185E
.bank $08 slot 3
.section "preboss cut mod 42 3" overwrite
  .dw cut_bra,cutmod_preboss_42_1
.ends

.bank $00 slot 2
.section "preboss cut mod 42 4" free
  cutmod_preboss_42_1:
    
    .dw cut_waitStd
      .dw 91
    
    ;=====
    ; 43
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 43
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 119
    
    ;=====
    ; 44
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 44
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 165
    
    ;=====
    ; 45
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 45
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 181+12
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$7863
.ends

;=====
; 46-48
; target time: 1290 frames
;=====

.org $18A7
.bank $08 slot 3
.section "preboss cut mod 46 0" overwrite
  .dw cut_bra,cutmod_preboss_46_0
.ends

.bank $00 slot 2
.section "preboss cut mod 46 1" free
  cutmod_preboss_46_0:
    ;=====
    ; 46
    ;=====
    
    .dw cut_waitStd
      .dw 113
    
    .dw cut_loadSubs
      .db 46
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 265
    
    ;=====
    ; 47
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 38
    
    .dw cut_loadSubs
      .db 47
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 547
    
    ;=====
    ; 48
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 64
    
    .dw cut_loadSubs
      .db 48
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 262
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
;    .dw cut_waitStd
;      .dw 1193
;      .db $08
    
    .dw cut_bra,$78AC
.ends

;=====
; 49-55
; target time: 1680 frames
;=====

; due to profligate and unnecessary use of sprite overlays,
; we run out of sprites during this scene.
; we've already replaced part of the overlay with background tiles
; in order to subvert the sprites-per-line limit,
; so we can just remove the sprites at the bottom part of the
; overlay entirely to give us space to work.

.bank $07 slot 3
.org $06B5
.section "preboss arle sprite overlay state 0" overwrite
  ; max number of sprites needed for this object
  lda #$2D-18
.ends

.bank $07 slot 3
.org $0826
.section "preboss arle sprite overlay state 1" overwrite
  ; number of sprites
  .db 44-18
  ; sprite data
  .dw $0050,$0090,$02B0,$0080
  .dw $0030,$0090,$02A8,$1080
  .dw $0070,$0090,$02B8,$0080
  .dw $0060,$0090,$02B4,$0080
  .dw $0070,$0070,$0298,$0180
  .dw $0050,$0070,$0290,$1180
  .dw $0010,$0070,$0284,$3180
  .dw $0070,$FFE2,$019A,$0080
  .dw $0070,$0050,$0278,$0182
  .dw $0070,$0030,$0258,$0180
  .dw $0070,$0010,$0238,$0180
  .dw $0070,$FFF0,$0218,$0181
  .dw $0050,$0050,$0270,$1180
  .dw $0050,$0030,$0250,$1180
  .dw $0050,$0010,$0230,$1180
  .dw $0050,$FFF0,$0210,$1180
  .dw $0010,$0050,$0260,$3180
  .dw $0010,$0030,$0240,$3180
  .dw $0010,$0010,$0220,$3180
  .dw $0080,$FFD0,$019C,$0180
  .dw $0080,$0090,$02BC,$0082
;  .dw $0090,$0090,$02E0,$1082
;  .dw $00D0,$0090,$02F0,$1082
;  .dw $00D0,$0070,$02D0,$1182
  .dw $0080,$0070,$029C,$0182
;  .dw $0090,$0070,$02C0,$3182
;  .dw $00B0,$FFE0,$01DA,$0080
;  .dw $0090,$FFD0,$01B8,$1180
;  .dw $00D0,$0050,$01F0,$1182
;  .dw $00D0,$0030,$01D0,$1182
;  .dw $00D0,$0010,$01B0,$1182
;  .dw $00D0,$FFF0,$0190,$1182
;  .dw $00B0,$0010,$01A8,$1182
;  .dw $00B0,$FFF0,$0188,$1182
;  .dw $00A0,$0010,$01A4,$0182
;  .dw $00A0,$FFF0,$0184,$0182
;  .dw $0090,$0050,$01E0,$3182
;  .dw $0090,$0030,$01C0,$3182
;  .dw $0090,$0010,$01A0,$0182
;  .dw $0090,$FFF0,$0180,$0181
  .dw $0080,$0030,$025C,$0182
  .dw $0080,$0050,$027C,$0182
  .dw $0080,$0010,$023C,$0180
  .dw $0080,$FFF0,$021C,$0181
.ends

.bank $07 slot 3
.org $0987
.section "preboss arle sprite overlay state 2" overwrite
  ; number of sprites
  .db 45-18
  ; sprite data
  .dw $0068,$0030,$0204,$0180
  .dw $0050,$0090,$02B0,$0080
  .dw $0030,$0090,$02A8,$1080
  .dw $0070,$0090,$02B8,$0080
  .dw $0060,$0090,$02B4,$0080
  .dw $0070,$0070,$0298,$0180
  .dw $0050,$0070,$0290,$1180
  .dw $0010,$0070,$0284,$3180
  .dw $0070,$FFE2,$019A,$0080
  .dw $0070,$0050,$0278,$0182
  .dw $0070,$0030,$0258,$0180
  .dw $0070,$0010,$0238,$0180
  .dw $0070,$FFF0,$0218,$0181
  .dw $0050,$0050,$0270,$1180
  .dw $0050,$0030,$0250,$1180
  .dw $0050,$0010,$0230,$1180
  .dw $0050,$FFF0,$0210,$1180
  .dw $0010,$0050,$0260,$3180
  .dw $0010,$0030,$0240,$3180
  .dw $0010,$0010,$0220,$3180
  .dw $0080,$FFD0,$019C,$0180
  .dw $0080,$0090,$02BC,$0082
;  .dw $0090,$0090,$02E0,$1082
;  .dw $00D0,$0090,$02F0,$1082
;  .dw $00D0,$0070,$02D0,$1182
  .dw $0080,$0070,$029C,$0182
;  .dw $0090,$0070,$02C0,$3182
;  .dw $00B0,$FFE0,$01DA,$0080
;  .dw $0090,$FFD0,$01B8,$1180
;  .dw $00D0,$0050,$01F0,$1182
;  .dw $00D0,$0030,$01D0,$1182
;  .dw $00D0,$0010,$01B0,$1182
;  .dw $00D0,$FFF0,$0190,$1182
;  .dw $00B0,$0010,$01A8,$1182
;  .dw $00B0,$FFF0,$0188,$1182
;  .dw $00A0,$0010,$01A4,$0182
;  .dw $00A0,$FFF0,$0184,$0182
;  .dw $0090,$0050,$01E0,$3182
;  .dw $0090,$0030,$01C0,$3182
;  .dw $0090,$0010,$01A0,$0182
;  .dw $0090,$FFF0,$0180,$0181
  .dw $0080,$0030,$025C,$0182
  .dw $0080,$0050,$027C,$0182
  .dw $0080,$0010,$023C,$0180
  .dw $0080,$FFF0,$021C,$0181
.ends

.bank $07 slot 3
.org $0AF0
.section "preboss arle sprite overlay state 3" overwrite
  ; number of sprites
  .db 45-18
  ; sprite data
  .dw $0068,$0030,$0200,$0180
  .dw $0050,$0090,$02B0,$0080
  .dw $0030,$0090,$02A8,$1080
  .dw $0070,$0090,$02B8,$0080
  .dw $0060,$0090,$02B4,$0080
  .dw $0070,$0070,$0298,$0180
  .dw $0050,$0070,$0290,$1180
  .dw $0010,$0070,$0284,$3180
  .dw $0070,$FFE2,$019A,$0080
  .dw $0070,$0050,$0278,$0182
  .dw $0070,$0030,$0258,$0180
  .dw $0070,$0010,$0238,$0180
  .dw $0070,$FFF0,$0218,$0181
  .dw $0050,$0050,$0270,$1180
  .dw $0050,$0030,$0250,$1180
  .dw $0050,$0010,$0230,$1180
  .dw $0050,$FFF0,$0210,$1180
  .dw $0010,$0050,$0260,$3180
  .dw $0010,$0030,$0240,$3180
  .dw $0010,$0010,$0220,$3180
  .dw $0080,$FFD0,$019C,$0180
  .dw $0080,$0090,$02BC,$0082
;  .dw $0090,$0090,$02E0,$1082
;  .dw $00D0,$0090,$02F0,$1082
;  .dw $00D0,$0070,$02D0,$1182
  .dw $0080,$0070,$029C,$0182
;  .dw $0090,$0070,$02C0,$3182
;  .dw $00B0,$FFE0,$01DA,$0080
;  .dw $0090,$FFD0,$01B8,$1180
;  .dw $00D0,$0050,$01F0,$1182
;  .dw $00D0,$0030,$01D0,$1182
;  .dw $00D0,$0010,$01B0,$1182
;  .dw $00D0,$FFF0,$0190,$1182
;  .dw $00B0,$0010,$01A8,$1182
;  .dw $00B0,$FFF0,$0188,$1182
;  .dw $00A0,$0010,$01A4,$0182
;  .dw $00A0,$FFF0,$0184,$0182
;  .dw $0090,$0050,$01E0,$3182
;  .dw $0090,$0030,$01C0,$3182
;  .dw $0090,$0010,$01A0,$0182
;  .dw $0090,$FFF0,$0180,$0181
  .dw $0080,$0030,$025C,$0182
  .dw $0080,$0050,$027C,$0182
  .dw $0080,$0010,$023C,$0180
  .dw $0080,$FFF0,$021C,$0181
.ends

.bank $08 slot 3
.org $18F9
.section "preboss cut mod 49 0" overwrite
  .dw cut_bra,cutmod_preboss_49_0
.ends

.bank $00 slot 2
.section "preboss cut mod 49 1" free
  cutmod_preboss_49_0:
    ;=====
    ; 49
    ;=====
    
    .dw cut_waitStd
      .dw 15
    
    .dw cut_loadSubs
      .db 49
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 121
    
    ;=====
    ; 50
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 56
    
    .dw cut_loadSubs
      .db 50
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 232
    
    ;=====
    ; 51
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 51
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 220
    
    ;=====
    ; 52
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 58
    
    .dw cut_loadSubs
      .db 52
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 101
    
    ;=====
    ; 53
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 45
    
    .dw cut_loadSubs
      .db 53
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 132
    
    ;=====
    ; 54
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 54
    
    .dw cut_loadSubs
      .db 54
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 139
    
    ;=====
    ; 55
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 67
    
    .dw cut_loadSubs
      .db 55
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 296
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 143
    
    
    ; 1680
    .dw cut_bra,$78FE
.ends

;===============================================
; ending
;===============================================

;=====
; 00-01
; target time: 180 frames
;=====

.bank $08 slot 3
.org $19D4
.section "ending cut mod 00 0" overwrite
  .dw cut_bra,cutmod_ending_00
.ends

.bank $00 slot 2
.section "ending cut mod 00 1" free
  cutmod_ending_00:
    ; set up for ending
    .dw cut_setUpScene
      .db 2
    
    ;=====
    ; 00
    ;=====
    
    .dw cut_waitStd
      .dw 5
    
    .dw cut_loadSubs
      .db 0
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 82
    
    ;=====
    ; 01
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 15
    
    .dw cut_loadSubs
      .db 1
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 77
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$79D9
.ends

;=====
; 02-05
; target time: 1140 frames
;=====

.bank $08 slot 3
.org $19F9
.section "ending cut mod 02 2" overwrite
  .dw cut_bra,cutmod_ending_02_2
.ends

.bank $00 slot 2
.section "ending cut mod 02 3" free
  cutmod_ending_02_2:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$B0,$02
      ; dst
      .dw $5000
      ; size
      .dw $6000
      
    ; load patch tilemap
    .dw cut_acToVram
      ; src
      .db ending_patch0MapOffsetLo
      .db ending_patch0MapOffsetMid
      .db ending_patch0MapOffsetHi
      ; dst
      .dw $0000
      ; size
      .dw ending_patch0MapSize
    
    ; load patch graphics
    .dw cut_acToVram
      ; src
      .db ending_patch0GrpOffsetLo
      .db ending_patch0GrpOffsetMid
      .db ending_patch0GrpOffsetHi
      ; dst
      .dw $4400
      ; size
      .dw ending_patch0GrpSize
    
    .dw cut_bra,$7A02
.ends

.bank $08 slot 3
.org $1A1D
.section "ending cut mod 02 0" overwrite
  .dw cut_bra,cutmod_ending_02
.ends

.bank $00 slot 2
.section "ending cut mod 02 1" free
  cutmod_ending_02:
    ;=====
    ; 02
    ;=====
    
    .dw cut_waitStd
      .dw 140
    
    .dw cut_loadSubs
      .db 2
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 325
    
    ;=====
    ; 03
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 55
    
    .dw cut_loadSubs
      .db 3
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 287
    
    ;=====
    ; 04
    ;=====
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 70
    
    .dw cut_loadSubs
      .db 4
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 87
    
    ;=====
    ; 05
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 5
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 169-1
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_bra,$7A22
.ends

;=====
; 06-08
; target time: 240 frames
;=====

.bank $08 slot 3
.org $1A6C
.section "ending cut mod 06 0" overwrite
  .dw cut_bra,cutmod_ending_06
.ends

.bank $00 slot 2
.section "ending cut mod 06 1" free
  cutmod_ending_06:
    ;=====
    ; 06
    ;=====
    
;    .dw cut_waitStd
;      .dw 140
;      .db $08
    
    .dw cut_loadSubs
      .db 6
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 99
    
    ;=====
    ; 07
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 7
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 63
    
    ;=====
    ; 08
    ;=====
    
    .dw cut_clearSubs
    .dw cut_wait1FrameStd
    
    .dw cut_loadSubs
      .db 8
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 72
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 4
    
    .dw cut_bra,$7A71
.ends

;=====
; 09
; target time: 300 frames
;=====

.bank $08 slot 3
.org $1ABF
.section "ending cut mod 09 0" overwrite
  .dw cut_bra,cutmod_ending_09
.ends

.bank $08 slot 3
.section "ending cut mod 09 1" free
  cutmod_ending_09:
    ;=====
    ; 09
    ;=====
    
    .dw cut_waitStd
      .dw 30
    
    .dw cut_loadSubs
      .db 9
    .dw cut_showSubs
    
    .dw cut_waitStd
      .dw 150
    
    .dw cut_clearSubs
    .dw cut_waitStd
      .dw 150
    
    .dw cut_bra,$7AC4
.ends

;===============================================
; credits
;===============================================

.define newCreditsLoadDst $9000
.define loadCreditsBanks $6FF3

.bank $07 slot 3
.org $0F8E
.section "credits load 1" overwrite
  jsr loadCredits
  jmp $6F96
.ends

.bank $07 slot 3
.section "credits load 2" free
  loadCredits:
    ; load slots
    jsr loadCreditsBanks
  
    lda #ending_creditsDataOffsetLo
    sta $1A02.w
    lda #ending_creditsDataOffsetMid
    sta $1A03.w
    lda #ending_creditsDataOffsetHi
    sta $1A04.w
    ; zero offset register
    stz $1A05.w
    stz $1A06.w
    
    ; dstaddr
    lda #<newCreditsLoadDst
    sta @transferCommand+3.w
    lda #>newCreditsLoadDst
    sta @transferCommand+4.w
    
    ; size
    lda #<ending_creditsDataSize
    sta @transferCommand+5.w
    lda #>ending_creditsDataSize
    sta @transferCommand+6.w
    
    ; do transfer
    @transferCommand:
    tai $1A00,$0000,$0000
    
    ; make up work: set credits srcptr
    lda #<newCreditsLoadDst
    sta $D9
    lda #>newCreditsLoadDst
    sta $DA
    
    rts
.ends

; extra delay at end of credits

.bank $08 slot 3
.org $1C1F
.section "ending credits mod 0" overwrite
  .dw cut_bra,cutmod_credits_0
.ends

.bank $08 slot 3
.section "ending credits mod 1" free
  cutmod_credits_0:
    ; delay
    .dw cut_setTimerAndWait
      .dw $100+60
      .db $00
    
    ; make up work
    .dw cut_fadeOut
      .db $08,$FF,$FF,$00,$00,$01
    
    .dw cut_bra,$7C27
.ends

;===============================================
; title screen sprite overlay
;===============================================

.define numSubtitleOverlaySprites 30

.bank $03 slot 3
.org $045E
.section "subtitle sprite overlay 1" overwrite
  ; big-endian pointer to sprite layout src
  .db >subtitleSpriteOverlaySprites
  .db <subtitleSpriteOverlaySprites
.ends

.bank $03 slot 3
.org $02C7
.section "subtitle sprite overlay 2" overwrite
  ; number of sprite slots to reserve
;  lda #$04
  lda #numSubtitleOverlaySprites
.ends

.bank $03 slot 3
.org $042D
.section "subtitle sprite overlay 3" overwrite
  ; ?
  ; number of slots...
;  lda #$04
  lda #numSubtitleOverlaySprites
.ends

.bank $03 slot 3
.org $0300
.section "subtitle sprite overlay 4" overwrite
  ; number of slots when cleaning up
;  lda #$04
  lda #numSubtitleOverlaySprites
.ends

.bank $03 slot 3
.section "subtitle sprite overlay 5" free
  subtitleSpriteOverlaySprites:
    .incbin "out/grp/title_overlay_sprites.bin"
.ends

.bank $03 slot 3
.org $045A
.section "subtitle sprite overlay 6" overwrite
  ; x/y position
  .dw $0080-64
  .dw $0098+8
.ends

;=====
; script updates
;=====

.bank $08 slot 3
.org $116A
.section "subtitle sprite overlay script mod 0" overwrite
  .dw cut_bra,cutmod_subtitle_0
.ends

.bank $08 slot 3
.section "subtitle sprite overlay script mod 1" free
  cutmod_subtitle_0:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$60,$00
      ; dst
      .dw $4000
      ; size
      .dw $1800
    
    ; load new graphics
    .dw cut_acToVram
      ; src
      .db intro_subtitleOverlayGrpOffsetLo
      .db intro_subtitleOverlayGrpOffsetMid
      .db intro_subtitleOverlayGrpOffsetHi
      ; dst
      .dw $5000
      ; size
      .dw intro_subtitleOverlayGrpSize
    
    .dw cut_bra,$7173
.ends

.bank $08 slot 3
.org $099C
.section "subtitle sprite overlay script mod 2" overwrite
  .dw cut_bra,cutmod_subtitle_1
.ends

.bank $08 slot 3
.section "subtitle sprite overlay script mod 3" free
  cutmod_subtitle_1:
    ; make up work
    .dw cut_acToVram
      ; src
      .db $01,$60,$00
      ; dst
      .dw $4000
      ; size
      .dw $1800
    
    ; load new graphics
    .dw cut_acToVram
      ; src
      .db intro_subtitleOverlayGrpOffsetLo
      .db intro_subtitleOverlayGrpOffsetMid
      .db intro_subtitleOverlayGrpOffsetHi
      ; dst
      .dw $5000
      ; size
      .dw intro_subtitleOverlayGrpSize
    
    .dw cut_bra,$69A5
.ends

