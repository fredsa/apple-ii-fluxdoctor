; --------------------------------------------------
; FLUXDOCTOR V1.2
; Copyright Fred Sauer 2026
; See LICENSE.txt
;
; Apple Disk II diagnostic utility for real-time
; troubleshooting, diagnositcs, and repair.
; --------------------------------------------------
            processor 6502
            org  1

; --------------------------------------------------
; Desired start of program execution
; --------------------------------------------------
pgmstart    equ  $2000
PGM_LENGTH  equ  PGM_END - pgmstart

            seg
            org  pgmstart - 4 ; Subtract 4 bytes for header


; --------------------------------------------------
; DOS 3.3 binary header (4 bytes)
; --------------------------------------------------
            word pgmstart ; Program start address in memory (2 bytes)
            word PGM_LENGTH ; Program length (2 bytes), must be file size - 4


; --------------------------------------------------
; ROM address use
; --------------------------------------------------
CH          equ  $24
CV          equ  $25


; --------------------------------------------------
; Scratch space
; --------------------------------------------------
; $06-$09 - Free Space
EXIT_FLAG   equ  $06
DATA_CHECKSUM equ $07
RUNNING     equ  $08

; $1D-$1E - Free Space

; $CE-$CF - Free Space

; $D7     - Free Space
TEMP1       equ  $D7

; $E3     - Free Space
SPINNER     equ  $E3

; $EB-$EF - Free Space
SAVEX       equ  $EB
PTRL        equ  $EC
PTRH        equ  $ED

; $FA-$FE - Free Space
FOUND_HDR   equ  $FA  ; $FA-FD 4 bytes
FOUND_CHECKSUM equ FOUND_HDR
FOUND_SECTOR equ FOUND_HDR+1
FOUND_TRACK equ  FOUND_HDR+2
FOUND_VOLUME equ FOUND_HDR+3
CALC_CHKSUM equ  $FE

; $0200 - $02FF - GETLN Line Input Buffer

; $0300 - $03CF - Free Space for Machine Language, Shape Table, etc.

; $0400 - $07FF - Text Video Page and Peripheral Screenholes

; $0800 - $0BFF - Text Video Page 2 or Applesoft Program and Variables

; $0C00 - $1FFF - Free Space for Machine Language, Shapes, etc.
DISK_BUFFER equ  $0c00 ; $c00-$cff 256 bytes
MAP_6AND2   equ  $0d00 ; $d00-$dff 256 bytes

; $2000 - $3FFF -  High Resolution Graphics Page 1

; $4000 - $5FFF -  High Resolution Graphics Page 2

; $6000 - $95FF -  Applesoft String Data

; --------------------------------------------------
; ROM routines
; --------------------------------------------------
BELLB       equ  $FBE2
VTAB        equ  $FC22
HOME        equ  $FC58
WAIT        equ  $FCA8
COUT        equ  $FDED
CROUT       equ  $FD8E

; --------------------------------------------------
; DOS routines
; --------------------------------------------------
;RWTS        equ  $3D9

; --------------------------------------------------
; DOS data
; --------------------------------------------------
DRIVNO      equ  $35
DRV1TRK     equ  $478
DRV2TRK     equ  $4F8

; --------------------------------------------------
; IOB table
; --------------------------------------------------
IOB
DISK_IOB    equ  $B7E8 ; IOB type indicator, must be $01
;;;IBTYPE DFB 1 ; IOB TYPE CODE

DISK_SLOT   equ  $B7E9 ; Slot << 4
;;;IBSLOT DFB 6*16 ; CONTROLLER SLOT NO.

DISK_DRIVE  equ  $B7EA
;;;IBDRVN DFB 1 ; DRIVE NUMBER

DISK_VOL    equ  $B7EB ; Volume $01 - $FE, $00 = any
;;;IBVOL DFB $00 ; VOLUME NUMBER

DISK_TRACK  equ  $B7EC
;;;IBTRK DFB 0 ; TRACK NUMBER

DISK_SECTOR equ  $B7ED
;;;IBSECT DFB 0 ; SECTOR NUMBER

;                $B7EE ; Low-order byte of device characteristic table (DCT)
;                $B7EF ; High-order byte of DCT
;;;IBDCTP DW DCT

DISK_BUFFPTR equ $B7F0 ; data buffer pointer
;                $B7F1
;;;IBBUFP DW 0 ; POINTER TO BUFFER

;                $B7F2 ; data length
;                $B7F3 ;
;;;IBDLEN DW 256 ; DATA LENGTH

DISK_CMD    equ  $B7F4 ; disk command
;;;IBCMD DFB 0 ; COMMAND

DISK_ERR    equ  $B7F5 ; status error code (or last byte of bufer read in)
;;;IBSTAT DFB 0 ; STATUS

;                $B7F6 ; actual volume (or status modifier?)
;;;IBSMOD DFB 0 ; STATUS MODIFIER BYTE

OSLOT       equ  $B7F7 ; prev slot << 4
;;;IBPSLT DFB 6*16 ; PREVIOUS SLOT

ODRIV       equ  $B7F8 ; prev drive
;;;IBPDRV DFB 1 ; PREVIOUS DRIVE


;;;IBSPAR DS 2,0 ; IOB SPARES
;;;DCT DFB 0,1,$EF,$D8
;;;DS 1,0 ;FILL IN 3700 PAGE

DISK_CMD_SEEK equ $00
;;;IBCNUL EQU 0 ; 0-NULL COMMAND

DISK_CMD_READ equ $01
;;;IBCRTS EQU 1 ; 1-READ TRACK, SECTOR

DISK_CMD_WRITE equ $02
;;;IBCWTS EQU 2 ; 2-WRITE TRACK, SECTOR

DISK_CMD_FORMAT equ $04
;;;IBFMT EQU 4 ; 4-FORMAT DISK

DISK_CMD_WRITE_BOOT equ $08
;;;IBBOOT EQU 8 ; 8-WRITE BOOT


DISK_ERR_NONE equ $00 ; no errors

DISK_ERR_INIT equ $08 ; error during initialization

DISK_ERR_WP equ  $10  ; write protect error
;;;IBWPER EQU $10 ; WRITE PROTECT ERROR

DISK_ERR_VOL equ $20  ; volume mismatch error
;;;IBVMME EQU $20 ; VOLUME MISMATCH

DISK_ERR_DRIVE equ $40 ; drive error
;;;IBDERR EQU $40 ; DRIVE ERR

DISK_ERR_READ equ $80 ; read error (obsolete)
;;;IBRERR EQU $80 ; READ ERR

; --------------------------------------------------
; Device characteristics table
; --------------------------------------------------
; Offset 00  Device type: $OO = Disk II
; Offset 01  Phases per track: $01 = DISK II
; Offset 02  Motor on time count: $EFD8 = DISK II

; --------------------------------------------------
; Hardware registers
; --------------------------------------------------
KBD         equ  $C000
KBDSTRB     equ  $C010
PHASEOFF    equ  $C080 ; Stepper motor phase 0 off
PHASEON     equ  $C081 ; Stepper motor phase 0 on
PHASE1OFF   equ  $C082 ; Stepper motor phase 1 off
PHASElON    equ  $C083 ; Stepper motor phase I on
PHASE2OFF   equ  $C084 ; Stepper motor phase 2 off
PHASE2ON    equ  $C085 ; Stepper notor phase 2 on
PHASE3OFF   equ  $C086 ; Stepper motor phase 3 off
PHASE3ON    equ  $C087 ; Stepper motor phase 3 on
MOTOROFF    equ  $C088 ; Turn motor off
MOTORON     equ  $C089 ; Turn motor on
DRV0EN      equ  $C08A ; Drive 0 select
DRV1EN      equ  $C08B ; Drive 1 select
Q6L         equ  $C08C ; READ data latch
Q6H         equ  $C08D ; WRITE data latch; read write protect state
Q7L         equ  $C08E ; Set READ mode
Q7H         equ  $C08F ; Set WRITE mode
; Q7L Q6L = Read data
; Q7H Q6L = Write data
; Q7L Q6H = Sense Write Protect
; Q7H Q6H = Load Write Latch

; --------------------------------------------------
; Low level disk layout
; --------------------------------------------------
; Address field: D5 AA 96 {2:VOL} {2:TRACK} {2:SECT} {2:CHKSUM} DE AA EB
; Data field   : D5 AA AD {342:DATA}                 {2:CHKSUM} DE AA EB
PROLOGUE_0  equ  $D5
PROLOGUE_1  equ  $AA
PROLOGUE_2_ADDR equ $96
PROLOGUE_2_DATA equ $AD
EPILOGUE_0  equ  $DE
EPILOGUE_1  equ  $AA
EPILOGUE_2  equ  $EB

; --------------------------------------------------
; Keyboard scan codes
; --------------------------------------------------
KBD_LEFT    equ  $08
KBD_RIGHT   equ  $15

; --------------------------------------------------
; Codes
; --------------------------------------------------
ERR_CODE_SEEK equ 'S & $3f
ERR_CODE_MISSING equ 'M & $3f
ERR_CODE_CHECKSUM equ 'K & $3f
ERR_CODE_EPILOGUE equ 'E & $3f
CODE_Y      equ  'Y & $3f
CODE_N      equ  'N & $3f

; --------------------------------------------------
; Memory start addresses rows 0-23
; --------------------------------------------------
text_row_00 equ  $400
text_row_01 equ  $480
text_row_02 equ  $500
text_row_03 equ  $580
text_row_04 equ  $600
text_row_05 equ  $680
text_row_06 equ  $700
text_row_07 equ  $780
text_row_08 equ  $428
text_row_09 equ  $4a8
text_row_0a equ  $528
text_row_0b equ  $5a8
text_row_0c equ  $628
text_row_0d equ  $6a8
text_row_0e equ  $728
text_row_0f equ  $7a8
text_row_10 equ  $450
text_row_11 equ  $4d0
text_row_12 equ  $550
text_row_13 equ  $5d0
text_row_14 equ  $650
text_row_15 equ  $6d0
text_row_16 equ  $750
text_row_17 equ  $7d0

; --------------------------------------------------
; Macros
; --------------------------------------------------
            mac  print
.strname    equ  {1}
            lda  #<.strname
            sta  PTRL
            lda  #>.strname
            sta  PTRH
            ldy  #$ff
.next       iny
            lda  (PTRL),y
            beq  .done
            ora  #$80
            jsr  COUT
            jmp  .next
.done
            endm

            mac  printmessage
.addr       equ  {1}
            lda  .addr
            sta  CV
            jsr  VTAB
            lda  .addr+1
            sta  CH
            ldy  #$ff
.next       iny
            lda  .addr+2,y
            beq  .done
            ora  #$80
            jsr  COUT
            jmp  .next
.done
            endm

            mac  printmessageinv
.addr       equ  {1}
            lda  .addr
            sta  CV
            jsr  VTAB
            lda  .addr+1
            sta  CH
            ldy  #$ff
.next       iny
            lda  .addr+2,y
            beq  .done
            and  #$3f
            jsr  COUT
            jmp  .next
.done
            endm

            mac  readbyte
.readbyte   lda  Q6L,x ; read byte
            bpl  .readbyte
            endm

            mac  readbyte_y
.readbyte   ldy  Q6L,x ; read byte
            bpl  .readbyte
            endm

            mac  renderhex
.val        equ  {1}
.addr       equ  {2}
            lda  .val
            clc
            ror
            ror
            ror
            ror
            and  #$0f
            tay
            lda  hexchars,y
            and  #$3f
            sta  .addr

            lda  .val
            and  #$0f
            tay
            lda  hexchars,y
            and  #$3f
            sta  .addr+1
            endm


; --------------------------------------------------
; Start of program
; --------------------------------------------------
pgmstart
            ; --------------------------------------------------
            ; Clear exit flag
            ; --------------------------------------------------
            lda  #$00
            sta  EXIT_FLAG

            ; --------------------------------------------------
            ; Clear screen
            ; --------------------------------------------------
            jsr  HOME


            ; --------------------------------------------------
            ; Determine last slot / drive
            ; --------------------------------------------------
;             lda  $BF00 ; ProDOS springboard
;             cmp  #$4C ; JMP?
;             bne  notprodos
;             lda  $BF03 ; ProDOS springboard
;             cmp  #$4C ; JMP?
;             bne  notprodos
;             lda  $BF30 ; ProDOS DEVNUM
;             and  #$70
;             sta  DISK_SLOT
;             lda  #$01 ; Drive 1
;             bit  $BF30 ; ProDOS DEVNUM
;             bpl  prodosdrive
;             lda  #$02 ; Drive 2
; prodosdrive sta  DISK_DRIVE
;             jmp  endprevdevice
; notprodos

            ; DOS 3.3 relocation with different amounts of RAM
            ; 48KB  $03D0: JMP 9DBF; JMP 9D84; $AA6A=06 $AA68=01
            ; 32KB  $03D0: JMP 5DBF; JMP 5D84; $6A6A=06 $6A68=01
            ; 16KB  $03D0: JMP 1DBF; JMP 1D84; $2A6A=06 $2A68=01
            lda  $03D2 ; DOS 3.3 $03D0 JMP $9Dxx
            and  #$0f
            cmp  #$0d ; 9D/5D/1D
            bne  notdos33
            lda  $03D5 ; DOS 3.3 $03D3 JMP $9Dxx
            and  #$0f
            cmp  #$0d ; 9D/5D/1D
            bne  notdos33
            lda  $03D2 ; DOS 3.3 $03D0 JMP $9Dxx
            and  #$f0 ; 9D/5D/1D -> 90/50/10
            ora  #$0a ; 90/50/10 -> 9A/5A/1A
            clc
            adc  #$10 ; 9A/5A/1A -> AA/6A/2A
            sta  PTRH
            lda  #$00
            sta  PTRL
            ldy  #$6a
            lda  (PTRL),y
            asl
            asl
            asl
            asl
            sta  DISK_SLOT
            ldy  #$68
            lda  (PTRL),y
            sta  DISK_DRIVE
            jmp  endprevdevice


notdos33
            ; Default to slot 6, drive 1
            lda  #$60
            sta  DISK_SLOT
            lda  #$01
            sta  DISK_DRIVE

endprevdevice

            ; --------------------------------------------------
            ; Determine previous track
            ; --------------------------------------------------
            jsr  setdisktrack


            ; --------------------------------------------------
            ; Prep 6 and 2 GCR map
            ; --------------------------------------------------
            ldy  #$00
            lda  #$ff ; fill with $ff to denote invalid values
prepmap1    sta  MAP_6AND2,y
            dey
            bne  prepmap1

            ldy  #$3f
prepmap2    lda  dos33_6and2,y
            tax
            tya
            sta  MAP_6AND2,x ; populate reverse map
            dey
            bpl  prepmap2


            ; --------------------------------------------------
            ; Init IOB
            ; --------------------------------------------------
            lda  #$01
            sta  DISK_IOB

            lda  #$00 ; Any volume
            sta  DISK_VOL


            ; --------------------------------------------------
            ; Boilerplate text
            ; --------------------------------------------------
            jsr  resetscreen
            printmessage M_INSTRUCTIONS
            printmessageinv M_TITLE
            printmessage M_COPYRIGHT
            printmessage M_GITHUB
            lda  #ERR_CODE_SEEK
            sta  ERR_CODE_SEEK_ADDR
            lda  #ERR_CODE_MISSING
            sta  ERR_CODE_MISSING_ADDR
            lda  #ERR_CODE_CHECKSUM
            sta  ERR_CODE_CHECKSUM_ADDR
            lda  #ERR_CODE_EPILOGUE
            sta  ERR_CODE_EPILOGUE_ADDR



            ; --------------------------------------------------
            ; Prepare for disk access
            ; --------------------------------------------------
            ldx  DISK_SLOT ; restore X
            lda  DISK_DRIVE
            cmp  #1
            beq  initdrive0
            lda  DRV1EN,X
            jmp  initseek
