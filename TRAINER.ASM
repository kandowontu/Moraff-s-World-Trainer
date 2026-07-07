;; ================================================================
;; MORAFF'S WORLD IN-GAME TRAINER
;; Assemble:  nasm -f bin -o TRAINER.COM TRAINER.ASM
;; Usage:     Run TRAINER.COM before WORLD.EXE, press TAB in-game
;; ================================================================
[BITS 16]
[ORG 0x100]
    jmp install
;; ======================== RESIDENT DATA ========================
old_int9    dd 0
busy        db 0
vid_mode    db 0
vesa_mode   dw 0
is_vesa     db 0
data_seg    dw 0
data_off    dw 0
cur_sel     db 0
fld_idx     db 0
fld_vis     db 0
scroll_top  db 0
input_buf   times 11 db 0
input_len   db 0
input_mode  db 0
page        db 0
spell_row   db 0
spell_col   db 0
sp_tmp      dd 0
equip_sel   db 0
EQ_WEP_OWN  equ 0x081
EQ_WEP_ENCH equ 0x08E
EQ_ARM_OWN  equ 0x0B0
EQ_ARM_ENCH equ 0x0B8
EQ_NAME_COL equ 25
EQ_OWN_COL  equ 44
EQ_ENCH_END equ 52
NFIELDS     equ 40
VIS_FIELDS  equ 20
BOX_L       equ 20
BOX_W       equ 40
BOX_T       equ 0
FIELD_ROW   equ 3
NAME_COL    equ 23
VAL_COL     equ 49
SPELL_ROW   equ 5
SPELL_COL   equ 23
RAISE_IDX   equ 23
fld_off:    dw 0x7A8              ; 0  Level
            dw 0x031, 0x033       ; 1-2  HP Cur/Max
            dw 0x035, 0x039       ; 3-4  SP Cur/Max (float32)
            dw 0x7D6              ; 5  Age
            dw 0x7AC, 0x7AE       ; 6-7  X/Y Position
            dw 0x7B0              ; 8  Floor Depth
            dw 0x812, 0x814, 0x816, 0x818, 0x81A, 0x81C  ; 9-14 Stats
            dw 0x454, 0x458       ; 15-16 Jewels Pocket/Bank
            dw 0x45C, 0x460, 0x464, 0x468, 0x46C, 0x470  ; 17-22 Stones
            dw 0x806              ; 23 Raise Contract
            dw 0x7D0              ; 23 Body Armor Lv
            dw 0x7D2              ; 24 AntiMagic Ring
            dw 0x846              ; 25 Gauntlet
            dw 0x7C9              ; 26 Stone of See
            dw 0x7C8              ; 27 Holy H Grenade
            dw 0x313              ; 28 Wand Charges
            dw 0x80E              ; 29 Potion Heal
            dw 0x810              ; 30 Stone of Telep
            dw 0x15E              ; 31 Green Pill
            dw 0x15D              ; 32 Orange Pill
            dw 0x15F              ; 33 Blue Pill
            dw 0x160              ; 34 Red Pill
            dw 0x161              ; 35 White Pill
            dw 0x162              ; 36 Yellow Pill
            dw 0x042              ; 37 FS Hit1 042
            dw 0x81F              ; 38 FS Hit2 81F
fld_sz:     db 2, 2,2, 5,5, 4, 2,2,2, 2,2,2,2,2,2, 4,4, 4,4,4,4,4,4, 2, 1, 1, 1, 1, 1, 1, 1,1, 1,1,1,1,1, 1, 1,1
fld_name:   db 'Level         '
            db 'HP Current    '
            db 'HP Max        '
            db 'SP Current    '
            db 'SP Maximum    '
            db 'Age           '
            db 'X Position    '
            db 'Y Position    '
            db 'Floor Depth   '
            db 'Strength      '
            db 'Intelligence  '
            db 'Wisdom        '
            db 'Constitution  '
            db 'Agility       '
            db 'Luck          '
            db 'Jewels Pocket '
            db 'Jewels Bank   '
            db 'Copper Stones '
            db 'Silver Stones '
            db 'Ivory Stones  '
            db 'Gold Stones   '
            db 'Platinum Stone'
            db 'Jewel Stones  '
            db 'Raise Contract'
            db 'Body Armor Lv '
            db 'AntiMagic Ring'
            db 'Gauntlet      '
            db 'Stone of See  '
            db 'Holy H Grenade'
            db 'Wand Charges  '
            db 'Potion Heal   '
            db 'Stone of Telep'
            db 'Green Pill    '
            db 'Orange Pill   '
            db 'Blue Pill     '
            db 'Red Pill      '
            db 'White Pill    '
            db 'Yellow Pill   '
            db 'FS Hit1  042  '
            db 'FS Hit2  81F  '
spell_base: dw 0x177, 0x1A4, 0x1D1, 0x1FE
spell_lbl:  db 'E', 'H', 'A', 'P'
wep_name:   db 'Fist        '
            db 'Stick       '
            db 'Club        '
            db 'Mace        '
            db 'Knife       '
            db 'Shortsword  '
            db 'Long Sword  '
            db 'Great Sword '
arm_name:   db 'Skin        '
            db 'Leather     '
            db 'Chain       '
            db 'Scale       '
            db 'Plate       '
            db 'Field Plate '
            db 'Titanium    '
            db 'Ogre        '
str_whdr:   db ' WEAPONS               OWN  ENCH', 0
str_ahdr:   db ' ARMOR                 OWN  ENCH', 0
str_ehelp:  db ' Spc=Own ',1Bh,1Ah,'=Ench ',18h,19h,'=Sel ESC=Back', 0
str_title:  db 0xC9
            times BOX_W-2 db 0xCD
            db 0xBB, 0
str_bottom: db 0xC8
            times BOX_W-2 db 0xCD
            db 0xBC, 0
