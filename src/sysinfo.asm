; ==============================================================================
; KolibriPulse - System Metrics Collector
; ==============================================================================

collect_system_metrics:
    pushad

    ; --------------------------------------------------------------------------
    ; 1. RAM Information (Syscall 18, subfunctions 16 & 17)
    ; --------------------------------------------------------------------------
    ; Get Total RAM in KB
    mcall 18, 16
    mov [ram_total_kb], eax
    shr eax, 10                     ; KB -> MB (divide by 1024)
    mov [ram_total_mb], eax

    ; Get Free RAM in KB
    mcall 18, 17
    mov [ram_free_kb], eax
    shr eax, 10                     ; KB -> MB
    mov [ram_free_mb], eax

    ; Calculate Used RAM in MB
    mov eax, [ram_total_mb]
    sub eax, [ram_free_mb]
    jnc .used_ram_ok
    xor eax, eax
.used_ram_ok:
    mov [ram_used_mb], eax

    ; Calculate RAM usage percentage: (used_mb * 100) / total_mb
    mov eax, [ram_used_mb]
    imul eax, 100
    mov ecx, [ram_total_mb]
    test ecx, ecx
    jz .ram_pct_zero
    xor edx, edx
    div ecx
    cmp eax, 100
    jbe .ram_pct_ok
    mov eax, 100
    jmp .ram_pct_ok
.ram_pct_zero:
    xor eax, eax
.ram_pct_ok:
    mov [ram_percent], eax

    ; --------------------------------------------------------------------------
    ; 2. CPU Frequency (Syscall 18, subfunction 4)
    ; --------------------------------------------------------------------------
    mcall 18, 4
    ; Returns frequency in Hz. Convert to MHz (divide by 1,000,000)
    mov ecx, 1000000
    xor edx, edx
    div ecx
    mov [cpu_freq_mhz], eax

    ; --------------------------------------------------------------------------
    ; 3. Total Active Threads / Processes (Syscall 18, subfunction 7)
    ; --------------------------------------------------------------------------
    mcall 18, 7
    mov [active_threads], eax

    ; --------------------------------------------------------------------------
    ; 4. System Uptime (Syscall 26, subfunction 1)
    ; --------------------------------------------------------------------------
    mcall 26, 1
    ; EAX = timer ticks (100 ticks = 1 second)
    mov ecx, 100
    xor edx, edx
    div ecx                         ; EAX = uptime in seconds
    mov [uptime_total_sec], eax

    ; Calculate Hours = total / 3600
    mov ecx, 3600
    xor edx, edx
    div ecx
    mov [uptime_hours], eax

    ; Calculate Minutes = (total % 3600) / 60
    mov eax, edx
    mov ecx, 60
    xor edx, edx
    div ecx
    mov [uptime_mins], eax

    ; Calculate Seconds = remainder
    mov [uptime_secs], edx

    ; Format Uptime string "HH:MM:SS"
    call format_uptime_string

    ; --------------------------------------------------------------------------
    ; 5. CPU Usage via Slot 1 (IDLE Thread, Syscall 9)
    ; --------------------------------------------------------------------------
    mcall 9, proc_info_buf, 1
    ; Slot 1 is the kernel IDLE thread
    ; Offset 30 (word): CPU usage of idle thread
    movzx eax, word [proc_info_buf + 30]

    ; Check if given in basis points (0..10000) or percent (0..100)
    cmp eax, 100
    jbe .idle_is_pct
    mov ecx, 100
    xor edx, edx
    div ecx
.idle_is_pct:
    cmp eax, 100
    jbe .idle_clamped
    mov eax, 100
.idle_clamped:
    ; CPU Load = 100 - Idle%
    mov edx, 100
    sub edx, eax
    jnc .load_ok
    xor edx, edx
.load_ok:
    cmp edx, 100
    jbe .load_bounded
    mov edx, 100
.load_bounded:
    mov [cpu_percent], edx

    ; --------------------------------------------------------------------------
    ; 6. Update Sparkline History (Shift left and append newest CPU load)
    ; --------------------------------------------------------------------------
    mov ecx, SPARK_HISTORY_LEN - 1
    mov esi, spark_history + 1
    mov edi, spark_history
.shift_history:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop .shift_history

    ; Store current CPU percent at the end
    mov eax, [cpu_percent]
    mov [spark_history + SPARK_HISTORY_LEN - 1], al

    popad
    ret

; ------------------------------------------------------------------------------
; Helper: Formats HH:MM:SS into uptime_str buffer
; ------------------------------------------------------------------------------
format_uptime_string:
    push eax
    push edx

    ; Hours
    mov eax, [uptime_hours]
    call write_two_digits
    mov [uptime_str], al
    mov [uptime_str + 1], ah

    ; Colon
    mov byte [uptime_str + 2], ':'

    ; Minutes
    mov eax, [uptime_mins]
    call write_two_digits
    mov [uptime_str + 3], al
    mov [uptime_str + 4], ah

    ; Colon
    mov byte [uptime_str + 5], ':'

    ; Seconds
    mov eax, [uptime_secs]
    call write_two_digits
    mov [uptime_str + 6], al
    mov [uptime_str + 7], ah

    ; Null terminator
    mov byte [uptime_str + 8], 0

    pop edx
    pop eax
    ret

; Convert number in EAX (0..99) to two ASCII digits in AL (tens), AH (units)
write_two_digits:
    cmp eax, 99
    jbe .range_ok
    mov eax, 99
.range_ok:
    mov ecx, 10
    xor edx, edx
    div ecx
    add al, '0'
    add dl, '0'
    mov ah, dl
    ret
