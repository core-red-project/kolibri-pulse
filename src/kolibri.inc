; ==============================================================================
; KolibriOS Core Definitions & System Calls Macros
; ==============================================================================

; --- Application Header Structure (MENUET01) ---
macro app_header entry, img_end, mem_size, stack_ptr {
    db 'MENUET01'           ; 8-byte signature
    dd 0x01                 ; Header version
    dd entry                ; Entry point
    dd img_end              ; Binary image end address
    dd mem_size             ; Total memory required (BSS + heap)
    dd stack_ptr            ; Top of stack
    dd 0                    ; Execution arguments buffer pointer
    dd 0                    ; Reserved / Path pointer
}

; --- System Call Invocation Macro (int 0x40) ---
macro mcall a, b, c, d, e, f {
    if ~ a eq
        mov eax, a
    end if
    if ~ b eq
        mov ebx, b
    end if
    if ~ c eq
        mov ecx, c
    end if
    if ~ d eq
        mov edx, d
    end if
    if ~ e eq
        mov esi, e
    end if
    if ~ f eq
        mov edi, f
    end if
    int 0x40
}

; --- Event Codes ---
EV_NONE         equ 0
EV_REDRAW       equ 1
EV_KEY          equ 2
EV_BUTTON       equ 3

; --- Window Styles ---
WS_SKINNED_FIXED equ 0x34000000     ; Skinned window with fixed coordinates
WS_COORD_CLIENT  equ 0x20000000     ; Coordinates are client area
WS_CAPTION       equ 0x04000000     ; Draw window caption/title