initdrive0
            LDA  DRV0EN,x
initseek    jsr  seek

            lda  Q7L,x ; read mode

; --------------------------------------------------
; Free wheeling
; --------------------------------------------------
freewheelloop

            ; --------------------------------------------------
            ; Exit?
            ; --------------------------------------------------
            lda  EXIT_FLAG
            beq  noexit
            ldx  DISK_SLOT ; restore X
            lda  MOTOROFF,x ; motor off
            lda  #CODE_N
            sta  RUNNING
            jsr  HOME
            printmessage M_BYE
            rts
noexit

            ; --------------------------------------------------
            ; Spinner
            ; --------------------------------------------------
            inc  SPINNER
            lda  SPINNER
            and  #%11
            sta  SPINNER
            tax
            lda  spinnerchars,x
            sta  SPINNER_ADDR

            ; --------------------------------------------------
            ; Handle key press
            ; --------------------------------------------------
            lda  KBD
            bmi  checkkeys
            jmp  nokey
checkkeys   sta  KBDSTRB
            and  #$7f
            cmp  #'a
            bcc  nokeycase
            cmp  #'z+1
            bcs  nokeycase
            eor  #$20
nokeycase

            cmp  #KBD_LEFT
            bne  noleft
            lda  DISK_TRACK
            cmp  #0   ;lowest track
            beq  noleft
            dec  DISK_TRACK
            jsr  seek
            jmp  nokey
noleft

            cmp  #KBD_RIGHT
            bne  noright
            lda  DISK_TRACK
            cmp  #34  ; highest track
            beq  noright
            inc  DISK_TRACK
            jsr  seek
            jmp  nokey
noright

            cmp  #'0
            bne  nozero
            lda  DISK_TRACK
            cmp  #0
            beq  nozero
            lda  #0
            sta  DISK_TRACK
            jsr  seek
            jmp  nokey
nozero

            cmp  #'4
            bne  nofour
            lda  DISK_TRACK
            cmp  #34
            beq  nofour
            lda  #34
            sta  DISK_TRACK
            jsr  seek
            jmp  nokey
nofour

            cmp  #$1B ; ESC
            bne  noesc
            lda  #$FF
            sta  EXIT_FLAG
noesc
            cmp  #'N
            bne  nomotoron
            ldx  DISK_SLOT ; restore X
            lda  MOTORON,x ; motor on
            lda  #CODE_Y
            sta  RUNNING
nomotoron

            cmp  #'F
            bne  nomotoroff
            ldx  DISK_SLOT ; restore X
            lda  MOTOROFF,x ; motor off
            lda  #CODE_N
            sta  RUNNING
nomotoroff

            cmp  #'1
            bne  nodrive1
            ldx  DISK_SLOT ; restore X
            lda  MOTOROFF,x ; motor off
            lda  #CODE_N
            sta  RUNNING
            lda  #$01
            sta  DISK_DRIVE
            jsr  setdisktrack
            jsr  resetscreen
            ldx  DISK_SLOT ; restore X
            lda  DRV0EN,x
            lda  MOTORON,x ; motor on
            lda  #CODE_Y
            sta  RUNNING
nodrive1

            cmp  #'2
            bne  nodrive2
            ldx  DISK_SLOT ; restore X
            lda  MOTOROFF,x ; motor off
            lda  #CODE_N
            sta  RUNNING
            lda  #$02
            sta  DISK_DRIVE
            jsr  setdisktrack
            jsr  resetscreen
            ldx  DISK_SLOT ; restore X
            lda  DRV1EN,x
            lda  MOTORON,x ; motor on
            lda  #CODE_Y
            sta  RUNNING
nodrive2

nokey

            ; --------------------------------------------------
            ; Is the motor running?
            ; --------------------------------------------------
            lda  RUNNING
            cmp  #CODE_Y
            beq  dofreewheelscan
            jmp  freewheelloop ; avoid infinite readbyte loop


            ; --------------------------------------------------
            ; Find address field:
            ;   D5 AA 96 {2:VOL} {2:TRACK} {2:SECT} {2:CHKSUM} DE AA EB
            ; --------------------------------------------------
dofreewheelscan
            ldx  DISK_SLOT ; restore X


            ; ldy  $fc
            ldy  $00
            sty  TEMP1
readbyte0   iny
            bne  readbyte1
            inc  TEMP1
            beq  noheadererr
readbyte1   readbyte
chkbyte0    cmp  #PROLOGUE_0
            bne  readbyte0
            nop
            readbyte
            cmp  #PROLOGUE_1
            bne  chkbyte0

            ldy  #$3  ; 4 bytes: vol, track, sect, checksum
readbyte2   readbyte
            cmp  #PROLOGUE_2_ADDR
            bne  chkbyte0

            LDA  #$0  ; checksum
loopreadhdr sta  CALC_CHKSUM
            readbyte
            rol
            sta  TEMP1
            readbyte
            and  TEMP1
            sta  FOUND_HDR,y
            eor  CALC_CHKSUM
            dey
            bpl  loopreadhdr
            sta  CALC_CHKSUM
            tay
            bne  addrchecksumerr

            readbyte
            cmp  #EPILOGUE_0
            bne  epilogerr1

            readbyte
            cmp  #EPILOGUE_1
            bne  epilogerr1

            ; readbyte
            ; cmp  #EPILOGUE_2
            ; bne  epilogerr1

            jmp  readdatafield
noheadererr
            lda  #ERR_CODE_MISSING
            sta  ADDR_FIELD_ERR_ADDR_M
            jmp  readdatafield

addrchecksumerr
            lda  #ERR_CODE_CHECKSUM
            sta  ADDR_FIELD_ERR_ADDR_K
            jmp  readdatafield

epilogerr1
            lda  #ERR_CODE_EPILOGUE
            sta  ADDR_FIELD_ERR_ADDR_E

            ; --------------------------------------------------
            ; Find data field:
            ;   D5 AA AD {342:DATA}                 {2:CHKSUM} DE AA EB
            ; --------------------------------------------------
readdatafield
            ldy  #$20 ; 32 attempts
readbyte3
            dey
            beq  nodatafield
            readbyte
chkbyte3    eor  #PROLOGUE_0
            bne  readbyte3
            nop
readbyte4
            readbyte
            cmp  #PROLOGUE_1
            bne  chkbyte3

            ldy  #(342-256) ; 86 bytes
            readbyte
            cmp  #PROLOGUE_2_DATA
            bne  chkbyte3
            ; carry is now set

            ; lda  #'3 & $3F
            ; sta  ADDR_FIELD_ERR_ADDR

            ; --------------------------------------------------
            ; read bytes
            ; --------------------------------------------------


            ; read 86 bytes
            lda  #$00 ; checksum
loopbyte6   dey
            sty  TEMP1
            readbyte_y
            eor  MAP_6AND2,y
            ldy  TEMP1
            ; sta buf2,y
            bne  loopbyte6

loopbyte7   sty  TEMP1
            readbyte_y
            eor  MAP_6AND2,y
            ldy  TEMP1
            ; sta buf1,y
            iny
            bne  loopbyte7

            readbyte_y
            cmp  MAP_6AND2,y
            bne  chksumerr2

            readbyte
            cmp  #EPILOGUE_0
            bne  epilogerr2

            readbyte
            cmp  #EPILOGUE_1
            bne  epilogerr2

            ; readbyte
            ; cmp  #EPILOGUE_2
            ; bne  epilogerr2

            jsr  renderdatachecksumok
            jsr  showfound
            jsr  maybefixtrack

            jmp  enddataerr

chksumerr2
            sta  DATA_CHECKSUM
            jsr  renderdatachecksumbad
            lda  #ERR_CODE_CHECKSUM
            sta  DATA_FIELD_ERR_ADDR_K
            jmp  enddataerr

