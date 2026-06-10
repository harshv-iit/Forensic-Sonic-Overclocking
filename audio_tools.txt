#!/data/data/com.termux/files/usr/bin/bash

#Multiple Device/Hardware restrictions have been applied to the code

#Usage:
	#{program_name} "file.format"

# --- ORGANIZED AUDIO TOOLS ---

#Adds low-moderate meier crossfeed
widen() {
    SRC=$(find /sdcard/Music -iname "$1" -type f -print -quit)
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="/sdcard/Music/Widen"
    mkdir -p "$OUT_DIR"
    OUT_FILE="$OUT_DIR/WIDENED_$(basename "$SRC")"
    echo -e "\e[1;34mProcessing Widen (Crossfeed) -> $OUT_FILE\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "bs2b=profile=jmeier" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone.\e[0m"
}
#simulates digitally the analog hardware processing of the spl phonitor(a hardware based crossfeed system)
phonitor() {
    SRC=$(find /sdcard/Music -iname "$1" -type f -print -quit)
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="/sdcard/Music/Phonitor"
    mkdir -p "$OUT_DIR"
    OUT_FILE="$OUT_DIR/PHONITOR_$(basename "$SRC")"
    echo -e "\e[1;34mProcessing Phonitor (30deg Matrix) -> $OUT_FILE\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "bs2b=fcut=700:feed=65,loudnorm=I=-14:TP=-1.0" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone.\e[0m"
}
#Phase shifts the high frequencies in the pursuit of a more expansive soundstage
hologram() {
    SRC=$(find /sdcard/Music -iname "$1" -type f -print -quit)
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="/sdcard/Music/Hologram"
    mkdir -p "$OUT_DIR"
    OUT_FILE="$OUT_DIR/3D_$(basename "$SRC")"
    echo -e "\e[1;34mProcessing Hologram (Phase Shift) -> $OUT_FILE\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "allpass=f=12000:width_type=h:w=2" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone.\e[0m"
}
#Essentially just expanss the side and mid channels and not much else
godmode() {
    SRC=$(find /sdcard/Music -iname "$1" -type f -print -quit)
    [ -z "$SRC" ] && { echo -e "\e[1;31mFile not found\e[0m"; return 1; }
    
    OUT_DIR="/sdcard/Music/GodMode_Masters"
    mkdir -p "$OUT_DIR"
    
    BASENAME=$(basename "$SRC")
    FILENAME="${BASENAME%.*}"
    OUT_FILE="$OUT_DIR/GODMODE_${FILENAME}.flac"

    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;35mActivating TRUE STEREO GODMODE: 3-Layer Geometry...\e[0m"

    # THE REFINED MATRIX:
    # Path 1 (Lows): Forced to 'Dual Mono' Stereo (identitcal L/R)
    # Path 2 (Mids): 2.5x Expansion using single-pass math to avoid internal summing.
    # Path 3 (Highs): 5.0x Expansion using single-pass math.
    # Result: L=3.25L - 1.75R | R=-1.75L + 3.25R (This is the 5.0x / 1.5x formula)
    ffmpeg -v error -y -i "$SRC" -filter_complex \
    "[0:a]asplit=3[l_in][m_in][h_in]; \
     [l_in]lowpass=f=200,pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0+0.5*c1[lows]; \
     [m_in]highpass=f=200,lowpass=f=6000,pan=stereo|c0=1.9*c0-0.6*c1|c1=-0.6*c0+1.9*c1[mids]; \
     [h_in]highpass=f=6000,pan=stereo|c0=3.25*c0-1.75*c1|c1=-1.75*c0+3.25*c1[highs]; \
     [lows][mids][highs]amix=inputs=3:duration=first:normalize=0,loudnorm=I=-14:TP=-1.5" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"

    echo -e "\e[1;32mSUCCESS! True Stereo Multidimensional Master saved.\e[0m"
    echo -e "\e[1;37m$OUT_FILE\e[0m"
}

# Global variable for the new isolated environment
export PROC_DIR="/sdcard/Music (processed)"

# Helper engine: Searches both original and processed folders simultaneously
find_audio() {
    find "/sdcard/Music" "$PROC_DIR" -iname "$1" -type f -print -quit 2>/dev/null
}
#Allows to rip the center and side channels respectively effectively making them into two separate versions
rip() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_DIR="$PROC_DIR/Extracted_Stems"
    mkdir -p "$OUT_DIR"
    CENTER_FILE="$OUT_DIR/CENTER_STEREO_$(basename "${SRC%.*}").flac"
    SIDE_FILE="$OUT_DIR/SIDE_STEREO_$(basename "${SRC%.*}").flac"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;34mSurgically Ripping -> $PROC_DIR...\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0+0.5*c1,loudnorm=I=-16" -ar $SR -sample_fmt s32 -c:a flac "$CENTER_FILE"
    ffmpeg -v error -y -i "$SRC" -af "pan=stereo|c0=0.5*c0-0.5*c1|c1=-0.5*c0+0.5*c1,loudnorm=I=-16" -ar $SR -sample_fmt s32 -c:a flac "$SIDE_FILE"
    echo -e "\e[1;32mDONE!\e[0m"
}
#2.5 times side expansion with 1.3 times center channel expansion
far() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Far_As_Hell/FAR_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Far_As_Hell"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;34mDual-Pass FAR Mastering (Pass 1: Measuring...)\e[0m"
    # Added volume=-15dB pre-attenuation to prevent positive LUFS crashes
    MEASURE=$(nice -n 19 ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
     [wide]loudnorm=I=-14:TP=-1.5:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | grep "Input Integrated" | awk '{print $3}' | tail -n 1)
    TP=$(echo "$MEASURE" | grep "Input True Peak" | awk '{print $4}' | tail -n 1)
    LRA=$(echo "$MEASURE" | grep "Input LRA" | awk '{print $3}' | tail -n 1)
    THRESH=$(echo "$MEASURE" | grep "Input Threshold" | awk '{print $3}' | tail -n 1)
    I=${I:-"-14.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-24.0"}

    echo -e "\e[1;32m(Pass 2: Linear Render at ${SR}Hz...)\e[0m"
    if nice -n 19 ffmpeg -nostdin -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
     [wide]loudnorm=I=-14:TP=-1.5:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        bash ~/audit.sh "$OUT_FILE"
    else
        echo -e "\e[1;31mError: FFmpeg failed on Pass 2.\e[0m"
    fi
}
#5x side and 2.5x xenter channel expansion
uw() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Ultra_Wide/UW_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Ultra_Wide"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;31mDual-Pass UW Mastering (Pass 1: Measuring...)\e[0m"
    # Added volume=-20dB pre-attenuation for 5x explosion
    MEASURE=$(nice -n 19 ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=6[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
     [wide]loudnorm=I=-14:TP=-1.5:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | grep "Input Integrated" | awk '{print $3}' | tail -n 1)
    TP=$(echo "$MEASURE" | grep "Input True Peak" | awk '{print $4}' | tail -n 1)
    LRA=$(echo "$MEASURE" | grep "Input LRA" | awk '{print $3}' | tail -n 1)
    THRESH=$(echo "$MEASURE" | grep "Input Threshold" | awk '{print $3}' | tail -n 1)
    I=${I:-"-14.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-24.0"}

    echo -e "\e[1;32m(Pass 2: Linear Render...)\e[0m"
    if nice -n 19 ffmpeg -nostdin -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=6[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
     [wide]loudnorm=I=-14:TP=-1.5:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        bash ~/audit.sh "$OUT_FILE"
    fi
}
#100x side and 50x center channel expansion
sg() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    OUT_FILE="$PROC_DIR/Singularity/SG_100x_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Singularity"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;35mSingularity Dual-Pass (Pass 1: Measuring...)\e[0m"
    # Added volume=-50dB pre-attenuation because 100x is literally insanity
    MEASURE=$(nice -n 19 ffmpeg -nostdin -hide_banner -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=8[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=40.0*c0+100.0*c1|c1=40.0*c0-100.0*c1,volume=-50dB[wide]; \
     [wide]loudnorm=I=-18:TP=-2.0:print_format=summary" -f null - 2>&1)
    
    I=$(echo "$MEASURE" | grep "Input Integrated" | awk '{print $3}' | tail -n 1)
    TP=$(echo "$MEASURE" | grep "Input True Peak" | awk '{print $4}' | tail -n 1)
    LRA=$(echo "$MEASURE" | grep "Input LRA" | awk '{print $3}' | tail -n 1)
    THRESH=$(echo "$MEASURE" | grep "Input Threshold" | awk '{print $3}' | tail -n 1)
    I=${I:-"-18.0"}; TP=${TP:-"-2.0"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-28.0"}

    echo -e "\e[1;32m(Pass 2: Rendering SG Matrix...)\e[0m"
    if nice -n 19 ffmpeg -nostdin -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
     [ms]asplit=2[ms1][ms2]; \
     [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
     [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=8[side]; \
     [mid][side]amerge=inputs=2[ms_merged]; \
     [ms_merged]pan=stereo|c0=40.0*c0+100.0*c1|c1=40.0*c0-100.0*c1,volume=-50dB[wide]; \
     [wide]loudnorm=I=-18:TP=-2.0:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        bash ~/audit.sh "$OUT_FILE"
    fi
}
#Basically the far() command but can process folders
far_album() {
    TARGET_DIR=$(find "/sdcard/Music" "$PROC_DIR" -type d -iname "$1" -print -quit 2>/dev/null)
    [ -z "$TARGET_DIR" ] && { echo -e "\e[1;31mFolder not found\e[0m"; return 1; }
    ALBUM_NAME=$(basename "$TARGET_DIR")
    OUT_DIR="$PROC_DIR/Far_As_Hell/${ALBUM_NAME}_Far"
    mkdir -p "$OUT_DIR"
    
    shopt -s nocaseglob
    FILES=( "$TARGET_DIR"/*.{flac,mp3,opus,m4a} )
    TOTAL_FILES=${#FILES[@]}
    CURRENT_INDEX=0

    REPORT_FILE="$OUT_DIR/Loudness_Report.txt"
    echo "--- DUAL-PASS DAILY DRIVER REPORT: $ALBUM_NAME ---" > "$REPORT_FILE"
    printf "\n%-30s | %-10s | %-10s | %-10s\n" "Song Name" "80dB Pre" "85dB Pre" "90dB Pre" >> "$REPORT_FILE"
    echo "----------------------------------------------------------------------" >> "$REPORT_FILE"

    echo -e "\e[1;34m=== DUAL-PASS BATCH (FAR MODE): $ALBUM_NAME ===\e[0m"

    for src in "${FILES[@]}"; do
        [ -e "$src" ] || continue
        ((CURRENT_INDEX++))
        filename=$(basename "$src")
        output="$OUT_DIR/FAR_${filename%.*}.flac"
        
        if [ -f "$output" ]; then
            echo -e "\e[1;30m[$CURRENT_INDEX/$TOTAL_FILES] Skipping: $filename\e[0m"
            continue
        fi

        START_TIME=$(date +%s)
        echo -e "\n\e[1;33m[$CURRENT_INDEX/$TOTAL_FILES]\e[0m Mastering: \e[1;37m$filename\e[0m"
        SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$src")

        MEASURE=$(nice -n 19 ffmpeg -nostdin -hide_banner -y -threads 4 -i "$src" -filter_complex \
        "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
         [ms]asplit=2[ms1][ms2]; \
         [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[mid]; \
         [ms2]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[side]; \
         [mid][side]amerge=inputs=2[ms_merged]; \
         [ms_merged]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
         [wide]loudnorm=I=-14:TP=-1.5:print_format=summary" -f null - 2>&1)
        
        I=$(echo "$MEASURE" | grep "Input Integrated" | awk '{print $3}' | tail -n 1)
        TP=$(echo "$MEASURE" | grep "Input True Peak" | awk '{print $4}' | tail -n 1)
        LRA=$(echo "$MEASURE" | grep "Input LRA" | awk '{print $3}' | tail -n 1)
        THRESH=$(echo "$MEASURE" | grep "Input Threshold" | awk '{print $3}' | tail -n 1)
        I=${I:-"-14.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-24.0"}

        if nice -n 19 ffmpeg -nostdin -v error -y -threads 4 -i "$src" -filter_complex \
        "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
         [ms]asplit=2[ms1][ms2]; \
         [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[mid]; \
         [ms2]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[side]; \
         [mid][side]amerge=inputs=2[ms_merged]; \
         [ms_merged]pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,volume=-15dB[wide]; \
         [wide]loudnorm=I=-14:TP=-1.5:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true" \
        -ar $SR -sample_fmt s32 -c:a flac "$output"; then
            
            END_TIME=$(date +%s)
            ELAPSED=$((END_TIME - START_TIME))
            AUDIT_LOG=$(bash ~/audit.sh "$output")
            p80=$(echo "$AUDIT_LOG" | grep "80dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            p85=$(echo "$AUDIT_LOG" | grep "85dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            p90=$(echo "$AUDIT_LOG" | grep "90dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            
            printf "%-30.30s | %-10s | %-10s | %-10s\n" "${filename%.*}" "$p80" "$p85" "$p90" >> "$REPORT_FILE"
            echo -e "\e[1;32m   [Done in ${ELAPSED}s] 85dB Preamp: $p85\e[0m"
        else
            echo -e "\e[1;31m   [!] FFmpeg failed.\e[0m"
        fi
        sleep 3
    done
    echo -e "\n\e[1;34m=== BATCH COMPLETE ===\e[0m"
}
#Basically the uw() command but can process folders
uw_album() {
    TARGET_DIR=$(find "/sdcard/Music" "$PROC_DIR" -type d -iname "$1" -print -quit 2>/dev/null)
    [ -z "$TARGET_DIR" ] && { echo -e "\e[1;31mFolder not found\e[0m"; return 1; }
    ALBUM_NAME=$(basename "$TARGET_DIR")
    OUT_DIR="$PROC_DIR/Ultra_Wide/${ALBUM_NAME}_UW"
    mkdir -p "$OUT_DIR"
    
    shopt -s nocaseglob
    FILES=( "$TARGET_DIR"/*.{flac,mp3,opus,m4a} )
    TOTAL_FILES=${#FILES[@]}
    CURRENT_INDEX=0

    REPORT_FILE="$OUT_DIR/Loudness_Report.txt"
    echo "--- DUAL-PASS ULTRA-WIDE REPORT: $ALBUM_NAME ---" > "$REPORT_FILE"
    echo "Profile: 5.0x Side / 2.5x Center Anchor (Linear Volume)" >> "$REPORT_FILE"
    printf "\n%-30s | %-10s | %-10s | %-10s\n" "Song Name" "80dB Pre" "85dB Pre" "90dB Pre" >> "$REPORT_FILE"
    echo "----------------------------------------------------------------------" >> "$REPORT_FILE"

    echo -e "\e[1;31m=== DUAL-PASS BATCH (ULTRA-WIDE): $ALBUM_NAME ===\e[0m"

    for src in "${FILES[@]}"; do
        [ -e "$src" ] || continue
        ((CURRENT_INDEX++))
        filename=$(basename "$src")
        output="$OUT_DIR/UW_${filename%.*}.flac"
        
        if [ -f "$output" ]; then
            echo -e "\e[1;30m[$CURRENT_INDEX/$TOTAL_FILES] Skipping: $filename\e[0m"
            continue
        fi

        START_TIME=$(date +%s)
        echo -e "\n\e[1;33m[$CURRENT_INDEX/$TOTAL_FILES]\e[0m Mastering: \e[1;37m$filename\e[0m"
        SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$src")

        MEASURE=$(nice -n 19 ffmpeg -nostdin -hide_banner -y -threads 4 -i "$src" -filter_complex \
        "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
         [ms]asplit=2[ms1][ms2]; \
         [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
         [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=6[side]; \
         [mid][side]amerge=inputs=2[ms_merged]; \
         [ms_merged]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
         [wide]loudnorm=I=-14:TP=-1.5:print_format=summary" -f null - 2>&1)
        
        I=$(echo "$MEASURE" | grep "Input Integrated" | awk '{print $3}' | tail -n 1)
        TP=$(echo "$MEASURE" | grep "Input True Peak" | awk '{print $4}' | tail -n 1)
        LRA=$(echo "$MEASURE" | grep "Input LRA" | awk '{print $3}' | tail -n 1)
        THRESH=$(echo "$MEASURE" | grep "Input Threshold" | awk '{print $3}' | tail -n 1)
        I=${I:-"-14.0"}; TP=${TP:-"-1.5"}; LRA=${LRA:-"11.0"}; THRESH=${THRESH:-"-24.0"}

        if nice -n 19 ffmpeg -nostdin -v error -y -threads 4 -i "$src" -filter_complex \
        "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1[ms]; \
         [ms]asplit=2[ms1][ms2]; \
         [ms1]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=3[mid]; \
         [ms2]pan=mono|c0=c1,equalizer=f=16000:width_type=h:w=2:g=6[side]; \
         [mid][side]amerge=inputs=2[ms_merged]; \
         [ms_merged]pan=stereo|c0=2.5*c0+5.0*c1|c1=2.5*c0-5.0*c1,volume=-20dB[wide]; \
         [wide]loudnorm=I=-14:TP=-1.5:measured_I=$I:measured_TP=$TP:measured_LRA=$LRA:measured_thresh=$THRESH:linear=true" \
        -ar $SR -sample_fmt s32 -c:a flac "$output"; then
            
            END_TIME=$(date +%s)
            ELAPSED=$((END_TIME - START_TIME))
            AUDIT_LOG=$(bash ~/audit.sh "$output")
            p80=$(echo "$AUDIT_LOG" | grep "80dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            p85=$(echo "$AUDIT_LOG" | grep "85dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            p90=$(echo "$AUDIT_LOG" | grep "90dB" | awk -F'Pre:' '{print $2}' | awk '{print $1}')
            
            printf "%-30.30s | %-10s | %-10s | %-10s\n" "${filename%.*}" "$p80" "$p85" "$p90" >> "$REPORT_FILE"
            echo -e "\e[1;32m   [Done in ${ELAPSED}s] 85dB Preamp: $p85\e[0m"
        else
            echo -e "\e[1;31m   [!] FFmpeg failed.\e[0m"
        fi
        sleep 3
    done
    echo -e "\n\e[1;31m=== BATCH COMPLETE ===\e[0m"
}
#Adds even harmonics to the frequencies
analog() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && return 1
    OUT_FILE="$PROC_DIR/Analog_Masters/TUBE_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Analog_Masters"
    # aexciter: Boosts harmonics. level_in=0.1 (subtle), level_out=1 (pure), amount=5 (intensity)
    echo -e "\e[1;34mInjecting Even/Odd Harmonics (Analog Emulation)...\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "aexciter=level_in=0.8:level_out=1.0:amount=5:drive=3" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone.\e[0m"
}
#Adds a lower octave bass frequency
sub() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && return 1
    OUT_FILE="$PROC_DIR/Sub_Masters/SUB_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Sub_Masters"
    echo -e "\e[1;35mSynthesizing Sub-Harmonics (Max Legal Wetness)...\e[0m"
    # wet=1.0 is the max allowed. 
    # We add a low-shelf at 40Hz to give the new harmonics extra weight.
    ffmpeg -v error -y -i "$SRC" -af "asubboost=dry=1.0:wet=1.0:cutoff=60,equalizer=f=40:width_type=h:w=1:g=5,loudnorm=I=-14" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone. Sub-bass synthesized.\e[0m"
}
#Makes the processor go brrrrr
void() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && return 1
    OUT_FILE="$PROC_DIR/Void_Masters/VOID_$(basename "${SRC%.*}").flac"
    mkdir -p "$PROC_DIR/Void_Masters"
    # afftdn: FFT-based Denoiser. Very heavy math.
    echo -e "\e[1;31mInitiating Spectral Denoising (Building the Void)...\e[0m"
    ffmpeg -v error -y -i "$SRC" -af "afftdn=nr=15:nt=w" -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone. The background is now mathematically silent.\e[0m"
}
#Combines far(),analog(),and sub()
optimize() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && { echo "File not found"; return 1; }
    
    OUT_DIR="$PROC_DIR/Optimized_Masters"
    mkdir -p "$OUT_DIR"
    
    BASENAME=$(basename "$SRC")
    OUT_FILE="$OUT_DIR/OPT_LINEAR_${BASENAME%.*}.flac"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;35m--- LINEAR ENDGAME OPTIMIZATION ---\e[0m"
    echo -e "\e[1;34mAnalog + Sub + 2.5x Far | No-Compression Mode\e[0m"

    # Define the Master DSP Chain
    # aexciter (Harmonics) -> asubboost (Sub-Synth) -> Far Matrix (1.3x/2.5x)
    CHAIN="aexciter=level_in=0.8:level_out=1.0:amount=5:drive=3,asubboost=dry=1.0:wet=0.8:cutoff=60,pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1,asplit=2[m_in][s_in];[m_in]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=1.5:g=2[m];[s_in]pan=mono|c0=c1,equalizer=f=12000:width_type=h:w=2:g=4[s];[m][s]amerge=inputs=2,pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1"

    # PASS 1: Find the Peak
    echo -e "\e[1;36m[Pass 1/2] Finding Peak Headroom...\e[0m"
    PEAK=$(nice -n 19 ffmpeg -nostdin -i "$SRC" -filter_complex "$CHAIN,volumedetect" -f null - 2>&1 | grep "max_volume" | awk '{print $5}')
    
    # Calculate fixed gain to hit -1.0dB Peak (Linear Scaling)
    # If peak is -10dB, we add +9dB. If peak is +5dB, we subtract 6dB.
    GAIN=$(python3 -c "print(round(-1.0 - float('$PEAK'), 1))")

    echo -e "\e[1;32m[Pass 2/2] Applying Static Gain: ${GAIN}dB...\e[0m"
    # PASS 2: Render with Static Gain + Safety Limiter (alimiter)
    # alimiter is only there as a 0.1dB safety net, it won't touch the sound.
    if nice -n 19 ffmpeg -nostdin -v error -y -threads 4 -i "$SRC" -filter_complex \
    "$CHAIN,volume=${GAIN}dB,alimiter=level_in=1:level_out=1:limit=0.95:attack=5:release=20" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"; then
        echo -e "\e[1;35mLINEAR MASTER COMPLETE. Auditing...\e[0m"
        bash ~/audit.sh "$OUT_FILE"
    fi
}
#Basically same as rip()
carve() {
    SRC=$(find_audio "$1")
    [ -z "$SRC" ] && return 1
    OUT_FILE="$PROC_DIR/Optimized_Masters/CARVED_$(basename "${SRC%.*}").flac"
    SR=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$SRC")

    echo -e "\e[1;34mSurgically Carving Side-Channel to Unmask Vocals...\e[0m"

    # THE MATRIX:
    # 1. Split into Mid and Side.
    # 2. Side (c1): Apply a sharp -6dB notch at 3kHz (vocal presence) to stop it masking the Mid.
    # 3. Mid (c0): Keep it heavy (1.3x).
    # 4. Re-merge.
    ffmpeg -v error -y -i "$SRC" -filter_complex \
    "[0:a]pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0-0.5*c1,asplit=2[mid_p][side_p]; \
     [mid_p]pan=mono|c0=c0[mid]; \
     [side_p]pan=mono|c0=c0,equalizer=f=3000:width_type=q:w=0.5:g=-6[side_carved]; \
     [mid][side_carved]amerge=inputs=2,pan=stereo|c0=1.3*c0+2.5*c1|c1=1.3*c0-2.5*c1,alimiter=limit=0.95" \
    -ar $SR -sample_fmt s32 -c:a flac "$OUT_FILE"
    echo -e "\e[1;32mDone.\e[0m"
}
#Runs audit repeatedly
audit_recursive() {
    # Find the folder in either the original or processed directory
    ROOT_PATH=$(find "/sdcard/Music" "$PROC_DIR" -type d -iname "$1" -print -quit 2>/dev/null)
    [ -z "$ROOT_PATH" ] && { echo -e "\e[1;31mError: Folder '$1' not found.\e[0m"; return 1; }

    echo -e "\e[1;35m--- STARTING RECURSIVE REPORT GENERATION: $1 ---\e[0m"
    
    shopt -s nullglob nocaseglob

    # Use print0 to handle spaces and brackets [] perfectly
    find "$ROOT_PATH" -type d -print0 | while IFS= read -r -d '' SUBDIR; do
        
        # Collect audio files in THIS specific folder only
        FILES=( "$SUBDIR"/*.flac "$SUBDIR"/*.mp3 "$SUBDIR"/*.opus "$SUBDIR"/*.m4a )
        
        # Skip if the current subfolder has no music
        if [ ${#FILES[@]} -eq 0 ]; then continue; fi

        REPORT="$SUBDIR/Loudness_Report.txt"
        echo "--- LOCAL LOUDNESS REPORT (116dB CALIBRATION) ---" > "$REPORT"
        echo "Location: $SUBDIR" >> "$REPORT"
        printf "\n%-35s | %-10s | %-10s | %-10s\n" "Song Name" "80dB Pre" "85dB Pre" "90dB Pre" >> "$REPORT"
        echo "-----------------------------------------------------------------------" >> "$REPORT"

        echo -e "\e[1;34mGenerating Report for:\e[0m ${SUBDIR#$ROOT_PATH/}"

        for src in "${FILES[@]}"; do
            filename=$(basename "$src")
            
            # Extract LUFS without keyboard interruption bug
            LUFS=$(ffmpeg -nostdin -i "$src" -af ebur128 -f null - 2>&1 | sed -n 's/.*I: *\([-0-9.]*\).*/\1/p' | tail -n 1)
            [ -z "$LUFS" ] && continue

            # Python math for the 3 target preamps (116dB Max)
            MATH=$(python3 -c "
l, h = float('$LUFS'), 116.0
def p(t): return round(t-(h+l), 1)
print(f'{p(80)}|{p(85)}|{p(90)}')")
            IFS='|' read -r P80 P85 P90 <<< "$MATH"

            printf "%-35.35s | %-10s | %-10s | %-10s\n" "${filename%.*}" "$P80" "$P85" "$P90" >> "$REPORT"
            echo -ne "   > Logged: ${filename:0:30}...\r"
        done
        echo -e "\n\e[1;32m   [Report Saved]\e[0m"
        
    done
    
    shopt -u nullglob
    echo -e "\n\e[1;35m=== ALL FOLDERS AUDITED ===\e[0m"
}
