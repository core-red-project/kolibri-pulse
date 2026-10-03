; ==============================================================================
; KolibriPulse - Real-time System Monitor for KolibriOS
; Compact, Precise, Essential.
; ==============================================================================

format binary as ""
use32
org 0x0

; --- Included Definitions & Subsystems (Macros & Config) ---
include 'kolibri.inc'
include 'config.inc'

; --- Application Header ---
app_header START, I_END, MEM_SIZE, STACK_TOP

START:
    ; 1. Set event mask: Redraw (1), Keys (2), Buttons (4)
    mcall 40, 0x07

    ; 2. Clear sparkline history buffer
    mov edi, spark_history
    mov ecx, SPARK_HISTORY_LEN
    xor al, al
    rep stosb

    ; 3. Initial system metrics collection
    call collect_system_metrics

    ; 4. Initial window redraw
    call redraw_window

; ------------------------------------------------------------------------------
; Main Event Loop (Syscall 23 with timeout for non-blocking periodic refresh)
; ------------------------------------------------------------------------------
event_loop:
    ; Wait for event with timeout of REFRESH_INTERVAL (100cs = 1s)
    mcall 23, REFRESH_INTERVAL

    test eax, eax
    jz .on_timeout                  ; EAX == 0: Timer expired -> refresh metrics
    cmp eax, EV_REDRAW
    je .on_redraw                   ; EAX == 1: Window needs full redraw
    cmp eax, EV_KEY
    je .on_key                      ; EAX == 2: Keyboard press
    cmp eax, EV_BUTTON
    je .on_button                   ; EAX == 3: Button click (Close button)

    jmp event_loop

.on_timeout:
    ; Periodic update: sample new data and redraw dynamic canvas
    call collect_system_metrics
    call draw_ui
    jmp event_loop

.on_redraw:
    call redraw_window
    jmp event_loop

.on_key:
    ; Read ASCII key code
    mcall 2
    shr eax, 8                      ; AL = ASCII character
    cmp al, 'q'
    je .terminate
    cmp al, 'Q'
    je .terminate
    cmp al, 27                      ; ESC key
    je .terminate
    jmp event_loop

.on_button:
    ; Get pressed button ID
    mcall 17
    shr eax, 8                      ; AL = Button ID
    cmp al, 1                       ; ID 1 is the standard window close button
    je .terminate
    jmp event_loop

.terminate:
    ; Exit process cleanly (Syscall -1)
    mcall -1

; ------------------------------------------------------------------------------
; Window Redraw Procedure
; ------------------------------------------------------------------------------
redraw_window:
    pushad

    ; Begin Redraw (Syscall 12, subfunction 1)
    mcall 12, 1

    ; Create/Update Window (Syscall 0)
    ; EBX: (X shl 16) + Width
    ; ECX: (Y shl 16) + Height
    ; EDX: Style + Body color
    ; ESI: Title color (ignored when skinned)
    ; EDI: Title string pointer
    mcall 0, (WIN_POS_X shl 16) + WIN_WIDTH, (WIN_POS_Y shl 16) + WIN_HEIGHT, WS_SKINNED_FIXED or COL_BG, 0, str_win_title

    ; Render UI components inside client area
    call draw_ui

    ; End Redraw (Syscall 12, subfunction 2)
    mcall 12, 2

    popad
    ret

; --- Modular Subroutines ---
include 'sysinfo.asm'
include 'ui.asm'

; ==============================================================================
; Data Section (Initialized)
; ==============================================================================
str_win_title       db 'KolibriPulse', 0

str_title           db 'KOLIBRI PULSE', 0
str_title_len       = $ - str_title - 1

str_ver             db 'v1.0', 0
str_ver_len         = $ - str_ver - 1

str_mhz             db 'MHz', 0
str_mhz_len         = $ - str_mhz - 1

str_cpu_lbl         db 'CPU USAGE', 0
str_cpu_lbl_len     = $ - str_cpu_lbl - 1

str_ram_lbl         db 'MEMORY (RAM)', 0
str_ram_lbl_len     = $ - str_ram_lbl - 1

str_threads_lbl     db 'THREADS:', 0
str_threads_lbl_len = $ - str_threads_lbl - 1

str_uptime_lbl      db 'UPTIME:', 0
str_uptime_lbl_len  = $ - str_uptime_lbl - 1

str_percent         db '%', 0
str_percent_len     = 1

str_slash           db ' / ', 0
str_slash_len       = 3

str_mb              db ' MB', 0
str_mb_len          = 3

str_open_paren      db '(', 0
str_close_paren     db '%)', 0

uptime_str          db '00:00:00', 0

; ==============================================================================
; BSS Section (Uninitialized Data & Buffers)
; ==============================================================================
align 4

cpu_percent         dd 0
cpu_freq_mhz        dd 0

ram_total_kb        dd 0
ram_free_kb         dd 0
ram_total_mb        dd 0
ram_free_mb         dd 0
ram_used_mb         dd 0
ram_percent         dd 0

active_threads      dd 0

uptime_total_sec    dd 0
uptime_hours        dd 0
uptime_mins         dd 0
uptime_secs         dd 0

spark_history       rb SPARK_HISTORY_LEN
proc_info_buf       rb 1024

; End of initialized code and data
I_END:

; Stack Space (4 KB)
align 16
rb 4096
STACK_TOP:

; Total allocated runtime memory
MEM_SIZE:
