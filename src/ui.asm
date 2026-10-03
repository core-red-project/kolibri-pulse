; ==============================================================================
; KolibriPulse - User Interface & Rendering Engine
; ==============================================================================

; --- Helper: Draw Filled Rectangle ---
; In: EBX = (X shl 16) + Width
;     ECX = (Y shl 16) + Height
;     EDX = Color
macro draw_rect x, y, w, h, col {
    mov ebx, (x shl 16) + (w)
    mov ecx, (y shl 16) + (h)
    mov edx, col
    mov eax, 13
    int 0x40
}

; --- Helper: Draw Text ---
; In: x, y, col, str_ptr, str_len
macro draw_label x, y, col, str_ptr, str_len {
    mov ebx, (x shl 16) + (y)
    mov ecx, col
    mov edx, str_ptr
    mov esi, str_len
    mov eax, 4
    int 0x40
}

; --- Helper: Draw Number (Syscall 47) ---
; In: x, y, col, val, digits
macro draw_num x, y, col, val, digits {
    mov ebx, (0 shl 16) + (digits)    ; Decimal, left aligned
    mov ecx, val
    mov edx, (x shl 16) + (y)
    mov esi, col
    mov eax, 47
    int 0x40
}

; ------------------------------------------------------------------------------
; Full Redraw Routine
; ------------------------------------------------------------------------------
draw_ui:
    pushad

    ; 1. Redraw Base Panels & Background
    call draw_background_panels

    ; 2. Header: Logo, Version, Frequency
    call draw_header

    ; 3. CPU Section: Value, Progress Bar, Sparkline
    call draw_cpu_section

    ; 4. RAM Section: Value, Usage Bar
    call draw_ram_section

    ; 5. Footer: Threads & Uptime
    call draw_footer

    popad
    ret

; ------------------------------------------------------------------------------
; Background & Panel Cards
; ------------------------------------------------------------------------------
draw_background_panels:
    ; Main Window Canvas Background
    draw_rect 0, 0, WIN_WIDTH, WIN_HEIGHT, COL_BG

    ; Header Banner
    draw_rect 0, 0, WIN_WIDTH, 26, COL_HEADER_BG
    draw_rect 0, 26, WIN_WIDTH, 1, COL_PANEL_EDGE

    ; CPU Card (Y: 34, H: 100)
    draw_rect 10, 32, 300, 100, COL_PANEL
    draw_rect 10, 32, 300, 1, COL_PANEL_EDGE
    draw_rect 10, 131, 300, 1, COL_PANEL_EDGE

    ; RAM Card (Y: 138, H: 48)
    draw_rect 10, 138, 300, 48, COL_PANEL
    draw_rect 10, 138, 300, 1, COL_PANEL_EDGE
    draw_rect 10, 185, 300, 1, COL_PANEL_EDGE

    ; Footer Card (Y: 192, H: 26)
    draw_rect 10, 192, 300, 26, COL_PANEL
    draw_rect 10, 192, 300, 1, COL_PANEL_EDGE
    draw_rect 10, 217, 300, 1, COL_PANEL_EDGE

    ret

; ------------------------------------------------------------------------------
; Header Section
; ------------------------------------------------------------------------------
draw_header:
    ; Glowing Indicator Dot
    draw_rect 12, 10, 6, 6, COL_TEXT_TITLE

    ; Title: "KOLIBRI PULSE"
    draw_label 24, 9, COL_TEXT_TITLE, str_title, str_title_len

    ; Version tag "v1.0"
    draw_label 125, 9, COL_TEXT_MUTED, str_ver, str_ver_len

    ; CPU Frequency on right side (e.g., "3200 MHz")
    mov eax, [cpu_freq_mhz]
    draw_num 222, 9, COL_TEXT_MAIN, eax, 5
    draw_label 258, 9, COL_TEXT_MUTED, str_mhz, str_mhz_len

    ret

; ------------------------------------------------------------------------------
; CPU Metric Section
; ------------------------------------------------------------------------------
draw_cpu_section:
    ; Label "CPU ACTIVITY"
    draw_label 18, 40, COL_TEXT_MUTED, str_cpu_lbl, str_cpu_lbl_len

    ; CPU Percentage Value "XXX %"
    mov eax, [cpu_percent]
    draw_num 248, 40, COL_TEXT_MAIN, eax, 3
    draw_label 272, 40, COL_TEXT_MUTED, str_percent, str_percent_len

    ; --- CPU Gauge Bar ---
    ; Bar Track Background
    draw_rect 18, 54, 284, 8, COL_BAR_BG

    ; Calculate Fill Width: (284 * cpu_pct) / 100
    mov eax, [cpu_percent]
    imul eax, 284
    mov ecx, 100
    xor edx, edx
    div ecx
    test eax, eax
    jz .skip_cpu_fill

    ; Dynamic Color Based on Load
    mov edx, COL_CPU_BAR
    cmp dword [cpu_percent], 70
    jb .apply_cpu_col
    mov edx, COL_CPU_WARN
    cmp dword [cpu_percent], 85
    jb .apply_cpu_col
    mov edx, COL_CPU_CRIT