str_sep:    db 0xCC
            times BOX_W-2 db 0xCD
            db 0xB9, 0
str_help:   db ' ', 18h,19h, 'Sel ', 1Bh,1Ah, 0xF1,'1 Pg'
            db 0xF1, '100 #Set S=Sp E=Eq ESC', 0
str_shelp:  db ' ', 18h,19h,1Bh,1Ah, 'Nav Spc=Tog A/N=All ESC', 0
str_nf:     db ' Character not found! Press key', 0
str_active: db '         Active', 0
str_none:   db '           None', 0
str_sp:     db 'SP:', 0
race_tbl:   db 'Human   Elf     Dwarf   Hobbit  '
            db 'Gnome   Ogre    Sprite  Imp     '
cls_tbl:    db 'Fighter WorshipMonk    Wizard  '
            db 'Priest  Sage    Mage    '
numbuf:     times 12 db 0
palette_buf: times 768 db 0
fpu_state:  times 94 db 0
;; ======================== INT 9 HANDLER ========================
new_int9:
    push ax
    in al, 60h
    cmp al, 0Fh
    jne .chain
    cmp byte [cs:busy], 0
    jne .chain
    in al, 61h
    or al, 80h
    out 61h, al
    and al, 7Fh
    out 61h, al
    mov al, 20h
    out 20h, al
    mov byte [cs:busy], 1
    pop ax
    pushf
    pusha
    push ds
    push es
    push cs
    pop ds
    sti
    call editor_main
    pop es
    pop ds
    popa
    popf
    mov byte [cs:busy], 0
    iret
.chain:
    pop ax
    jmp far [cs:old_int9]
;; ======================== EDITOR MAIN ==========================
editor_main:
    mov ah, 0Fh
    int 10h
    mov [vid_mode], al
    mov byte [is_vesa], 0
    mov ax, 4F03h
    int 10h
    cmp ax, 004Fh
    jne .no_vesa
    mov [vesa_mode], bx
    mov byte [is_vesa], 1
.no_vesa:
    call save_palette
    mov ax, 0003h
    int 10h
    mov ah, 01h
    mov cx, 2000h
    int 10h
    mov byte [input_mode], 0
    mov byte [input_len], 0
    call scan_memory
    jc .notfound
    fnsave [fpu_state]
    mov byte [page], 0
    mov byte [cur_sel], 0
    mov byte [scroll_top], 0
    call draw_stats_page
;; ======== MAIN INPUT LOOP ========
.iloop:
    xor ah, ah
    int 16h
    cmp byte [page], 1
    je .spell_keys
    cmp byte [page], 2
    je .equip_keys
    cmp byte [input_mode], 0
    jne .handle_input
    cmp ah, 01h
    je .quit
    cmp al, 's'
    je .goto_spells
    cmp al, 'S'
    je .goto_spells
    cmp al, 'e'
    je .goto_equip
    cmp al, 'E'
    je .goto_equip
    cmp ah, 48h
    je .up
    cmp ah, 50h
    je .down
    cmp ah, 4Dh
    je .inc1
    cmp ah, 4Bh
    je .dec1
    cmp ah, 49h
    je .inc100
    cmp ah, 51h
    je .dec100
    cmp al, '0'
    jb .iloop
    cmp al, '9'
    ja .iloop
    mov byte [input_mode], 1
    mov byte [input_len], 0
    jmp .add_digit
.handle_input:
    cmp ah, 01h
    je .cancel_input
    cmp ah, 1Ch
    je .commit_input
    cmp ah, 0Eh
    je .backspace
    cmp al, '0'
    jb .iloop
    cmp al, '9'
    ja .iloop
.add_digit:
    cmp byte [input_len], 10
    jae .iloop
    movzx bx, byte [input_len]
    mov [input_buf + bx], al
    inc byte [input_len]
    call draw_input_val
    jmp .iloop
.backspace:
    cmp byte [input_len], 0
    je .iloop
    dec byte [input_len]
    call draw_input_val
    jmp .iloop
.cancel_input:
    mov byte [input_mode], 0
    call draw_fields
    jmp .iloop
.commit_input:
    call parse_input
    call write_field
    mov byte [input_mode], 0
    call draw_fields
    jmp .iloop
.up:
    cmp byte [cur_sel], 0
    je .iloop
    dec byte [cur_sel]
    mov al, [cur_sel]
    cmp al, [scroll_top]
    jae .up_ok
    mov [scroll_top], al
.up_ok:
    call draw_fields
    jmp .iloop
.down:
    cmp byte [cur_sel], NFIELDS-1
    jae .iloop
    inc byte [cur_sel]
    mov al, [cur_sel]
    sub al, [scroll_top]
    cmp al, VIS_FIELDS
    jb .dn_ok
    mov al, [cur_sel]
    sub al, VIS_FIELDS - 1
    mov [scroll_top], al
.dn_ok:
    call draw_fields
    jmp .iloop
.inc1:
    mov cx, 1
    call modify_val
    call draw_fields
    jmp .iloop
.dec1:
    mov cx, -1
    call modify_val
    call draw_fields
    jmp .iloop
.inc100:
    mov cx, 100
    call modify_val
    call draw_fields
    jmp .iloop
.dec100:
    mov cx, -100
    call modify_val
    call draw_fields
    jmp .iloop
.goto_spells:
    mov byte [page], 1
    mov byte [spell_row], 0
    mov byte [spell_col], 0
    call draw_spell_page
    jmp .iloop
.goto_equip:
    mov byte [page], 2
    mov byte [equip_sel], 0
    call draw_equip_page
    jmp .iloop
