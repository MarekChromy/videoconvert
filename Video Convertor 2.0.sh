#!/bin/bash
################################################################################
# KNI Video Converter PRO - Linux Edition v1.2
# Profesionální video konvertor s GPU akcelerací
# 
# Autor: Marek Chromý
# Rok: 2026
# Licence: GPL-3.0-or-later
# 
# Popis:
#   Grafický nástroj pro konverzi video souborů s podporou:
#   - Hardwarové GPU akcelerace (VA-API)
#   - Software enkódování (CPU)
#   - H.264 a H.265 (HEVC) kodeky
#   - Více výstupních rozlišení
#   - Nastavitelný bitrate
#   - Dávkové zpracování souborů
#   - Progress bar s real-time FFmpeg výstupem
#
# Požadavky:
#   - ffmpeg (s podporou libx264, libx265, vaapi)
#   - yad (Yet Another Dialog)
#   - GPU s VA-API podporou (pro GPU režim)
#
################################################################################

# Kontrola závislostí
check_dependencies() {
    local missing_deps=()
    
    if ! command -v yad &> /dev/null; then
        missing_deps+=("yad")
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        missing_deps+=("ffmpeg")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Chybějící závislosti: ${missing_deps[*]}"
        echo ""
        echo "Instalace:"
        echo "  Ubuntu/Debian: sudo apt install ${missing_deps[*]}"
        echo "  Fedora:        sudo dnf install ${missing_deps[*]}"
        echo "  Arch:          sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
}

# Kontrola GPU podpory
check_gpu_support() {
    if [ -e "/dev/dri/renderD128" ]; then
        return 0
    else
        return 1
    fi
}

# Získání délky videa v sekundách
get_video_duration() {
    local file="$1"
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null | cut -d'.' -f1
}