epilogerr2
            lda  #ERR_CODE_EPILOGUE
            sta  DATA_FIELD_ERR_ADDR_E
            jmp  enddataerr

nodatafield
            lda  #ERR_CODE_MISSING
            sta  DATA_FIELD_ERR_ADDR_M
            ; jmp  enddataerr

enddataerr
            jmp  freewheelloop


; --------------------------------------------------
; Display write protect stats
; --------------------------------------------------
showwp      ldx  DISK_SLOT
            lda  Q6H,x ; Sense WP
            LDA  Q7L,x ; Sense WP
            bmi  write_protected
            lda  #CODE_N
            jmp  end_write_protect
write_protected
            lda  #CODE_Y
end_write_protect
            sta  WRITE_PROTECT_ADDR
            rts

; --------------------------------------------------
; Helpers
; --------------------------------------------------
resetscreen
            printmessage M_SLOT_DRIVE
            printmessage M_TARGET_TRACK
            printmessage M_DIVIDER
            printmessage M_VOL_TRK_SECT
            printmessage M_WRITE_PROTECT
            printmessage M_VERSION
            printmessage M_DATA_CHECKSUM
            printmessage M_FIELDS
            renderhex DISK_TRACK,TARGET_TRACK_ADDR
clearsect   ldy  #15
clearsectloop
            tya
            asl
            tax
            lda  #'_ | $80
            sta  touchsect_addr,x
            dey
            bpl  clearsectloop
endclearsect
            lda  DISK_SLOT
            clc
            ror
            ror
            ror
            ror
            tay
            lda  hexchars,y
            sta  SLOT_ADDR
            ldy  DISK_DRIVE
            lda  hexchars,y
            sta  DRIVE_ADDR
            rts

touchsect   and  #$0f ; TODO report bad sector > $0f
            tax
            tay
            lda  sects_appledos,y
            tay
            txa
            asl
            tax
            lda  hexchars,y
            and  #$bf
            cmp  touchsect_addr,x
            bne  endtouchsect
            eor  #$80
endtouchsect
            sta  touchsect_addr,x
            rts

printnibble
            stx  SAVEX
            pha
            and  #$0f
            tax
            lda  hexchars,x
            jsr  COUT
            pla
            ldx  SAVEX
            rts

; printhex
;             stx  SAVEX
;             pha
;             and  #$f0
;             lsr
;             lsr
;             lsr
;             lsr
;             tax
;             lda  hexchars,x
;             jsr  COUT
;             pla
;             pha
;             and  #$0f
;             tax
;             lda  hexchars,x
;             jsr  COUT
;             pla
;             ldx  SAVEX
;             rts

showfound
            renderhex FOUND_VOLUME,VOLUME_ADDR
            renderhex FOUND_TRACK,TRACK_ADDR
            renderhex FOUND_SECTOR,SECTOR_ADDR
            renderhex CALC_CHKSUM,CHKSUM_ADDR
            lda  FOUND_SECTOR
            jsr  touchsect
            rts

renderdatachecksumok
            lda  #'_ | $80
            sta  DATA_CHECKSUM_ADDR+0
            sta  DATA_CHECKSUM_ADDR+1
            sta  DATA_CHECKSUM_ADDR+2
            rts

renderdatachecksumbad
            renderhex DATA_CHECKSUM,DATA_CHECKSUM_ADDR
            lda  #'!
            sta  DATA_CHECKSUM_ADDR+2
            rts

; --------------------------------------------------
; Disk II
; --------------------------------------------------
seek
            jsr  resetscreen
            lda  #DISK_CMD_SEEK
            sta  DISK_CMD
            lda  #>DISK_IOB
            ldy  #<DISK_IOB
            jsr  RWTS
            ldx  DISK_SLOT ; restore X
            lda  MOTORON,x ; keep motor on
            lda  #CODE_Y
            sta  RUNNING
            php
            renderhex DISK_TRACK,TARGET_TRACK_ADDR
            plp
            bcc  noseekerr
seekerr     lda  #ERR_CODE_SEEK
            sta  SEEK_ERR_ADDR
noseekerr
            jsr  showwp
            rts


; readsect
;             lda  #DISK_CMD_READ
;             sta  DISK_CMD

;             lda  #<DISK_BUFFER
;             sta  DISK_BUFFPTR
;             lda  #>DISK_BUFFER
;             sta  DISK_BUFFPTR+1

;             lda  #>DISK_IOB
;             ldy  #<DISK_IOB
;             jsr  RWTS
;             lda #???
;             sta RUNNING
;             bcc  nodiskerr
; diskerr     lda  #ERR_CODE_SEEK
;             sta  SEEK_ERR_ADDR
;             renderhex DISK_ERR,TARGET_ERR_ADDR
; nodiskerr
;             rts


setdisktrack
            lda  DISK_SLOT
            lsr
            lsr
            lsr
            lsr
            tay
            lda  DISK_DRIVE
            cmp  #$01
            bne  prevtrackdrive2
            lda  DRV1TRK,y
            jmp  endprevtrack
prevtrackdrive2
            lda  DRV2TRK,y
endprevtrack
            lsr
            sta  DISK_TRACK
            rts

maybefixtrack
            lda  FOUND_TRACK
            cmp  DISK_TRACK
            bne  askfixtrack
            rts
askfixtrack
            printmessageinv M_BAD_TRACK
            renderhex FOUND_TRACK,BAD_TRACK_ADDR1
            renderhex DISK_TRACK,BAD_TRACK_ADDR2
            jsr  BELLB
maybefixkey lda  KBD
            bpl  maybefixkey
            sta  KBDSTRB
            and  #$7f
            cmp  #'a
            bcc  maybefixnocase
            cmp  #'z+1
            bcs  maybefixnocase
            eor  #$20
maybefixnocase
            cmp  #$1B ; ESC
            bne  maybefixnoesc
            lda  #$FF
            sta  EXIT_FLAG
            jmp  endfixtrack
maybefixnoesc
            cmp  #'N
            beq  endfixtrack
            cmp  #'Y
            bne  maybefixkey
            lda  DISK_SLOT
            lsr
            lsr
            lsr
            lsr
            tay
            lda  DISK_DRIVE
            cmp  #1
            bne  maybefixdrivetrack2
            lda  FOUND_TRACK
            clc
            rol
            sta  DRV1TRK,y
            jmp  fixtrackseek
maybefixdrivetrack2
            lda  FOUND_TRACK
            clc
            rol
            sta  DRV2TRK,y
fixtrackseek
            jsr  seek
endfixtrack
            printmessage M_BAD_TRACK_OK
            rts

; --------------------------------------------------
; Messages
; --------------------------------------------------
M_SLOT_DRIVE
            byte $00, $00 ; ypos,xpos
            byte "SLOT _   DRIVE _ :",13
            byte 0
SLOT_ADDR   equ  text_row_00+5
DRIVE_ADDR  equ  text_row_00+15
SPINNER_ADDR equ text_row_00+17

M_WRITE_PROTECT
            byte $00,$13 ; ypos, xpos
            byte "WRITE PROTECT _",0
WRITE_PROTECT_ADDR equ text_row_00+33

M_VERSION
            byte $00,$24 ; ypos, xpos
            byte "V1.2",0

M_TARGET_TRACK
            byte $01,$00 ; ypos, xpos
            byte "TARGET VOL __   TRK __   SEC __   ERR __",0
;TARGET_VOL_ADDR equ text_row_01+11
TARGET_TRACK_ADDR equ text_row_01+20
;TARGET_SEC_ADDR equ text_row_01+29
;TARGET_ERR_ADDR equ text_row_01+38

M_DIVIDER
            byte $02,$00 ; ypos, xpos
            byte "========================================",0

M_VOL_TRK_SECT
            byte $04, 00 ; ypos, xpos
            byte "READ   VOL __   TRK __   SEC __   CHK __",0
