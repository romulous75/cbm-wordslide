.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

.include "cbm_kernal.inc"

load_text:
.byte "loading...",0

screen_text:
.byte $92,$93,$8E,$05,$0D," word slide!",$0D,$0D
.byte " ",$B0,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$B2,$C3,$AE,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$DB,$C3,$B3,$0D
.byte " ",$C2," ",$C2," ",$C2," ",$C2," ",$C2," ",$C2,$0D
.byte " ",$AD,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$B1,$C3,$BD,$0D,$0D
.byte " guess the word ",$0D,$0D
.byte " ",$B0,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$AE,$0D
.byte " ",$C2,"qwertyuiop",$C2,$0D
.byte " ",$C2,"asdfghjkl ",$C2,$0D
.byte " ",$C2," zxcvbnm  ",$C2,$0D
.byte " ",$AD,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$C3,$BD,0

answer:
.res 5

letter_status:
.res 26

filename:
.byte "words.bin"
end_filename:
FILENAME_LENGTH = end_filename - filename

WORD_TABLE = $6000

LUT_SIZE = 26*26*2

word_table_size:
.res 2

remainder:
.res 1

random_seed:
.res 2

start:
   ldx #0
@load_loop:
   lda load_text,x
   beq @load
   jsr CHROUT
   inx
   jmp @load_loop
@load:
   ; set background to black
.if .def(__CX16__)
   lda #$90    ; foreground = black
   jsr CHROUT
   lda #$01    ; swap background/foreground
   jsr CHROUT
   lda #64     ; half-resolution
   sta $9F2A   ; VERA H-Scale
   sta $9F2B   ; VERA V-Scale
.elseif .def(__C64__)
   lda #0      ; black
   sta $D021   ; background color VIC-II register
.elseif .def(__VIC20__)
   lda #0      ; black background and border
   sta $900F   ; background/border color VIC register
.endif
   ; seed random number generator
.if .def (__CX16__)
   jsr $FECF ; entropy_get
   stx random_seed
   sty random_seed+1
   eor random_seed
   sta random_seed
   txa
   eor random_seed+1
   sta random_seed+1
.elseif .def(__C64__)
   ; use SID
   lda #$FF  ; maximum frequency value
   sta $D40E ; voice 3 frequency low byte
   sta $D40F ; voice 3 frequency high byte
   lda #$80  ; noise waveform, gate bit off
   sta $D412 ; voice 3 control register
.elseif .def(__VIC20__)
   ; TBD
.endif
   ; load word table from disk
   lda #1
   ldx #8
   ldy #0
   jsr SETLFS
   lda #FILENAME_LENGTH
   ldx #<filename
   ldy #>filename
   jsr SETNAM
   lda #0
   ldx #<WORD_TABLE
   ldy #>WORD_TABLE
   jsr LOAD
   sec
   txa
   sbc #<WORD_TABLE
   sta word_table_size
   tya
   sbc #>WORD_TABLE
   sta word_table_size+1
   lda word_table_size
   sbc #<LUT_SIZE
   sta word_table_size
   lda word_table_size+1
   sbc #>LUT_SIZE
   sta word_table_size+1
   ; divide by 5 to get word count
   lda #0
   sta remainder
   ldx #16
@div5_loop:
   asl word_table_size
   rol word_table_size+1
   rol remainder
   sec
   sbc #5
   bcc @next_bit
   inc word_table_size
@next_bit:
   dex
   bne @div5_loop
   ; display initial screen text
   ldx #0
@init_loop:
   lda screen_text,x
   jsr CHROUT
   inx
   bne @init_loop       ; keep looping until X = 0
@init_page2:
   lda screen_text+$100,x
   beq @init_loop_done  ; break out of loop at null terminator
   jsr CHROUT
   inx
   jmp @init_page2
@init_loop_done:
   ; randomly select a word
.if .def (__CX16__)
   jsr $FECF ; entropy_get
   pha
   eor random_seed
   stx random_seed
   eor random_seed
   sta random_seed
   pla
   eor random_seed+1
   sta random_seed+1
   tya
.elseif .def(__C64__)
   ; use SID
   lda #D41B
   
.elseif .def(__VIC20__)
   ; TBD
.endif



   rts