;; ---- Equipment page keys ----
.equip_keys:
    cmp ah, 01h
    je .goto_stats
    cmp ah, 48h
    je .equip_up
    cmp ah, 50h
    je .equip_down
    cmp al, ' '
    je .equip_tog
    cmp ah, 4Dh
    je .equip_einc
    cmp ah, 4Bh
    je .equip_edec
    jmp .iloop
.equip_up:
    cmp byte [equip_sel], 0
    je .iloop
    dec byte [equip_sel]
    call draw_equip_items
    jmp .iloop
.equip_down:
    cmp byte [equip_sel], 15
    jae .iloop
    inc byte [equip_sel]
    call draw_equip_items
    jmp .iloop
.equip_tog:
    call do_equip_toggle
    call draw_equip_items
    jmp .iloop
.equip_einc:
    mov cx, 1
    call modify_equip_ench
    call draw_equip_items
    jmp .iloop
.equip_edec:
    mov cx, -1
    call modify_equip_ench
    call draw_equip_items
    jmp .iloop
;; ---- Spell page keys ----
.spell_keys:
    cmp ah, 01h
    je .goto_stats
    cmp al, 's'
    je .goto_stats
    cmp al, 'S'
    je .goto_stats
    cmp ah, 48h
    je .spell_up
    cmp ah, 50h
    je .spell_down
    cmp ah, 4Dh
    je .spell_right
    cmp ah, 4Bh
    je .spell_left
    cmp al, ' '
    je .spell_toggle
    cmp al, 'a'
    je .spell_all_on
    cmp al, 'A'
    je .spell_all_on
    cmp al, 'n'
    je .spell_all_off
    cmp al, 'N'
    je .spell_all_off
    jmp .iloop
.spell_up:
    cmp byte [spell_row], 0
    je .iloop
    dec byte [spell_row]
    call draw_spell_grid
    jmp .iloop
.spell_down:
    cmp byte [spell_row], 3
    jae .iloop
    inc byte [spell_row]
    call draw_spell_grid
    jmp .iloop
.spell_right:
    cmp byte [spell_col], 29
    jae .iloop
    inc byte [spell_col]
    call draw_spell_grid
    jmp .iloop
.spell_left:
    cmp byte [spell_col], 0
    je .iloop
    dec byte [spell_col]
    call draw_spell_grid
    jmp .iloop
.spell_toggle:
    call do_toggle_spell
    call draw_spell_grid
    jmp .iloop
.spell_all_on:
    call set_type_all
    call draw_spell_grid
    jmp .iloop
.spell_all_off:
    call clear_type_all
    call draw_spell_grid
    jmp .iloop
.goto_stats:
    mov byte [page], 0
    mov byte [input_mode], 0
    call draw_stats_page
    jmp .iloop
.notfound:
    mov dh, 12
    mov dl, 22
    mov bl, 0Ch
    mov si, str_nf
    call printat
    xor ah, ah
    int 16h
.quit:
    frstor [fpu_state]
    cmp byte [is_vesa], 0
    je .restore_std
    mov ax, 4F02h
    mov bx, [vesa_mode]
    and bx, 7FFFh
    int 10h
    jmp .mode_done
.restore_std:
    xor ah, ah
    mov al, [vid_mode]
    int 10h
.mode_done:
    call restore_palette
    ret
;; ======================== DRAW STATS PAGE ======================
draw_stats_page:
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov ax, 0720h
    mov cx, 2000
    rep stosw
    mov dh, BOX_T
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_title
    call printat
    call draw_namerow
    mov dh, BOX_T+2
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    call draw_fields
    mov dh, FIELD_ROW + VIS_FIELDS
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 1
    mov bl, 07h
    mov si, str_help
    call printat
    mov dh, FIELD_ROW + VIS_FIELDS + 1
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_bottom
    call printat
    ret
;; ======================== DRAW NAME ROW ========================
draw_namerow:
    mov dh, BOX_T+1
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 2
    push ds
    mov ds, [cs:data_seg]
    mov si, [cs:data_off]
    mov cx, 14
    mov bl, 0Fh
.pn:
    lodsb
    test al, al
    jz .pn_done
    call putch_adv
    loop .pn
.pn_done:
    pop ds
    push es
    mov es, [data_seg]
    mov bx, [data_off]
    movzx ax, byte [es:bx+28h]
    pop es
    mov dl, BOX_L + 18
    shl ax, 3
    mov si, race_tbl
    add si, ax
    mov bl, 0Eh
    mov cx, 8
.pr:
    lodsb
    call putch_adv
    loop .pr
    push es
    mov es, [data_seg]
    mov bx, [data_off]
    movzx ax, byte [es:bx+29h]
    pop es
    cmp al, 0
    jne .female
    mov al, 'M'
    jmp .psex
.female:
    mov al, 'F'
.psex:
    mov bl, 07h
    call putch_adv
    mov al, ' '
    call putch_adv
    push es
    mov es, [data_seg]
    mov bx, [data_off]
    movzx ax, byte [es:bx+2Ah]
    pop es
    shl ax, 3
    mov si, cls_tbl
    add si, ax
    mov bl, 0Eh
    mov cx, 8
.pc:
    lodsb
    call putch_adv
    loop .pc
    ret
;; ======================== DRAW FIELDS ==========================
draw_fields:
    pusha
    push es
    push ds
    push cs
    pop ds
    mov al, [scroll_top]
    mov [fld_idx], al
    mov byte [fld_vis], 0
.floop:
    cmp byte [fld_vis], VIS_FIELDS
    jae .fdone
    mov cl, [fld_idx]
    cmp cl, NFIELDS
    jae .fpad
    mov dh, FIELD_ROW
    add dh, [fld_vis]
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    push word 0B800h
    pop es
    movzx ax, dh
    imul ax, 80
    add ax, BOX_L + 1
    shl ax, 1
    mov di, ax
    mov ax, 0720h
    push cx
    mov cx, BOX_W - 2
    rep stosw
    pop cx
    mov cl, [fld_idx]
    mov dh, FIELD_ROW
    add dh, [fld_vis]
    mov dl, BOX_L + 1
    cmp cl, [cur_sel]
    jne .no_arrow
    mov al, 1Ah
    mov bl, 0Eh
    call putch_at
    jmp .do_name