VOLUME_ADDR equ  text_row_04+11
TRACK_ADDR  equ  text_row_04+20
SECTOR_ADDR equ  text_row_04+29
CHKSUM_ADDR equ  text_row_04+38

touchsect_addr equ text_row_06+5

M_DATA_CHECKSUM
            byte $08,$00 ; ypos, xpos
            byte "SEEK ERR _         DATA CHECKSUM ERR ___",0
SEEK_ERR_ADDR equ text_row_08+9
DATA_CHECKSUM_ADDR equ text_row_08+37

M_FIELDS
            byte $0a,$00 ; ypos, xpos
            byte "ADDR FIELD ERR ___    DATA FIELD ERR ___",0
ADDR_FIELD_ERR_ADDR_M equ text_row_0a+15
ADDR_FIELD_ERR_ADDR_K equ text_row_0a+16
ADDR_FIELD_ERR_ADDR_E equ text_row_0a+17
DATA_FIELD_ERR_ADDR_M equ text_row_0a+37
DATA_FIELD_ERR_ADDR_K equ text_row_0a+38
DATA_FIELD_ERR_ADDR_E equ text_row_0a+39

M_BAD_TRACK
            byte $0d, 00 ; ypos, xpos
            byte "UNEXPECTED TRACK __, SEEK TO __? [Y]/[N]",0
M_BAD_TRACK_OK
            byte $0d, 00 ; ypos, xpos
            byte "                                        ",0
BAD_TRACK_ADDR1 equ text_row_0d+17
BAD_TRACK_ADDR2 equ text_row_0d+29


M_INSTRUCTIONS
            byte $0f,$00 ; ypos, xpos
            byte "SELECT DRIVE [1], [2]   MOTOR O[N] OF[F]"
            byte "TRACK [0], 3[4] OR [LEFT]/[RGHT] FOR -/+"
            byte "                              [ESC] EXIT"
            byte "ERROR",13
            byte "CODES: _EEK  _ISSING  CHEC_SUM  _PILOGUE",0
ERR_CODE_SEEK_ADDR equ text_row_13+7
ERR_CODE_MISSING_ADDR equ text_row_13+13
ERR_CODE_CHECKSUM_ADDR equ text_row_13+26
ERR_CODE_EPILOGUE_ADDR equ text_row_13+32

M_TITLE
            byte $16,$01 ; ypos, xpos
            byte " FLUXDOCTOR ",0

M_COPYRIGHT
            byte $16,$0e ; ypos, xpos
            byte "COPYRIGHT FRED SAUER 2026",0

M_GITHUB
            byte $17,$01 ; ypos, xpos
            byte "GITHUB.COM/FREDSA/APPLE-II-FLUXDOCTOR"

M_BYE
            byte $00,$00 ; ypos, xpos
            byte "GITHUB.COM/FREDSA/APPLE-II-FLUXDOCTOR",13
            byte 13
            byte "THANK YOU FOR USING FLUXDOCTOR.",13
            byte "GOODBYE FOR NOW.",13
            byte 0

; --------------------------------------------------
; Data
; --------------------------------------------------
spinnerchars
            byte '/ | $80
            byte '- | $80
            byte '\ | $80
            byte ': | $80
hexchars    byte '0 & $3F, '1 & $3F, '2 & $3F, '3 & $3F
            byte '4 & $3F, '5 & $3F, '6 & $3F, '7 & $3F
            byte '8 & $3F, '9 & $3F, 'A & $3F, 'B & $3F
            byte 'C & $3F, 'D & $3F, 'E & $3F, 'F & $3F

sects_appledos byte 0,13,11,9,7,5,3,1,14,12,10,8,6,4,2,15


dos33_6and2
            ; https://wikipedia.org/wiki/Group_coded_recording#Apple > 6-and-2
            byte $96, $97, $9A, $9B, $9D, $9E, $9F, $A6 ; 6-bit values $00 - $07
            byte $A7, $AB, $AC, $AD, $AE, $AF, $B2, $B3 ; 6-bit values $08 - $0f
            byte $B4, $B5, $B6, $B7, $B9, $BA, $BB, $BC ; 6-bit values $10 - $17
            byte $BD, $BE, $BF, $CB, $CD, $CE, $CF, $D3 ; 6-bit values $18 - $1f
            byte $D6, $D7, $D9, $DA, $DB, $DC, $DD, $DE ; 6-bit values $20 - $27
            byte $DF, $E5, $E6, $E7, $E9, $EA, $EB, $EC ; 6-bit values $28 - $2f
            byte $ED, $EE, $EF, $F2, $F3, $F4, $F5, $F6 ; 6-bit values $30 - $37
            byte $F7, $F9, $FA, $FB, $FC, $FD, $FE, $FF ; 6-bit values $38 - $3f

text_rows
            word text_row_00,text_row_01,text_row_02,text_row_03,text_row_04
            word text_row_05,text_row_06,text_row_07,text_row_08,text_row_09
            word text_row_0a,text_row_0b,text_row_0c,text_row_0d,text_row_0e
            word text_row_0f,text_row_10,text_row_11,text_row_12,text_row_13
            word text_row_14,text_row_15,text_row_16,text_row_17

; --------------------------------------------------
; RWTS
; --------------------------------------------------
; DRV1TRK EQU $478
; DRV2TRK EQU $4F8
IOBPL EQU $48
IOBPH EQU $49
SLOT EQU $5F8 ;HOLDS SLOT NUM USED
PTRSDEST EQU $3C
DEVCTBL EQU PTRSDEST
; DRIVNO EQU $35
MONTIME EQU $46
SECT EQU CSSTV+1
TRACK EQU CSSTV+2
VOLUME EQU CSSTV+3
MAXSEEKS EQU 4 ;MAX FOR SEEKCNT
SEEKCNT EQU $4F8 ;# RESEEKS BEFORE RECALIBRATE
RETRYCNT EQU $578
RECALCNT EQU $6F8 ;# RECALIBRATES -1

; --------------------------------------------------
; RDADR16
; --------------------------------------------------
COUNT EQU $26 ;'MUST FIND' COUNT.
LAST EQU $26 ;'ODD BIT' NIBLS.
CSUM EQU $27 ;CHECKSUM BYTE.
CSSTV EQU $2C ;FOUR BYTES,
              ;* CHECKSUM, SECTOR, TRACK, AND VOLUME.

; --------------------------------------------------
; MSWAIT
; --------------------------------------------------
MONTIMEL EQU $46 ; MOTOR-ON TIME
MONTIMEH EQU $47 ; COUNTERS.

; --------------------------------------------------
; SEEK
; --------------------------------------------------
TRKCNT EQU $26 ;HALFTRKS MOVED COUNT.
PRIOR EQU $27 ;PRIOR HALFTRACK.
TRKN EQU $2A ;DESIRED TRACK.
SLOTTEMP EQU $2B ;SLOT NUM TIMES $10.
CURTRK EQU $478 ;CURRENT TRACK ON ENTRY.

; --------------------------------------------------
; PRENIBL16
; --------------------------------------------------
T0 EQU $26 ;TEMP FOR POSTNBL16.

; --------------------------------------------------
; READ16
; --------------------------------------------------
IDX EQU $26 ;INDEX INTO (BUF).


; --------------------------------------------------
; RWTS
; --------------------------------------------------
RWTS    STY IOBPL ;UPON ENTRY, A&Y POINT AT THE
        STA IOBPH ;I/O CONTROL BLOCK (IOB)
        LDY #2 ;SET RECALIBRATE
        STY RECALCNT ; COUNT
        LDY #MAXSEEKS ;SET RESEEK
        STY SEEKCNT ; COUNT
        LDY #1 ;GET SLOT # FOR THIS OPERATION
        LDA (IOBPL),Y
        TAX
        LDY #$0F ;DID HE CHANGE SLOTS?
        CMP (IOBPL),Y
        BEQ SAMESLOT ;IF HE DIDN'T, GOOD FOR HIM!
        ; *
        ; * NOW ARE USING A DIFFERENT SLOT.
        ; * NOW WAIT FOR THIS DRIVE TO TURN OFF
        ; * TO SENSE MOTOR NOT SPINNING, DATA FROM DISK MUST
        ; * BE THE SAME FOR AT LEAST 96 MICROSECONDS
        TXA ;SAVE NEW SLOT #
        PHA
        LDA (IOBPL),Y ;GET 'OLD SLOT NUMBER'
        TAX
        PLA
        PHA ;PUT BACK ON STACK
        STA (IOBPL),Y ;SAVE 'NEW SLOT NUMBER'
        LDA Q7L,X ;GO INTO READ MODE
