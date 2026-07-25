#!/usr/bin/env zsh
# ==============================================================================
# Forensic Sonic Overclocking Suite (macOS 32-bit FLAC Full-Range Master Edition)
# ==============================================================================

export PROC_DIR="$HOME/audio files (processed)"
mkdir -p "$PROC_DIR"

alias audit="bash ~/audit.sh"

find_audio() {
    if [ -f "$1" ]; then
        echo "$1"
    else
        find "$HOME/audio files" "$PROC_DIR" -type f -iname "$1" 2>/dev/null | head -n 1
    fi
}

# 2.5x Full-Range Spatial Wide (-15 LUFS, 32-bit FLAC)
far() {
    local c=":"
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Far_As_Hell/FAR_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Far_As_Hell"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;34mDual-Pass FAR Full-Range Mastering (-15 LUFS, 32-bit FLAC)...\e[0m"
    MEASURE=$(ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
     [wide]loudnorm=I=-15:TP=-1.5:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Integrated:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-15.0')")
    TP=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input True Peak:\s*([-+0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-1.5')")
    LRA=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input LRA:\s*([0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '11.0')")
    THRESH=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Threshold:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-25.0')")
    I=${I:-"-15.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-25.0"}

    if ffmpeg -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
     [wide]loudnorm=I=-15:TP=-1.5${c}measured_I=$I${c}measured_TP=$TP${c}measured_LRA=$LRA${c}measured_thresh=$THRESH${c}linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

# 5.0x Full-Range Ultra-Wide (-15 LUFS, 32-bit FLAC)
uw() {
    local c=":"
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Ultra_Wide/UW_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Ultra_Wide"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;31mDual-Pass 5x Full-Range Ultra-Wide (-15 LUFS, 32-bit FLAC)...\e[0m"
    MEASURE=$(ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
     [wide]loudnorm=I=-15:TP=-1.5:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Integrated:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-15.0')")
    TP=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input True Peak:\s*([-+0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-1.5')")
    LRA=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input LRA:\s*([0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '11.0')")
    THRESH=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Threshold:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-25.0')")
    I=${I:-"-15.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-25.0"}

    if ffmpeg -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
     [wide]loudnorm=I=-15:TP=-1.5${c}measured_I=$I${c}measured_TP=$TP${c}measured_LRA=$LRA${c}measured_thresh=$THRESH${c}linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

# 100x Full-Range GodMode Matrix (-15 LUFS, 32-bit FLAC)
godmode() {
    local c=":"
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/GodMode_Masters/GODMODE_100x_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/GodMode_Masters"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;35mActivating GODMODE: 100x Full-Range Matrix (-15 LUFS, 32-bit FLAC)...\e[0m"
    MEASURE=$(ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=40.0*c0+100.0*c1|c1=40.0*c0-100.0*c1[wide]; \
     [wide]loudnorm=I=-15:TP=-2.0:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Integrated:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-15.0')")
    TP=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input True Peak:\s*([-+0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-2.0')")
    LRA=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input LRA:\s*([0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '11.0')")
    THRESH=$(echo "$MEASURE" | python3 -c "import sys, re; m=re.search(r'Input Threshold:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-25.0')")
    I=${I:-"-15.0"}; TP=${TP:-"-2.0"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-25.0"}

    if ffmpeg -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]pan=stereo|c0=40.0*c0+100.0*c1|c1=40.0*c0-100.0*c1[wide]; \
     [wide]loudnorm=I=-15:TP=-2.0${c}measured_I=$I${c}measured_TP=$TP${c}measured_LRA=$LRA${c}measured_thresh=$THRESH${c}linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

analog() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Analog_Masters/TUBE_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Analog_Masters"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    CHAIN="aexciter=level_in=0.95:level_out=1.0:amount=2:drive=1.2"

    echo -e "\e[1;34mInjecting Subtle Tube Harmonics...\e[0m"
    PEAK_LOG=$(ffmpeg -nostdin -i "$SRC" -filter_complex "$CHAIN,volumedetect" -f null - 2>&1)
    PEAK=$(echo "$PEAK_LOG" | python3 -c "import sys, re; m=re.search(r'max_volume:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '0.0')")
    GAIN=$(python3 -c "print(round(-1.0 - float('$PEAK'), 1))")

    if ffmpeg -v error -y -i "$SRC" -filter_complex "$CHAIN,volume=${GAIN}dB" -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

sub() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Subharmonic_Generator/SUB_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Subharmonic_Generator"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    CHAIN="asplit=2[org][bass_path];[bass_path]lowpass=f=120:p=2,asetrate=${SR}*0.5,atempo=2.0,lowpass=f=60:p=2,volume=1.5,aresample=${SR}[sub_octave];[org][sub_octave]amix=inputs=2:weights=1.0 0.8"

    echo -e "\e[1;35m--- LINEAR SUBHARMONIC OPTIMIZATION (120Hz Target) ---\e[0m"
    PEAK_LOG=$(ffmpeg -nostdin -i "$SRC" -filter_complex "$CHAIN,volumedetect" -f null - 2>&1)
    PEAK=$(echo "$PEAK_LOG" | python3 -c "import sys, re; m=re.search(r'max_volume:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '0.0')")
    GAIN=$(python3 -c "print(round(-1.5 - float('$PEAK'), 1))")

    if ffmpeg -v error -y -i "$SRC" -filter_complex "$CHAIN,volume=${GAIN}dB" -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

bass() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Virtual_Bass_Generator/VB_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Virtual_Bass_Generator"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    CHAIN="virtualbass=cutoff=110:strength=1.2,pan=stereo|c0=c0+0.4*c2|c1=c1+0.4*c2"

    echo -e "\e[1;35m--- LINEAR PSYCHOACOUSTIC BASS ENHANCEMENT ---\e[0m"
    PEAK_LOG=$(ffmpeg -nostdin -i "$SRC" -filter_complex "$CHAIN,volumedetect" -f null - 2>&1)
    PEAK=$(echo "$PEAK_LOG" | python3 -c "import sys, re; m=re.search(r'max_volume:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '0.0')")
    GAIN=$(python3 -c "print(round(-1.5 - float('$PEAK'), 1))")

    if ffmpeg -v error -y -i "$SRC" -filter_complex "$CHAIN,volume=${GAIN}dB" -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}

rip() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="$PROC_DIR/Extracted_Stems/$(basename "${SRC%.*}")"
    mkdir -p "$OUT_DIR"
    echo -e "\e[1;34mSurgically Ripping via AI (Vocals + Accompaniment)...\e[0m"
    
    demucs -d mps --two-stems vocals --flac --segment 7 -o "$OUT_DIR" "$SRC"
    
    local track_name=$(basename "${SRC%.*}")
    local gen_dir="$OUT_DIR/htdemucs/$track_name"
    
    if [ -d "$gen_dir" ]; then
        echo -e "\e[1;33mPreserving original tags and cover art...\e[0m"
        for stem in "$gen_dir"/*.flac; do
            [ -f "$stem" ] || continue
            local temp_stem="${stem%.*}.temp.flac"
            if ffmpeg -v error -y -i "$stem" -i "$SRC" -map 0:a -map 1:v? -map_metadata 1 -c:a copy -c:v copy "$temp_stem"; then
                mv "$temp_stem" "$stem"
            fi
        done
    fi
    echo -e "\e[1;32mDONE! Stems saved to: $OUT_DIR\e[0m"
}

rippro() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="$PROC_DIR/Extracted_Stems/$(basename "${SRC%.*}")"
    mkdir -p "$OUT_DIR"
    echo -e "\e[1;35mExecuting Full AI Multi-Stem Extraction (4-Stem FT Model)...\e[0m"
    
    demucs -d mps -n htdemucs_ft --flac --segment 7 -o "$OUT_DIR" "$SRC"
    
    local track_name=$(basename "${SRC%.*}")
    local gen_dir="$OUT_DIR/htdemucs_ft/$track_name"
    
    if [ -d "$gen_dir" ]; then
        echo -e "\e[1;33mPreserving original tags and cover art...\e[0m"
        for stem in "$gen_dir"/*.flac; do
            [ -f "$stem" ] || continue
            local temp_stem="${stem%.*}.temp.flac"
            if ffmpeg -v error -y -i "$stem" -i "$SRC" -map 0:a -map 1:v? -map_metadata 1 -c:a copy -c:v copy "$temp_stem"; then
                mv "$temp_stem" "$stem"
            fi
        done
    fi
    echo -e "\e[1;32mDONE! Full stems saved to: $OUT_DIR\e[0m"
}

optimize() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    
    OUT_DIR="$PROC_DIR/Optimized_Masters"
    mkdir -p "$OUT_DIR"
    
    BASENAME=$(basename "$SRC")
    OUT_FILE="$OUT_DIR/OPT_LINEAR_${BASENAME%.*}.flac"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;35m--- LINEAR ENDGAME OPTIMIZATION ---\e[0m"
    CHAIN="aexciter=level_in=0.8:level_out=1.0:amount=5:drive=3,asubboost=dry=1.0:wet=0.8:cutoff=60,pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1,asplit=2[m_in][s_in];[m_in]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[m];[s_in]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[s];[m][s]amerge=inputs=2,pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1"

    PEAK_LOG=$(ffmpeg -nostdin -i "$SRC" -filter_complex "$CHAIN,volumedetect" -f null - 2>&1)
    PEAK=$(echo "$PEAK_LOG" | python3 -c "import sys, re; m=re.search(r'max_volume:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '0.0')")
    GAIN=$(python3 -c "print(round(-1.0 - float('$PEAK'), 1))")

    echo -e "\e[1;32m[Pass 2/2] Applying Static Gain: ${GAIN}dB...\e[0m"
    if ffmpeg -v error -y -i "$SRC" -filter_complex "$CHAIN,volume=${GAIN}dB,alimiter=level_in=1:level_out=1:limit=0.95" -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        audit "$OUT_FILE"
    fi
}
alias optimise="optimize"