.no_arrow:
    mov al, ' '
    mov bl, 07h
    call putch_at
.do_name:
    mov cl, [fld_idx]
    mov dl, NAME_COL
    movzx si, cl
    imul si, 14
    add si, fld_name
    cmp cl, [cur_sel]
    jne .nm_norm
    mov bl, 0Fh
    jmp .nm_pr
.nm_norm:
    mov bl, 07h
.nm_pr:
    push cx
    mov cx, 14
.nm_lp:
    lodsb
    call putch_adv
    loop .nm_lp
    pop cx
    cmp byte [fld_idx], RAISE_IDX
    je .raise_display
    movzx bx, byte [fld_idx]
    mov al, [fld_sz + bx]
    shl bx, 1
    mov di, [fld_off + bx]
    add di, [data_off]
    mov es, [data_seg]
    cmp al, 5
    je .read_flt
    cmp al, 4
    je .read32
    cmp al, 1
    je .read8
    mov ax, [es:di]
    xor dx, dx
    jmp .format_num
.read8:
    movzx ax, byte [es:di]
    xor dx, dx
    jmp .format_num
.read32:
    mov ax, [es:di]
    mov dx, [es:di+2]
    jmp .format_num
.read_flt:
    fld dword [es:di]
    fistp dword [sp_tmp]
    mov ax, [sp_tmp]
    mov dx, [sp_tmp+2]
.format_num:
    mov di, numbuf
    call u32_to_dec
    mov si, numbuf
    xor bx, bx
.slen:
    cmp byte [si+bx], 0
    je .slen_done
    inc bx
    jmp .slen
.slen_done:
    mov cl, [fld_idx]
    mov dh, FIELD_ROW
    add dh, [fld_vis]
    mov dl, VAL_COL
    sub dl, bl
    mov si, numbuf
    cmp cl, [cur_sel]
    jne .val_norm
    mov bl, 0Fh
    jmp .val_pr
.val_norm:
    mov bl, 0Ah
.val_pr:
    call printat
    jmp .next_field
.raise_display:
    mov di, [data_off]
    add di, 0x806
    mov es, [data_seg]
    mov ax, [es:di]
    mov cl, [fld_idx]
    mov dh, FIELD_ROW
    add dh, [fld_vis]
    mov dl, NAME_COL + 14
    cmp ax, 0FFFFh
    je .raise_none
    mov si, str_active
    jmp .raise_color
.raise_none:
    mov si, str_none
.raise_color:
    cmp cl, [cur_sel]
    jne .raise_dim
    mov bl, 0Fh
    jmp .raise_pr
.raise_dim:
    mov bl, 0Ah
.raise_pr:
    call printat
.next_field:
    inc byte [fld_idx]
    inc byte [fld_vis]
    jmp .floop
.fpad:
    mov dh, FIELD_ROW
    add dh, [fld_vis]
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    inc byte [fld_vis]
    inc byte [fld_idx]
    jmp .floop
.fdone:
    ;; Up arrow if scroll_top > 0
    mov dh, FIELD_ROW
    mov dl, BOX_L + BOX_W - 2
    cmp byte [scroll_top], 0
    je .no_up
    mov al, 18h
    mov bl, 0Eh
    call putch_at
    jmp .chk_dn
.no_up:
    mov al, ' '
    mov bl, 07h
    call putch_at
.chk_dn:
    ;; Down arrow if more fields below
    mov dh, FIELD_ROW + VIS_FIELDS - 1
    mov al, [scroll_top]
    add al, VIS_FIELDS
    cmp al, NFIELDS
    jae .no_dn
    mov al, 19h
    mov bl, 0Eh
    call putch_at
    jmp .arrows_done
.no_dn:
    mov al, ' '
    mov bl, 07h
    call putch_at
.arrows_done:
    pop ds
    pop es
    popa
    ret
;; ======================== DRAW SPELL PAGE ======================
draw_spell_page:
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov ax, 0720h
    mov cx, 2000
    rep stosw
    mov dh, 0
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_title
    call printat
    call draw_namerow
    mov dh, 2
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    ;; Row 3: SP display
    mov dh, 3
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 2
    mov bl, 0Eh
    mov si, str_sp
    call printat
    ;; SP Current
    mov di, [data_off]
    add di, 0x035
    mov es, [data_seg]
    fld dword [es:di]
    fistp dword [sp_tmp]
    mov ax, [sp_tmp]
    mov dx, [sp_tmp+2]
    mov di, numbuf
    call u32_to_dec
    mov dh, 3
    mov dl, BOX_L + 6
    mov bl, 0Fh
    mov si, numbuf
    call printat
    ;; Separator '/'
    mov si, numbuf
    xor bx, bx
.splen1:
    cmp byte [si+bx], 0
    je .splen1d
    inc bx
    jmp .splen1
.splen1d:
    mov dl, BOX_L + 6
    add dl, bl
    mov al, '/'
    mov bl, 07h
    call putch_at
    inc dl
    ;; SP Max
    push dx
    mov di, [data_off]
    add di, 0x039
    mov es, [data_seg]
    fld dword [es:di]
    fistp dword [sp_tmp]
    mov ax, [sp_tmp]
    mov dx, [sp_tmp+2]
    mov di, numbuf
    call u32_to_dec
    pop dx
    mov bl, 0Fh
    mov si, numbuf
    call printat
    ;; Row 4: separator
    mov dh, 4
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    ;; Rows 5-8: spell grid
    call draw_spell_grid
    ;; Row 9: separator
    mov dh, 9
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    ;; Row 10: help
    mov dh, 10
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 1
    mov bl, 07h
    mov si, str_shelp
    call printat
    ;; Row 11: bottom
    mov dh, 11
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_bottom
    call printat
    ret