# Hlavní funkce
main() {
    # Kontrola závislostí
    check_dependencies
    
    # Zjištění podpory GPU
    local gpu_available=false
    if check_gpu_support; then
        gpu_available=true
    fi
    
    # Výchozí hodnoty
    local default_input="$HOME/Downloads/"
    local default_output="$HOME/Videos/"
    
    # 1. Konfigurační okno
    CONFIG=$(yad --title="KNI Video Converter PRO - Linux Edition" \
        --form --width=600 --separator="|" \
        --text="Profesionální video konvertor s GPU akcelerací\nVytvořil Marek Chromý © 2026" \
        --field="Vstupní složka:DIR" "$default_input" \
        --field="Cílová složka:DIR" "$default_output" \
        --field="Rozlišení:CB" "1920:1080!1280:720!640:480!Původní" \
        --field="Poměr stran:CB" "Automaticky!16:9!4:3!1:1" \
        --field="Video Kodek:CB" "H.265 (HEVC)!H.264 (AVC)" \
        --field="Formát souboru:CB" "mp4!mkv!avi" \
        --field="Video Bitrate (kbps):NUM" "2800!500..20000!100" \
        --field="Audio Bitrate:CB" "128k!192k!256k!320k!96k!64k" \
        --field="Framerate (fps):CB" "Původní!30!25!24!60" \
        --field="Režim enkódování:CB" "GPU (VA-API)!CPU (Software)" \
        --field="Kvalita (CRF pro CPU):NUM" "23!0..51!1" \
        --button="Spustit konverzi:0" \
        --button="O programu:2" \
        --button="Zrušit:1")
    
    local ret=$?
    
    # Tlačítko "O programu"
    if [ $ret -eq 2 ]; then
        yad --info --title="O programu" --width=400 \
            --text="<b>KNI Video Converter PRO</b>\n\nVerze: 1.2\nAutor: Marek Chromý\nRok: 2026\nLicence: GPL-3.0-or-later\n\n<b>Funkce:</b>\n• GPU akcelerace (VA-API)\n• H.264 a H.265 kodeky\n• Dávkové zpracování\n• Progress bar s live výstupem\n\n<b>Web:</b>\nhttps://github.com/marekchrony/kni-converter"
        exit 0
    fi
    
    # Zrušení
    if [ $ret -ne 0 ]; then
        exit 1
    fi
    
    # Načtení konfigurace
    INPUT_DIR=$(echo "$CONFIG" | cut -d'|' -f1)
    OUTPUT_DIR=$(echo "$CONFIG" | cut -d'|' -f2)
    RES=$(echo "$CONFIG" | cut -d'|' -f3)
    ASPECT=$(echo "$CONFIG" | cut -d'|' -f4)
    V_CODEC_RAW=$(echo "$CONFIG" | cut -d'|' -f5)
    EXT=$(echo "$CONFIG" | cut -d'|' -f6)
    V_BITRATE=$(echo "$CONFIG" | cut -d'|' -f7 | cut -d',' -f1 | tr -dc '0-9')
    A_BITRATE=$(echo "$CONFIG" | cut -d'|' -f8)
    FRAMERATE=$(echo "$CONFIG" | cut -d'|' -f9)
    ENCODE_MODE=$(echo "$CONFIG" | cut -d'|' -f10)
    CRF=$(echo "$CONFIG" | cut -d'|' -f11 | cut -d',' -f1 | tr -dc '0-9')
    
    # Validace vstupní složky
    if [ ! -d "$INPUT_DIR" ]; then
        yad --error --title="Chyba" --text="Vstupní složka neexistuje!"
        exit 1
    fi
    
    # Vytvoření výstupní složky
    mkdir -p "$OUTPUT_DIR"
    
    # Nastavení kodeku
    if [[ "$ENCODE_MODE" == "GPU (VA-API)" ]]; then
        if ! check_gpu_support; then
            yad --warning --title="Varování" \
                --text="GPU není k dispozici!\nPokračuji v CPU režimu."
            ENCODE_MODE="CPU (Software)"
        else
            if [[ "$V_CODEC_RAW" == "H.265 (HEVC)" ]]; then
                CODEC="hevc_vaapi"
                HW_ACCEL="-init_hw_device vaapi=va:/dev/dri/renderD128 -hwaccel vaapi -hwaccel_device va"
                VIDEO_FILTER="format=nv12,hwupload"
            else
                CODEC="h264_vaapi"
                HW_ACCEL="-init_hw_device vaapi=va:/dev/dri/renderD128 -hwaccel vaapi -hwaccel_device va"
                VIDEO_FILTER="format=nv12,hwupload"
            fi
        fi
    fi
    
    if [[ "$ENCODE_MODE" == "CPU (Software)" ]]; then
        if [[ "$V_CODEC_RAW" == "H.265 (HEVC)" ]]; then
            CODEC="libx265"
            HW_ACCEL=""
            VIDEO_FILTER=""
            CODEC_OPTS="-crf $CRF -preset medium"
        else
            CODEC="libx264"
            HW_ACCEL=""
            VIDEO_FILTER=""
            CODEC_OPTS="-crf $CRF -preset medium"
        fi
    fi
    
    # Rozlišení
    if [[ "$RES" != "Původní" ]]; then
        if [[ -n "$VIDEO_FILTER" ]]; then
            VIDEO_FILTER="scale=$RES,$VIDEO_FILTER"
        else
            VIDEO_FILTER="scale=$RES"
        fi
    fi
    
    # Poměr stran
    if [[ "$ASPECT" != "Automaticky" ]]; then
        if [[ -n "$VIDEO_FILTER" ]]; then
            VIDEO_FILTER="$VIDEO_FILTER,setdar=$ASPECT"
        else
            VIDEO_FILTER="setdar=$ASPECT"
        fi
    fi
    
    # Framerate
    if [[ "$FRAMERATE" != "Původní" ]]; then
        FPS_OPT="-r $FRAMERATE"
    else
        FPS_OPT=""
    fi
    
    # Bitrate vs CRF
    if [[ "$ENCODE_MODE" == "GPU (VA-API)" ]]; then
        QUALITY_OPTS="-b:v ${V_BITRATE}k"
    else
        QUALITY_OPTS="$CODEC_OPTS"
    fi
    
    # Přejít do vstupní složky
    cd "$INPUT_DIR" || exit 1
    shopt -s nullglob
    FILES=(*)
    
    # Počítadlo souborů
    total_files=0
    for f in "${FILES[@]}"; do
        [[ ! -f "$f" ]] && continue
        [[ "$f" == *.deb || "$f" == *.sh || "$f" == *.txt ]] && continue
        ((total_files++))
    done
    
    if [ $total_files -eq 0 ]; then
        yad --info --title="Info" --text="Žádné video soubory k převodu!"
        exit 0
    fi
    
    # Potvrzení
    yad --question --title="Potvrzení" \
        --text="Nalezeno souborů: $total_files\nRežim: $ENCODE_MODE\nKodek: $V_CODEC_RAW\nFormát: $EXT\n\nSpustit konverzi?" \
        --button="Ano:0" --button="Ne:1"
    
    if [ $? -ne 0 ]; then
        exit 0
    fi
    
    # Smyčka pro zpracování
    current=0
    
    # Vytvoření seznamu souborů pro frontu
    file_list=()
    for f in "${FILES[@]}"; do
        [[ ! -f "$f" ]] && continue
        [[ "$f" == *.deb || "$f" == *.sh || "$f" == *.txt ]] && continue
        file_list+=("$f")
    done
    
    for f in "${file_list[@]}"; do
        ((current++))
        
        # Získání délky videa
        duration=$(get_video_duration "$f")
        if [[ -z "$duration" || "$duration" == "N/A" ]]; then
            duration=100
        fi
        
        # Výstupní soubor
        output_file="$OUTPUT_DIR/${f%.*}_KNI.$EXT"
        
        # Sestavení FFmpeg příkazu
        if [[ -n "$VIDEO_FILTER" ]]; then
            VFILTER_OPT="-vf $VIDEO_FILTER"
        else
            VFILTER_OPT=""
        fi
        
        # Dočasný log soubor
        tmplog="/tmp/kni_ffmpeg_$$.log"
        > "$tmplog"
        
        # Spuštění konverze s progress barem
        (
            ffmpeg -y \
                $HW_ACCEL \
                -i "$f" \
                $VFILTER_OPT \
                -c:v "$CODEC" $QUALITY_OPTS $FPS_OPT \
                -c:a aac -b:a "$A_BITRATE" \
                "$output_file" \
                -progress pipe:1 2>&1 | while read -r line; do
                
                # Uložení řádku do logu
                echo "$line" >> "$tmplog"
                
                # Detekce progress
                if [[ "$line" == out_time_ms=* ]]; then
                    time_ms=${line#*=}
                    time_s=$((time_ms / 1000000))
                    
                    if [ $time_s -gt 0 ] && [ $duration -gt 0 ]; then
                        percent=$((time_s * 100 / duration))
                        [ $percent -gt 100 ] && percent=100
                    else
                        percent=0
                    fi
                    
                    # Formát času
                    h=$((time_s / 3600))
                    m=$(((time_s % 3600) / 60))
                    s=$((time_s % 60))
                    time_str=$(printf '%02d:%02d:%02d' $h $m $s)
                    
                    # Poslední řádek s fps/speed info
                    stats=$(grep -E "frame=|fps=|speed=" "$tmplog" | tail -1)
                    
                    echo "$percent"
                    echo "# 🎬 ${f} (${current}/${total_files}) | ${percent}% | ⏱️ ${time_str} | 📟 ${stats}"
                fi
                
                if [[ "$line" == *"progress=end"* ]]; then
                    echo "100"
                    echo "# ✅ Hotovo!"
                fi
            done
        ) | yad --progress \
            --title="KNI Converter PRO - Zpracovávám" \
            --width=850 \
            --height=100 \
            --percentage=0 \
            --auto-close \
            --auto-kill \
            --no-cancel
        
        # Cleanup
        rm -f "$tmplog"
        
        # Kontrola úspěchu
        if [ -f "$output_file" ]; then
            :  # OK
        else
            yad --error --title="Chyba" --text="❌ Chyba při zpracování: $f" --timeout=3
        fi
    done
    
    # Závěrečná zpráva
    yad --info --title="Dokončeno" \
        --width=400 \
        --text="<b>✅ Konverze dokončena!</b>\n\nZpracováno: $current/$total_files\nVýstup: $OUTPUT_DIR\n\n<b>💻 Marek Chromý © 2026</b>" \
        --button="Otevřít složku:0" \
        --button="Zavřít:1"
    
    if [ $? -eq 0 ]; then
        xdg-open "$OUTPUT_DIR" 2>/dev/null || nautilus "$OUTPUT_DIR" 2>/dev/null || dolphin "$OUTPUT_DIR" 2>/dev/null
    fi
}

# Spuštění
main "$@"