STILLON LDY #$08 ;TO BE SURE, DATA MUST REMAIN
        LDA Q6L,X ;STABLE FOR 96 MICROSECONDS
NOTSURE CMP Q6L,X ;DATA STILL CHANGING?
        BNE STILLON ;IF SO, STILL SPINNING
        DEY
       ;;;;;;;; BNE NOTSURE ;STABLE LONG ENOUGH? IF NOT, LOOP
        ; *
        ; * PREVIOUS SLOT'S DRIVE NOW OFF...
        ; *
        PLA ;RESTORE NEW SLOT #
        TAX
        ; *
        ; * NOW CHECK IF THE MOTOR IS ON, THEN START IT
        ; *
SAMESLOT LDA Q7L,X ;MAKE SURE IN READ MODE
        LDA Q6L,X
        LDY #8 ;WE MAY HAFTA CHECK SEVERAL TIMES TO
        ; BE SURE
CHKIFON LDA Q6L,X ;GET THE DATA
        PHA ;DELAY FOR DISK DATA TO CHANGE
        PLA
        PHA
        PLA
        STX SLOT
        CMP Q6L,X ;CHECK RUNNING HERE
        BNE ITISON ;=>IT'S ON...
        DEY ;MAYBE WE DIDN'T CATCH IT
        BNE CHKIFON ; SO WE'LL TRY AGAIN
        ; *
ITISON
    PHP ;SAVE TEST RESULTS
    LDA MOTORON,X ;TURN ON MOTOR REGARDLESS
    LDY #6 ;MOVE OUT ALL POINTERS INTO ZPAGE
PTRMOV LDA (IOBPL),Y
    STA PTRSDEST-6,Y
    INY
    CPY #$0A ;MOVED ALL POINTERS?
    BNE PTRMOV
    LDY #3 ;SET UP THE
    LDA (DEVCTBL),Y ; MOTOR-ON TIME
    STA MONTIME+1
    LDY #2 ;NOW GET PARAMS
    LDA (IOBPL),Y ;DETERMINE DRIVE ONE OR TWO
    LDY #$10 ;SAME DRIVE USED BEFORE?
    CMP (IOBPL),Y
    BEQ OK ;IF SO, DON'T NECESSARILY WAIT FOR
MOTOR
    STA (IOBPL),Y ;NOW USING THIS DRIVE
    PLP ;TELL HIM MOTOR WAS OFF
    LDY #$00 ;SET ZERO FLAG
    PHP
OK ROR ;BY GOING INTO THE CARRY
    BCC SD1 ;SELECT DRIVE 2 !
    LDA DRV0EN,X ;ASSUME DRIVE 0 TO HIT
    BCS DRVSEL ;IF WRONG, ENABLE DRIVE 1 INSTEAD
SD1 LDA DRV1EN,X
DRVSEL
    ROR DRIVNO ;SAVE SELECTED DRIVE
; *
; * DRIVE SELECTED. IF MOTORING-UP,
; * WAIT BEFORE SEEKING...
; *
    PLP ;WAS THE MOTOR
    PHP ; PREVIOUSLY OFF?
    BNE NOWAIT ;=>NO, FORGET WAITING.
    LDY #7 ;YES, DELAY 150 MS
SEEKW JSR MSWAIT
    DEY
    BNE SEEKW
    LDX SLOT ;RESTORE SLOT NUMBER
; *
NOWAIT
; *
; * SEEK TO DESIRED TRACK...
; *
    LDY #4 ;SET TO IOBTRK
    LDA (IOBPL),Y ;GET DESIRED TRACK
    JSR MYSEEK ;SEEK!
; *
; * SEE IF MOTOR WAS ALREADY SPINNING.
; *
    PLP ;WAS MOTOR ON?
    BNE TRYTRK ;IF SO, DON'T DELAY, GET IT TODAY!
; *
; * WAIT FOR MOTOR SPEED TO COME UP.
; *
    LDY MONTIME+1 ;IF MOTORTIME IS POSITIVE,
    BPL MOTORUP ; THEN SEEK WASTED ENUFF TIME FOR US
MOTOF LDY #$12 ;DELAY 100 USEC PER COUNT
CONWAIT DEY
    BNE CONWAIT
    INC MONTIME
    BNE MOTOF
    INC MONTIME+1
        BNE MOTOF ;COUNT UP TO $0000
MOTORUP

; --------------------------------------------------
; TRYTRK
; --------------------------------------------------
; *
; * DISK IS NOW UP TO SPEED: READ IT!
; * NOW CHECK: IF IT IS NOT THE FORMAT DISK COMMAND,
; * LOCATE THE CORRECT SECTOR FOR THIS OPERATION.
; *
TRYTRK
    LDY #$0C
    LDA (IOBPL),Y ;GET COMMAND CODE #
    BEQ GALLDONE ;IF NULL COMMAND, GO HOME TO BED.
;;;    CMP #$04 ;FORMAT THE DISK?
    ;;;BEQ FORMDSK ;ALLRIGHT,ALLRIGHT, I WILL...
    ROR ;SET CARRY=1 FOR READ, 0 FOR WRITE
    PHP ;AND SAVE THAT
    BCS TRYTRK2 ;MUST PRENIBBLIZE FOR WRITE.
    JSR PRENIB16
TRYTRK2 LDY #$30 ;ONLY 48 RETRIES OF ANY KIND.
    STY RETRYCNT
TRYADR LDX SLOT ;GET SLOT NUM INTO X-REG
    JSR RDADR16 ;READ NEXT ADDRESS FIELD
    BCC RDRIGHT ;IF READ IT RIGHT, HURRAH!
TRYADR2 DEC RETRYCNT ;ANOTHER MISTAEK!!

    BPL TRYADR ; WELL, LET IT GO THIS TIME.,
; *
; * RRRRRECALIBRATE !!!!
; *
RECAL
    LDA DRV1TRK
    PHA ;SAVE TRACK WE REALLY WANT
    LDA #$60 ;RECALIBRATE ALL OVER AGAIN!
    JSR SETTRK ;PRETEND TO BE ON TRACK 96
    DEC RECALCNT ;ONCE TOO MANY??
    BEQ DRVERR ;TRIED TO RECALIBRATE TOO MANY
;TIMES, ERROR!
    LDA #MAXSEEKS ;RESET THE
    STA SEEKCNT ; SEEK COUNTER
    LDA #$00
    JSR MYSEEK ;MOVE TO TRACK 00
    PLA
RESEEK JSR MYSEEK ;GO TO CORRECT TRACK THIS TIME!
    JMP TRYTRK2 ;LOOP BACK, TRY AGAIN ON THIS TRACK
; *
; * HAVE NOW READ AN ADDRESS FIELD CORRECTLY.
; * MAKE SURE THIS IS THE TRACK, SECTOR, AND VOLUME DESIRED.
; *
RDRIGHT LDY TRACK ;ON THE RIGHT TRACK?
    CPY DRV1TRK
    BEQ RTTRK ;IF SO, GOOD
; * NO, DRIVE WAS ON A DIFFERENT TRACK. TRY
; * RESEEKING/RECALIBRATING FROM THIS TRACK
    LDA DRV1TRK ;PRESERVE DESTINATION TRACK
    PHA
    TYA
    JSR SETTRK
    PLA
    DEC SEEKCNT ;SHOULD WE RESEEK?
    BNE RESEEK ;=>YES, RESEEK
    BEQ RECAL ;=>NO, RECALIBRATE!
