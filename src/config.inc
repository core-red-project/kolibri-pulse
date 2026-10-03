; ==============================================================================
; KolibriPulse - Configuration & Visual Theme
; ==============================================================================

; --- Window Dimensions ---
WIN_POS_X       equ 150
WIN_POS_Y       equ 120
WIN_WIDTH       equ 320
WIN_HEIGHT      equ 235

; --- Theme Colors (Hex 0x00RRGGBB) ---
COL_BG          equ 0x14161B    ; Deep carbon / slate background
COL_PANEL       equ 0x1C1F26    ; Card background
COL_PANEL_EDGE  equ 0x282C37    ; Card border / separator line
COL_HEADER_BG   equ 0x181B22    ; Subtle header banner

; Text Colors
COL_TEXT_TITLE  equ 0x00E5FF    ; Neon cyan brand title
COL_TEXT_MAIN   equ 0xE8ECF2    ; High-contrast crisp white
COL_TEXT_MUTED  equ 0x7E8694    ; Secondary gray for labels
COL_TEXT_DARK   equ 0x484E5B    ; Dimmed helper text

; Metrics Accent Colors
COL_CPU_BAR     equ 0x00D2FF    ; Cyan for normal CPU load
COL_CPU_WARN    equ 0xFFB800    ; Amber for medium-high CPU (>70%)
COL_CPU_CRIT    equ 0xFF4D6D    ; Coral red for critical load (>85%)
COL_RAM_BAR     equ 0x9D4EDD    ; Electric violet for RAM usage
COL_BAR_BG      equ 0x111317    ; Gauge empty background track
COL_SPARK_GRID  equ 0x222630    ; Sparkline horizontal grid guides

; --- Sparkline Settings ---
SPARK_HISTORY_LEN equ 40        ; Number of historical CPU samples
SPARK_X           equ 18
SPARK_Y           equ 98
SPARK_W           equ 284
SPARK_H           equ 28

; Refresh Interval (in 1/100ths of a second)
; 100 centiseconds = 1.0 second update tick
REFRESH_INTERVAL  equ 100