;; ======================== DRAW SPELL GRID ======================
draw_spell_grid:
    pusha
    push es
    push ds
    push cs
    pop ds
    mov byte [fld_idx], 0
.grow:
    cmp byte [fld_idx], 4
    jae .gdone
    movzx ax, byte [fld_idx]
    mov dh, SPELL_ROW
    add dh, al
    ;; Left border
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    ;; Right border
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    ;; Clear interior
    push word 0B800h
    pop es
    movzx ax, dh
    imul ax, 80
    add ax, BOX_L + 1
    shl ax, 1
    mov di, ax
    mov ax, 0720h
    mov cx, BOX_W - 2
    rep stosw
    ;; Type label
    movzx bx, byte [fld_idx]
    mov dh, SPELL_ROW
    add dh, bl
    mov dl, BOX_L + 1
    mov al, [spell_lbl + bx]
    mov bl, 0Eh
    call putch_at
    ;; Draw 30 dots
    movzx si, byte [fld_idx]
    shl si, 1
    mov si, [spell_base + si]
    add si, [data_off]
    xor cx, cx
.dcol:
    cmp cx, 30
    jae .dnext_row
    ;; Screen column for this spell
    mov dl, SPELL_COL
    add dl, cl
    mov al, cl
    cmp al, 10
    jb .no_gap1
    inc dl
.no_gap1:
    cmp al, 20
    jb .no_gap2
    inc dl
.no_gap2:
    ;; Read flag
    push es
    mov es, [data_seg]
    mov bx, si
    add bx, cx
    mov al, [es:bx]
    pop es
    ;; Choose glyph and color
    test al, al
    jz .spell_off
    mov al, 0FEh
    mov bl, 0Ah
    jmp .spell_draw
.spell_off:
    mov al, 0FAh
    mov bl, 08h
.spell_draw:
    ;; Highlight if cursor is here
    push cx
    mov cl, [fld_idx]
    cmp cl, [spell_row]
    jne .no_hl
    pop cx
    push cx
    cmp cl, [spell_col]
    jne .no_hl
    mov bl, 0Fh
.no_hl:
    pop cx
    movzx bx, byte [fld_idx]
    mov dh, SPELL_ROW
    add dh, bl
    ;; Recalc color (bl got clobbered)
    push es
    mov es, [data_seg]
    push bx
    mov bx, si
    add bx, cx
    mov al, [es:bx]
    pop bx
    pop es
    test al, al
    jz .off2
    mov al, 0FEh
    mov bl, 0Ah
    jmp .hl2
.off2:
    mov al, 0FAh
    mov bl, 08h
.hl2:
    push cx
    mov cl, [fld_idx]
    cmp cl, [spell_row]
    jne .no_hl2
    pop cx
    push cx
    cmp cl, [spell_col]
    jne .no_hl2
    mov bl, 0Fh
.no_hl2:
    pop cx
    call putch_at
    inc cx
    jmp .dcol
.dnext_row:
    inc byte [fld_idx]
    jmp .grow
.gdone:
    pop ds
    pop es
    popa
    ret
;; ======================== SPELL TOGGLE =========================
do_toggle_spell:
    push es
    push bx
    push di
    movzx bx, byte [spell_row]
    shl bx, 1
    mov di, [spell_base + bx]
    movzx bx, byte [spell_col]
    add di, bx
    add di, [data_off]
    mov es, [data_seg]
    mov al, [es:di]
    test al, al
    jnz .clr
    mov byte [es:di], 1
    jmp .td
.clr:
    mov byte [es:di], 0
.td:
    pop di
    pop bx
    pop es
    ret
set_type_all:
    push es
    push bx
    push di
    push cx
    movzx bx, byte [spell_row]
    shl bx, 1
    mov di, [spell_base + bx]
    add di, [data_off]
    mov es, [data_seg]
    mov cx, 30
    xor bx, bx
.sa_lp:
    mov byte [es:di+bx], 1
    inc bx
    loop .sa_lp
    pop cx
    pop di
    pop bx
    pop es
    ret
clear_type_all:
    push es
    push bx
    push di
    push cx
    movzx bx, byte [spell_row]
    shl bx, 1
    mov di, [spell_base + bx]
    add di, [data_off]
    mov es, [data_seg]
    mov cx, 30
    xor bx, bx
.ca_lp:
    mov byte [es:di+bx], 0
    inc bx
    loop .ca_lp
    pop cx
    pop di
    pop bx
    pop es
    ret
;; ======================== DRAW EQUIP PAGE ======================
draw_equip_page:
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov ax, 0720h
    mov cx, 2000
    rep stosw
    mov dh, 0
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_title
    call printat
    call draw_namerow
    mov dh, 2
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    ;; Weapon header row 3
    mov dh, 3
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 1
    mov bl, 0Eh
    mov si, str_whdr
    call printat
    ;; Armor header row 12
    mov dh, 12
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 1
    mov bl, 0Eh
    mov si, str_ahdr
    call printat
    ;; Draw items
    call draw_equip_items
    ;; Separator row 21
    mov dh, 21
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_sep
    call printat
    ;; Help row 22
    mov dh, 22
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    mov dl, BOX_L + 1
    mov bl, 07h
    mov si, str_ehelp
    call printat
    ;; Bottom row 23
    mov dh, 23
    mov dl, BOX_L
    mov bl, 0Bh
    mov si, str_bottom
    call printat
    ret
;; ======================== DRAW EQUIP ITEMS =====================
draw_equip_items:
    pusha
    push es
    push ds
    push cs
    pop ds
    mov byte [fld_idx], 0