; ***
DRVERR PLA ;REMOVE DRV1TRK.
    LDA #DISK_ERR_DRIVE ;BAD DRIVE ERROR
JMPTO1 PLP
    JMP HNDLERR
GALLDONE BEQ ALLDONE
;;; FORMDSK JMP DSKFORM ;=>GO TO IT!
; *
; * DRIVE IS ON RIGHT TRACK, CHECK VOLUME MISMATCH
; *
RTTRK LDY #3 ;IS THE RIGHT DISK IN?
    LDA (IOBPL),Y ;GET DESIRED VOLUM
    PHA ;PRESERVE DESIRED VOLUME#
    LDA VOLUME ;GET ACTUAL VOLUME HERE
    LDY #$0E ;TELL OPSYS WHAT VOLUME WAS THERE
    STA (IOBPL),Y
    PLA ;GET DESIRED VOLUME BACK
    BEQ CORRECTVOL ;DESIRED VOLUME 00 MATCHES ALL.
    CMP VOLUME
    BEQ CORRECTVOL ;YUP, IT WAS RIGHT
    LDA #DISK_ERR_VOL ;HE SWITCHED DISCS!
    BNE JMPTO1 ;ALWAYS TAKEN
CORRECTVOL
    LDY #5 ; TO ALLOW FOR INTERLEAVE
    LDA (IOBPL),Y ;GET REQUESTED (LOGICAL) SECTOR
    TAY ;MOVE TO INDEX REG
    LDA INTRLEAV,Y ;COMPUTE PHYSICAL SECTOR
    CMP SECT ;DID WE GET THE SECTOR?
    BNE TRYADR2 ;NO, KEEP TRYING.
; *
; * HOORAY! WE GOT THE RIGHT SECTOR!
; *
GOTSECT
    PLP
    BCC WRIT ;CARRY WAS SET FOR READ OPERATION,
    JSR READ16 ;CLEARED FOR WRITE
    PHP ;SAVE STATUS OF READ OPERATION
    BCS TRYADR2 ;CARRY SET UPON RETURN IF BAD READ
    PLP ;CAREFUL OF STACK
    LDX #0 ;SET TO POSTNIBLIZE
    STX T0 ; ALL 256 BYTES OF THE SECTOR
    JSR POSTNB16 ;DECODE INTO REAL WORLD DATA
    LDX SLOT ;RESTORE SLOTNUM INTO X
ALLDONE CLC
    byte $24 ;SKIP OVER NEXT BYTE WITH BIT OPCODE
HNDLERR SEC ;INDICATE AN ERROR
    LDY #$0D ;GIVE HIM ERROR#
    STA (IOBPL),Y
    LDA MOTOROFF,X ;TURN IT OFF...
    RTS
WRIT
    JSR WRITE16 ;WRITE NYBBLES NOW
    BCC ALLDONE ;IF NO ERRORS.
    LDA #DISK_ERR_WP ;DISK IS WRITE PROTECTED!!
    BCS HNDLERR ;ALWAYS TAKEN
; *
; * THIS IS THE 'SEEK' ROUTINE
; * SEEKS TRACK 'N' IN SLOT #X/$10
; * IF DRIVNO IS NEGATIVE, ON DRIVE 1
; * IF DRIVNO IS POSITIVE, ON DRIVE 2
; *
MYSEEK PHA ;AND PRESERVE A-REGISTER
    LDY #$01 ;IS THIS A TWO-PHASE DISC?
    LDA (DEVCTBL),Y
    ROR ;GET # OF PHASES INTO CARRY
    PLA
    BCC MYSEEK2 ;IF ONE PHASE PER TRACK
    ASL
    JSR MYSEEK2
    LSR DRV1TRK ;DIVIDE BACK DOWN
    RTS
MYSEEK2 STA TRKN ;SAVE DESTINATION TRACK(*2)
    JSR XTOY ;SET Y=SLOT#
    LDA DRV1TRK,Y
    BIT DRIVNO
    BMI WASD0 ;IS MINUS, ON DRIVE ZERO
    LDA DRV2TRK,Y
WASD0 STA DRV1TRK ;THIS IS WHERE I AM
    LDA TRKN ;AND WHERE I'M GOING TO
    BIT DRIVNO ;NOW UPDATE SLOT DEPENDENT
    BMI ISDRV1 ;LOCATIONS WITH TRACK
    STA DRV2TRK,Y ;INFORMATION
    BPL GOSEEK ;ALWAYS TAKEN
ISDRV1 STA DRV1TRK,Y
GOSEEK JMP SEEK ;GO THERE!
XTOY TXA
    LSR
    LSR
    LSR
    LSR
    TAY
    RTS
; *
; * THIS SUBROUTINE SETS THE SLOT DEPENDENT TRACK
; * LOCATION.
; *
SETTRK PHA ;PRESERVE DESTINATION TRACK
    LDY #$02
    LDA (IOBPL),Y
    ROR ;GET DRIVE # INTO CARRY
    ROR DRIVNO ;INTO (DRIVNO)
    JSR XTOY ;SET UP Y-REG
    PLA
    ASL ;ASSUME TRACK IS HELD *2
SETTRK2 BIT DRIVNO
    BMI ONDRV1 ;IF ON DRIVE 1(1), DRIVNO MINUS
       STA DRV2TRK,Y
       BPL SETRTS
ONDRV1 STA DRV1TRK,Y
SETRTS RTS



; --------------------------------------------------
; READ16
; --------------------------------------------------

READ16 LDY #$20 ;'MUST FIND' COUNT.
RSYNC DEY ;IF CAN'T FIND MARKS
        BEQ RDERR ;THEN EXIT WITH CARRY SET.
READ1 LDA Q6L,X ;READ NIBL.
        BPL READ1 ;*** NO PAGE CROSS! ***
RSYNC1 EOR #$D5 ;DATA MARK 1?
        BNE RSYNC ;LOOP IF NOT.
        NOP ;DELAY BETWEEN NIBLS.
READ2 LDA Q6L,X
        BPL READ2 ;*** NO PAGE CROSS! ***
        CMP #$AA ;DATA MARK 2?
        BNE RSYNC1 ;(IF NOT, IS IT DM1?)
        LDY #$56 ;INIT NBUF2 INDEX.
        ; * (ADDED NIBL DELAY)
READ3 LDA Q6L,X
        BPL READ3 ;*** NO PAGE CROSS! ***
        CMP #$AD ;DATA MARK 3?
        BNE RSYNC1 ;(IF NOT, IS IT DM1?)
        ; * (CARRY SET IF DM3!)
        LDA #$00 ;INIT CHECKSUM.
RDATA1 DEY
        STY IDX
READ4 LDY Q6L,X
        BPL READ4 ;*** NO PAGE CROSS! ***
        EOR DNIBL,Y ;XOR 6-BIT NIBL.
        LDY IDX
        STA NBUF2,Y ;STORE IN NBUF2 PAGE.
        BNE RDATA1 ;TAKEN IF Y-REG NONZERO.
RDATA2 STY IDX
READ5 LDY Q6L,X
        BPL READ5 ;*** NO PAGE CROSS! ***
        EOR DNIBL,Y ;XOR 6-BIT NIBL.
        LDY IDX
        STA NBUF1,Y ;STORE IN NBUF1 PAGE.
        INY
        BNE RDATA2
READ6 LDY Q6L,X ;READ 7-BIT CSUM NIBL.
        BPL READ6 ;*** NO PAGE CROSS! ***
        CMP DNIBL,Y ;IF LAST NBUF1 NIBL NOT
        BNE RDERR ;EQUAL CHKSUM NIBL THEN ERR.
READ7 LDA Q6L,X
        BPL READ7 ;*** NO PAGE CROSS! ***
        CMP #$DE ;FIRST BIT SLIP MARK?
        BNE RDERR ;(ERR IF NOT)
        NOP ;DELAY BETWEEN NIBLS.