.apply_cpu_col:
    push edx
    ; Draw Fill
    mov ebx, (18 shl 16)
    add ebx, eax                    ; Width
    mov ecx, (54 shl 16) + 8         ; Height 8
    pop edx                         ; Color
    mov eax, 13
    int 0x40

.skip_cpu_fill:
    ; --- Rolling Sparkline Graph ---
    ; Sparkline area: X=18, Y=70, W=284, H=52
    draw_rect SPARK_X, 70, SPARK_W, 52, COL_BAR_BG

    ; Grid Lines (25%, 50%, 75%)
    draw_rect SPARK_X, 83, SPARK_W, 1, COL_SPARK_GRID
    draw_rect SPARK_X, 96, SPARK_W, 1, COL_SPARK_GRID
    draw_rect SPARK_X, 109, SPARK_W, 1, COL_SPARK_GRID

    ; Render History Bars (SPARK_HISTORY_LEN = 40 samples)
    ; Bar width = 6 px, spacing = 1 px -> (6+1)*40 = 280 px fits nicely
    xor esi, esi                    ; Index 0..39
.draw_spark_loop:
    movzx eax, byte [spark_history + esi]
    test eax, eax
    jz .spark_next

    ; Bar height = (50 * load) / 100
    imul eax, 48
    mov ecx, 100
    xor edx, edx
    div ecx
    test eax, eax
    jnz .h_ok
    mov eax, 1                      ; Minimum 1 px height
.h_ok:
    ; Y start = (Bottom Y: 121) - height
    mov ecx, 121
    sub ecx, eax                    ; ECX = Y_pos
    push eax                        ; Save height

    ; X pos = SPARK_X + 2 + (esi * 7)
    mov ebx, esi
    imul ebx, 7
    add ebx, SPARK_X + 2

    ; Pack EBX: (X shl 16) + Width (5)
    shl ebx, 16
    add ebx, 5

    ; Pack ECX: (Y shl 16) + Height
    shl ecx, 16
    pop eax                         ; Restore height
    add ecx, eax

    ; Color based on sample value
    movzx eax, byte [spark_history + esi]
    mov edx, COL_CPU_BAR
    cmp eax, 70
    jb .spark_draw
    mov edx, COL_CPU_WARN
    cmp eax, 85
    jb .spark_draw
    mov edx, COL_CPU_CRIT

.spark_draw:
    mov eax, 13
    int 0x40

.spark_next:
    inc esi
    cmp esi, SPARK_HISTORY_LEN
    jb .draw_spark_loop

    ret

; ------------------------------------------------------------------------------
; RAM Metric Section
; ------------------------------------------------------------------------------
draw_ram_section:
    ; Label "MEMORY (RAM)"
    draw_label 18, 145, COL_TEXT_MUTED, str_ram_lbl, str_ram_lbl_len

    ; Readout: Used MB
    mov eax, [ram_used_mb]
    draw_num 140, 145, COL_TEXT_MAIN, eax, 5
    draw_label 176, 145, COL_TEXT_MUTED, str_slash, str_slash_len

    ; Readout: Total MB
    mov eax, [ram_total_mb]
    draw_num 186, 145, COL_TEXT_MAIN, eax, 5
    draw_label 222, 145, COL_TEXT_MUTED, str_mb, str_mb_len

    ; Percentage "(XX%)"
    draw_label 250, 145, COL_TEXT_MUTED, str_open_paren, 1
    mov eax, [ram_percent]
    draw_num 256, 145, COL_RAM_BAR, eax, 3
    draw_label 278, 145, COL_TEXT_MUTED, str_close_paren, 2

    ; RAM Progress Bar Track
    draw_rect 18, 162, 284, 10, COL_BAR_BG

    ; Calculate Fill Width: (284 * ram_percent) / 100
    mov eax, [ram_percent]
    imul eax, 284
    mov ecx, 100
    xor edx, edx
    div ecx
    test eax, eax
    jz .skip_ram_fill

    ; Draw RAM Bar
    mov ebx, (18 shl 16)
    add ebx, eax                    ; Width
    mov ecx, (162 shl 16) + 10       ; Height 10
    mov edx, COL_RAM_BAR
    mov eax, 13
    int 0x40

.skip_ram_fill:
    ret

; ------------------------------------------------------------------------------
; Footer Section (Threads & Uptime)
; ------------------------------------------------------------------------------
draw_footer:
    ; Left side: "THREADS:"
    draw_label 18, 201, COL_TEXT_MUTED, str_threads_lbl, str_threads_lbl_len
    mov eax, [active_threads]
    draw_num 76, 201, COL_TEXT_MAIN, eax, 4

    ; Divider dot
    draw_rect 120, 204, 3, 3, COL_TEXT_DARK

    ; Right side: "UPTIME:"
    draw_label 140, 201, COL_TEXT_MUTED, str_uptime_lbl, str_uptime_lbl_len
    draw_label 192, 201, COL_TEXT_MAIN, uptime_str, 8

    ret