.ei_loop:
    cmp byte [fld_idx], 16
    jae .ei_done
    ;; Calculate screen row
    movzx ax, byte [fld_idx]
    cmp al, 8
    jb .ei_wrow
    add al, 5
    jmp .ei_setrow
.ei_wrow:
    add al, 4
.ei_setrow:
    mov dh, al
    ;; Draw borders
    mov dl, BOX_L
    mov al, 0BAh
    mov bl, 0Bh
    call putch_at
    mov dl, BOX_L + BOX_W - 1
    call putch_at
    ;; Clear interior
    push word 0B800h
    pop es
    movzx ax, dh
    imul ax, 80
    add ax, BOX_L + 1
    shl ax, 1
    mov di, ax
    mov ax, 0720h
    mov cx, BOX_W - 2
    rep stosw
    ;; Arrow if selected
    mov dl, BOX_L + 1
    mov al, [fld_idx]
    cmp al, [equip_sel]
    jne .ei_no_arr
    mov al, 1Ah
    mov bl, 0Eh
    call putch_at
    jmp .ei_name
.ei_no_arr:
    mov al, ' '
    mov bl, 07h
    call putch_at
.ei_name:
    ;; Selection color
    mov al, [fld_idx]
    cmp al, [equip_sel]
    jne .ei_dim
    mov bl, 0Fh
    jmp .ei_slot
.ei_dim:
    mov bl, 07h
.ei_slot:
    ;; Slot number (1-8)
    mov dl, EQ_NAME_COL
    movzx ax, byte [fld_idx]
    cmp al, 8
    jb .ei_sn
    sub al, 8
.ei_sn:
    add al, '1'
    call putch_at
    inc dl
    mov al, '.'
    call putch_at
    inc dl
    ;; Name (12 chars)
    push bx
    movzx si, byte [fld_idx]
    cmp si, 8
    jb .ei_wn
    sub si, 8
    imul si, 12
    add si, arm_name
    jmp .ei_pn
.ei_wn:
    imul si, 12
    add si, wep_name
.ei_pn:
    pop bx
    mov cx, 12
.ei_nlp:
    lodsb
    call putch_at
    inc dl
    loop .ei_nlp
    ;; OWN flag
    mov dl, EQ_OWN_COL
    movzx bx, byte [fld_idx]
    cmp bl, 8
    jb .ei_wo
    sub bl, 8
    add bx, EQ_ARM_OWN
    jmp .ei_ro
.ei_wo:
    add bx, EQ_WEP_OWN
.ei_ro:
    add bx, [data_off]
    push es
    mov es, [data_seg]
    mov al, [es:bx]
    pop es
    test al, al
    jz .ei_own_n
    mov al, 'Y'
    mov bl, 0Ah
    jmp .ei_own_c
.ei_own_n:
    mov al, 'N'
    mov bl, 08h
.ei_own_c:
    push ax
    mov al, [fld_idx]
    cmp al, [equip_sel]
    pop ax
    jne .ei_own_d
    mov bl, 0Fh
.ei_own_d:
    call putch_at
    ;; Enchant level
    movzx bx, byte [fld_idx]
    cmp bl, 8
    jb .ei_we
    sub bl, 8
    add bx, EQ_ARM_ENCH
    jmp .ei_re
.ei_we:
    add bx, EQ_WEP_ENCH
.ei_re:
    add bx, [data_off]
    push es
    mov es, [data_seg]
    movzx ax, byte [es:bx]
    pop es
    push dx
    xor dx, dx
    mov di, numbuf
    call u32_to_dec
    pop dx
    ;; Right-align the number
    mov si, numbuf
    xor bx, bx
.ei_elen:
    cmp byte [si+bx], 0
    je .ei_elen_d
    inc bx
    jmp .ei_elen
.ei_elen_d:
    mov dl, EQ_ENCH_END
    sub dl, bl
    mov si, numbuf
    mov al, [fld_idx]
    cmp al, [equip_sel]
    jne .ei_ed
    mov bl, 0Fh
    jmp .ei_ep
.ei_ed:
    mov bl, 0Ah
.ei_ep:
    call printat
    ;; Next item
    inc byte [fld_idx]
    jmp .ei_loop
.ei_done:
    pop ds
    pop es
    popa
    ret
;; ======================== EQUIP TOGGLE/MODIFY ==================
do_equip_toggle:
    push es
    push bx
    movzx bx, byte [equip_sel]
    cmp bl, 8
    jb .et_wep
    sub bl, 8
    add bx, EQ_ARM_OWN
    jmp .et_do
.et_wep:
    add bx, EQ_WEP_OWN
.et_do:
    add bx, [data_off]
    mov es, [data_seg]
    mov al, [es:bx]
    test al, al
    jnz .et_off
    mov byte [es:bx], 1
    jmp .et_done
.et_off:
    mov byte [es:bx], 0
.et_done:
    pop bx
    pop es
    ret
modify_equip_ench:
    push es
    push bx
    push ax
    movzx bx, byte [equip_sel]
    cmp bl, 8
    jb .me_wep
    sub bl, 8
    add bx, EQ_ARM_ENCH
    jmp .me_do
.me_wep:
    add bx, EQ_WEP_ENCH
.me_do:
    add bx, [data_off]
    mov es, [data_seg]
    movzx ax, byte [es:bx]
    add ax, cx
    test ax, ax
    js .me_clamp0
    cmp ax, 255
    ja .me_clamp_hi
    jmp .me_write
.me_clamp0:
    xor ax, ax
    jmp .me_write
.me_clamp_hi:
    mov ax, 255
.me_write:
    mov [es:bx], al
    pop ax
    pop bx
    pop es
    ret
;; ======================== MEMORY SCANNER =======================
scan_memory:
    push es
    push di
    push bx
    mov ax, 0060h
    mov es, ax
    xor di, di
.sloop:
    mov al, [es:di]
    cmp al, 'A'
    jb .snext
    cmp al, 'Z'
    jbe .name_ok
    cmp al, 'a'
    jb .snext
    cmp al, 'z'
    ja .snext
.name_ok:
    xor cx, cx
    mov bx, 1
.nchk:
    mov al, [es:di+bx]
    test al, al
    jz .nfound_null
    cmp al, 20h
    jb .snext
    cmp al, 7Eh
    ja .snext
    jmp .nchk_next
.nfound_null:
    mov cx, 1
.nchk_next:
    inc bx
    cmp bx, 10
    jb .nchk
    test cx, cx
    jnz .name_valid
.null_scan:
    cmp bx, 20
    jae .snext
    cmp byte [es:di+bx], 0
    je .name_valid
    inc bx
    jmp .null_scan
.name_valid:
    mov bx, 1
.find_null:
    cmp bx, 28h
    jae .padding_ok
    cmp byte [es:di+bx], 0
    je .null_found
    inc bx
    jmp .find_null
.null_found:
.pad_chk:
    inc bx
    cmp bx, 28h
    jae .padding_ok
    cmp byte [es:di+bx], 0
    jne .snext
    jmp .pad_chk
.padding_ok:
    mov al, [es:di+28h]
    cmp al, 8
    jae .snext
    mov al, [es:di+29h]
    cmp al, 2
    jae .snext
    mov al, [es:di+2Ah]
    cmp al, 7
    jae .snext
    cmp byte [es:di+2Bh], 0
    jne .snext
    mov ax, di
    add ax, 81Ch
    jc .snext
    mov bx, di
    add bx, 33h
    mov ax, [es:bx]
    test ax, ax
    jz .snext
    mov bx, di
    add bx, 812h
    mov ax, [es:bx]
    test ax, ax
    jz .snext
    cmp ax, 19999
    ja .snext
    mov ax, [es:bx+2]
    test ax, ax
    jz .snext
    cmp ax, 19999
    ja .snext
    mov ax, [es:bx+4]
    test ax, ax
    jz .snext
    cmp ax, 19999
    ja .snext
    mov ax, [es:bx+6]
    test ax, ax
    jz .snext
    cmp ax, 19999
    ja .snext
    mov ax, di
    mov cl, 4
    shr ax, cl
    mov bx, es
    add bx, ax
    mov [cs:data_seg], bx
    and di, 0Fh
    mov [cs:data_off], di
    pop bx
    pop di
    pop es
    clc
    ret
.snext:
    inc di
    cmp di, 0F600h
    jb .sloop
    mov ax, es
    add ax, 0F60h
    mov es, ax
    xor di, di
    cmp ax, 0A000h
    jb .sloop
    pop bx
    pop di
    pop es
    stc
    ret
;; ======================== MODIFY VALUE =========================
modify_val:
    push es
    push di
    push ax
    push bx
    push dx
    cmp byte [cur_sel], RAISE_IDX
    jne .normal_modify
    movzx bx, byte [cur_sel]
    shl bx, 1
    mov di, [fld_off + bx]
    add di, [data_off]
    mov es, [data_seg]
    mov ax, [es:di]
    cmp ax, 0FFFFh
    je .set_active
    mov ax, 0FFFFh
    jmp .write_raise
.set_active:
    mov ax, 1
.write_raise:
    mov [es:di], ax
    jmp .moddone
.normal_modify:
    movzx bx, byte [cur_sel]
    mov al, [fld_sz + bx]
    shl bx, 1
    mov di, [fld_off + bx]
    add di, [data_off]
    mov es, [data_seg]
    cmp al, 5
    je .mod_flt
    cmp al, 4
    je .mod32
    cmp al, 1
    je .mod8
    mov ax, [es:di]
    mov dx, ax
    add ax, cx
    test cx, 8000h
    jz .chk_ovf16
    cmp ax, dx
    ja .clamp_zero16
    jmp .chk_cap16
.chk_ovf16:
    cmp ax, dx
    jb .clamp_max16
.chk_cap16:
    cmp ax, 7FFFh
    ja .clamp_max16
.write16:
    mov [es:di], ax
    jmp .moddone
.clamp_zero16:
    xor ax, ax
    jmp .write16
.clamp_max16:
    mov ax, 7FFFh
    jmp .write16
.mod8:
    movzx ax, byte [es:di]
    add ax, cx
    test ax, ax
    js .clamp_zero8
    cmp ax, 255
    ja .clamp_max8
.write8:
    mov [es:di], al
    jmp .moddone
.clamp_zero8:
    xor al, al
    jmp .write8
.clamp_max8:
    mov al, 0FFh
    jmp .write8
.mod32:
    mov ax, [es:di]
    mov dx, [es:di+2]
    push ax
    push dx
    mov bx, cx
    test cx, 8000h
    jz .pos_delta
    add ax, cx
    adc dx, 0FFFFh
    jmp .chk32
.pos_delta:
    add ax, cx
    adc dx, 0
.chk32:
    test bx, 8000h
    jz .write32
    test dx, 8000h
    jnz .clamp_zero32
    jmp .write32
.clamp_zero32:
    xor ax, ax
    xor dx, dx
.write32:
    pop bx
    pop bx
    mov [es:di], ax
    mov [es:di+2], dx
    jmp .moddone
.mod_flt:
    fld dword [es:di]
    fistp dword [sp_tmp]
    mov ax, [sp_tmp]
    mov dx, [sp_tmp+2]
    push ax
    push dx
    mov bx, cx
    test cx, 8000h
    jz .flt_pos
    add ax, cx
    adc dx, 0FFFFh
    jmp .flt_chk
.flt_pos:
    add ax, cx
    adc dx, 0
.flt_chk:
    test bx, 8000h
    jz .flt_write
    test dx, 8000h
    jnz .flt_clamp0
    jmp .flt_write
.flt_clamp0:
    xor ax, ax
    xor dx, dx
.flt_write:
    pop bx
    pop bx
    mov [sp_tmp], ax
    mov [sp_tmp+2], dx
    fild dword [sp_tmp]
    fstp dword [es:di]
.moddone:
    pop dx
    pop bx
    pop ax
    pop di
    pop es
    ret
;; ======================== U32 TO DECIMAL =======================
u32_to_dec:
    push bx
    push cx
    push si
    mov si, di
    mov bx, 10
    xor cx, cx
.dloop:
    push ax
    mov ax, dx
    xor dx, dx
    div bx
    mov [cs:numbuf+10], ax
    pop ax
    div bx
    push dx
    inc cx
    mov dx, [cs:numbuf+10]
    test ax, ax
    jnz .dloop
    test dx, dx
    jnz .dloop
    mov di, si
.dpop:
    pop ax
    add al, '0'
    mov [di], al
    inc di
    loop .dpop
    mov byte [di], 0
    pop si
    pop cx
    pop bx
    ret
;; ======================== PALETTE SAVE/RESTORE =================
save_palette:
    push es
    push di
    push cx
    push dx
    push cs
    pop es
    mov di, palette_buf
    mov dx, 3C7h
    xor al, al
    out dx, al
    mov dx, 3C9h
    mov cx, 768
.sp_loop:
    in al, dx
    stosb
    loop .sp_loop
    pop dx
    pop cx
    pop di
    pop es
    ret
restore_palette:
    push si
    push cx
    push dx
    mov si, palette_buf
    mov dx, 3C8h
    xor al, al
    out dx, al
    mov dx, 3C9h
    mov cx, 768
.rp_loop:
    lodsb
    out dx, al
    loop .rp_loop
    pop dx
    pop cx
    pop si
    ret
;; ======================== INPUT HELPERS ========================
parse_input:
    push bx
    push cx
    push si
    xor dx, dx
    xor ax, ax
    movzx cx, byte [input_len]
    test cx, cx
    jz .pi_done
    mov si, input_buf
.pi_loop:
    push cx
    mov bx, 10
    push dx
    mul bx
    mov cx, dx
    pop dx
    push ax
    mov ax, dx
    mul bx
    add ax, cx
    mov dx, ax
    pop ax
    movzx bx, byte [si]
    sub bl, '0'
    add ax, bx
    adc dx, 0
    inc si
    pop cx
    loop .pi_loop
.pi_done:
    pop si
    pop cx
    pop bx
    ret
write_field:
    push es
    push di
    push bx
    push cx
    movzx bx, byte [cur_sel]
    mov cl, [fld_sz + bx]
    shl bx, 1
    mov di, [fld_off + bx]
    add di, [data_off]
    mov es, [data_seg]
    cmp cl, 5
    je .wf_flt
    cmp cl, 4
    je .wf32
    cmp cl, 1
    je .wf8
    mov [es:di], ax
    jmp .wf_done
.wf8:
    mov [es:di], al
    jmp .wf_done
.wf32:
    mov [es:di], ax
    mov [es:di+2], dx
    jmp .wf_done
.wf_flt:
    mov [sp_tmp], ax
    mov [sp_tmp+2], dx
    fild dword [sp_tmp]
    fstp dword [es:di]
.wf_done:
    pop cx
    pop bx
    pop di
    pop es
    ret
draw_input_val:
    pusha
    push es
    mov cl, [cur_sel]
    mov al, cl
    sub al, [scroll_top]
    mov dh, FIELD_ROW
    add dh, al
    mov ax, 0B800h
    mov es, ax
    movzx ax, dh
    imul ax, 80
    add ax, NAME_COL + 14
    shl ax, 1
    mov di, ax
    mov ax, 0E20h
    mov cx, VAL_COL - NAME_COL - 14 + 6
    rep stosw
    movzx bx, byte [input_len]
    test bx, bx
    jz .di_done
    mov byte [input_buf + bx], 0
    mov dl, VAL_COL
    sub dl, bl
    mov si, input_buf
    mov bl, 0Eh
    call printat
.di_done:
    pop es
    popa
    ret
;; ======================== PRINT HELPERS ========================
printat:
    push es
    push di
    push ax
    mov ax, 0B800h
    mov es, ax
    call calc_vpos
.ploop:
    lodsb
    test al, al
    jz .pdone
    mov [es:di], al
    mov [es:di+1], bl
    add di, 2
    inc dl
    jmp .ploop
.pdone:
    pop ax
    pop di
    pop es
    ret
putch_at:
    push es
    push di
    push ax
    push ax
    mov ax, 0B800h
    mov es, ax
    call calc_vpos
    pop ax
    mov [es:di], al
    mov [es:di+1], bl
    pop ax
    pop di
    pop es
    ret
putch_adv:
    call putch_at
    inc dl
    ret
calc_vpos:
    push ax
    push dx
    movzx ax, dh
    imul ax, 160
    movzx di, dl
    shl di, 1
    add di, ax
    pop dx
    pop ax
    ret
;; ======================== INSTALL CODE =========================
install:
    mov ah, 09h
    mov dx, banner
    int 21h
    mov ax, 3509h
    int 21h
    mov [old_int9], bx
    mov [old_int9+2], es
    mov ax, 2509h
    mov dx, new_int9
    int 21h
    mov ax, 3100h
    mov dx, (install - $$ + 0x100 + 15) >> 4
    int 21h
banner: db 'Moraff Trainer loaded! Press TAB in-game.', 0Dh, 0Ah
        db '  S=Spells E=Equipment A/N=all on/off', 0Dh, 0Ah, '$'