READ8 LDA Q6L,X
        BPL READ8 ;*** NO PAGE CROSS! ***
        CMP #$AA ;SECOND BIT SLIP MARK?
        BEQ RDEXIT ;(DONE IF IT IS)
RDERR SEC ;INDICATE 'ERROR EXIT'.
        RTS ;RETURN FROM READ16 OR RDADR16.

; --------------------------------------------------
; RDADR16
; --------------------------------------------------
RDADR16 LDY #$FC
    STY COUNT ;'MUST FIND' COUNT.
RDASYN INY
    BNE RDA1 ;LOW ORDER OF COUNT.
    INC COUNT ;(2K NIBLS TO FIND
    BEQ RDERR ;ADR MARK, ELSE ERR)
RDA1 LDA Q6L,X ;READ NIBL.
    BPL RDA1 ;*** NO PAGE CROSS! ***
RDASN1 CMP #$D5 ;ADR MARK 1?
    BNE RDASYN ;(LOOP IF NOT)
    NOP ; ADDED NIBL DELAY.
RDA2 LDA Q6L,X
    BPL RDA2 ;*** NO PAGE CROSS! ***
    CMP #$AA ;ADR MARK 2?
    BNE RDASN1 ;(IF NOT, IS IT AM1?)
    LDY #$3 ;INDEX FOR 4-BYTE READ.
; * (ADDED NIBL DELAY)
RDA3 LDA Q6L,X
    BPL RDA3 ;*** NO PAGE CROSS! ***
    CMP #$96 ;ADR MARK 3?
    BNE RDASN1 ;(IF NOT, IS IT AM1?)
; * (LEAVES CARRY SET!)
    LDA #$0 ;INIT CHECKSUM.
RDAFLD STA CSUM
RDA4 LDA Q6L,X ;READ 'ODD BIT' NIBL.
    BPL RDA4 ;*** NO PAGE CROSS! ***
    ROL ;ALIGN ODD BITS, '1' INTO LSB.
    STA LAST ;(SAVE THEM)
RDA5 LDA Q6L,X ;READ 'EVEN BIT' NIBL.
    BPL RDA5 ;*** NO PAGE CROSS! ***
    AND LAST ;MERGE ODD AND EVEN BITS.
    STA CSSTV,Y ;STORE DATA BYTE.
    EOR CSUM ;XOR CHECKSUM.
    DEY
    BPL RDAFLD ;LOOP ON 4 DATA BYTES.
    TAY ;IF FINAL CHECKSUM
    BNE RDERR ;NONZERO, THEN ERROR.
RDA6 LDA Q6L,X ;FIRST BIT-SLIP NIBL.
    BPL RDA6 ;*** NO PAGE CROSS! ***
    CMP #$DE
    BNE RDERR ;ERROR IF NONMATCH.
    NOP ;DELAY BETWEEN NIBLS.
RDA7 LDA Q6L,X ;SECOND BIT-SLIP NIBL.
    BPL RDA7 ;*** NO PAGE CROSS! ***
    CMP #$AA
    BNE RDERR ;ERROR IF NONMATCH.
RDEXIT CLC ;CLEAR CARRY ON
    RTS ;NORMAL


; --------------------------------------------------
; MSWAIT
; --------------------------------------------------
MSWAIT LDX #$11
MSW1 DEX ;DELAY 86 USEC.
    BNE MSW1
    INC MONTIMEL
    BNE MSW2 ;DOUBLE-BYTE
    INC MONTIMEH ;INCREMENT.
MSW2 SEC
    SBC #$1 ;DONE 'N' INTERVALS?
    BNE MSWAIT ;(A-REG COUNTS)
    RTS


; --------------------------------------------------
; SEEK
; --------------------------------------------------
SEEK STX SLOTTEMP ;SAVE X-REG
    STA TRKN ;SAVE TARGET TRACK
    CMP CURTRK ;ON DESIRED TRACK?
    BEQ SEEKRTS ;YES, RETURN
    LDA #$0
    STA TRKCNT ;HALFTRACK COUNT.
SEEK2 LDA CURTRK ;SAVE CURTRK FOR
    STA PRIOR ; DELAYED TURNOFF.
    SEC
    SBC TRKN ;DELTA-TRACKS.
    BEQ SEEKEND ;BR IF CURTRK=DESTINATION
    BCS OUT ;(MOVE OUT, NOT IN)
    EOR #$FF ;CALC TRKS TO GO.
    INC CURTRK ;INCR CURRENT TRACK (IN).
    BCC MINTST ;(ALWAYS TAKEN)
OUT ADC #$FE ;CALC TRKS TO GO.
    DEC CURTRK ;DECR CURRENT TRACK (OUT).
MINTST CMP TRKCNT
    BCC MAXTST ;AND 'TRKS MOVED'.
    LDA TRKCNT
MAXTST CMP #$C
    BCS STEP2 ;IF TRKCNT>$B LEAVE Y ALONE (Y=$B).
STEP TAY ;ELSE SET ACCELERATION INDEX IN Y
STEP2
    SEC ;CARRY SET=PHASE ON
    JSR SETPHASE ;PHASE ON
    LDA ONTABLE,Y ;FOR 'ONTIME'.
    JSR MSWAIT ;(100 USEC INTERVALS)
    LDA PRIOR
    CLC ;CARRY CLEAR=PHASE OFF
    JSR CLRPHASE ;PHASE OFF
    LDA OFFTABLE,Y ;THEN WAIT 'OFFTIME'.
    JSR MSWAIT ;(100 USEC INTERVALS)
    INC TRKCNT ;'TRACKS MOVED' COUNT.
    BNE SEEK2 ;(ALWAYS TAKEN)
; *
SEEKEND ;END OF SEEKING
    JSR MSWAIT ;A=0: WAIT 25 MS SETTLE
    CLC ; AND TURN OFF PHASE
; *
; * TURN HEAD STEPPER PHASE ON/OFF
; *
SETPHASE
    LDA CURTRK ;GET CURRENT PHASE
CLRPHASE
    AND #3 ;MASK FOR 1 OF 4 PHASES
    ROL ;DOUBLE FOR PHASE INDEX
    ORA SLOTTEMP
    TAX
    LDA PHASEOFF,X ;FLIP THE PHASE
         LDX SLOTTEMP ;RESTORE X-REG
SEEKRTS RTS

INTRLEAV
    byte $00,$0D,$0B,$09
    byte $07,$05,$03,$01
    byte $0E,$0C,$0A,$08
    byte $06,$04,$02,$0F

ONTABLE byte 1,$30,$28
    byte $24,$20,$1E
    byte $1D,$1C,$1C
         byte $1C,$1C,$1C
OFFTABLE byte $70,$2C,$26
      byte $22,$1F,$1E
      byte $1D,$1C,$1C
      byte $1C,$1C,$1C

;***************************
;* 7-BIT TO 6-BIT *
;* 'DENIBLIZE' TABL *
;* (16-SECTOR FORMAT) *
;* *
;* VALID CODES *
;* $96 TO $FF ONLY. *
;* *
;* *
;* CODES WITH MORE THAN *
;* ONE PAIR OF ADJACENT *
;* ZEROES OR WITH NO *
;* ADJACENT ONES (EXCEPT *
;* BIT 7) ARE EXCLUDED. *
;* *
;* THIS TABLE *MUST* BE *
;* ALIGNED AT THE END OF *
;* A PAGE IN MEMORY!!! *
;***************************
XP EQU <* ;CURRENT PAGE ADDRESS
DNIBL EQU 256*XP ;DNIBL TABLE PAGE


NBUF1 DS 256,0 ;NBUF1
NBUF2 DS 86,0 ;NBUF2

WRITE16 rts ; TODO
POSTNB16 rts ; TODO
PRENIB16  rts ; TODO

PGM_END
; Don't add instructions after this line
