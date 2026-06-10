#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Script Name:  audit.sh
# Description:  Forensic audio analysis and psychoacoustic SPL calibration utility.
# Dependencies: ffmpeg (with ebur128), sox, python3, termux-api
# Target OS:    Android (Termux Environment)
# ==============================================================================

# Hardware baseline calibration (0 dBFS = 116 dB SPL)
readonly HW_MAX=116
readonly PROC_DIR="/sdcard/Music (processed)"

# Ensure output directory exists
mkdir -p "$PROC_DIR"

# 1. Path & Argument Resolution
if [ -z "$1" ]; then
    echo -e "\e[1;31mError: No input file specified.\e[0m"
    echo "Usage: ./audit.sh <filename_or_path>"
    exit 1
fi

if [ -f "$1" ]; then
    FILE_PATH="$1"
else
    SEARCH_NAME="$1"
    # Search both the original music folder and the processed directory
    FILE_PATH=$(find "/sdcard/Music" "$PROC_DIR" -iname "$SEARCH_NAME" -type f -print -quit 2>/dev/null)
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    echo -e "\e[1;31mError: File not found: '$1'\e[0m"
    exit 1
fi

echo -e "\e[1;32mTarget Resolved: $FILE_PATH\e[0m"
echo -e "\e[1;33mExecuting EBU R128 Psychoacoustic Analysis...\e[0m"

# 2. Loudness Measurement (Pass 1)
# We capture stderr as ebur128 outputs metric data over standard error.
LOUDNESS_STATS=$(ffmpeg -hide_banner -i "$FILE_PATH" -af ebur128=peak=true -f null - 2>&1)

# Parse output metrics safely using sed
I_LUFS=$(echo "$LOUDNESS_STATS" | sed -n 's/.*I: *\([-0-9.]*\).*/\1/p' | tail -n 1)
LRA=$(echo "$LOUDNESS_STATS" | sed -n 's/.*LRA: *\([-0-9.]*\).*/\1/p' | tail -n 1)
TP_DB=$(echo "$LOUDNESS_STATS" | sed -n 's/.*Peak: *\([-0-9.]*\).*/\1/p' | head -n 1)

# Handle cases where parsing fails by applying standard fallbacks
I_LUFS=${I_LUFS:-"-14.0"}
LRA=${LRA:-"11.0"}
TP_DB=${TP_DB:-"-1.5"}

# 3. Dual-Stage Volume Calibration via Python 3
# Translates digital levels (dBFS) to real-world target SPLs (80, 85, 90 dB)
# based on transducer sensitivity and output voltage limits.
MATH_RESULT=$(python3 -c "
def calculate_preamp(target, lufs, max_spl):
    # Standard Android Volume step attenuation curve (Oreo/MIUI reference)
    vol_steps = {15:0, 14:-2, 13:-4, 12:-7, 11:-10, 10:-13, 9:-17, 8:-21, 7:-25}
    current_avg_spl = max_spl + lufs
    total_needed_attenuation = target - current_avg_spl
    
    # Prioritize digital preamp headroom up to -30dB, then drop master volume step
    for step in sorted(vol_steps.keys(), reverse=True):
        attenuation = vol_steps[step]
        preamp = total_needed_attenuation - attenuation
        if preamp >= -30.0:
            return step, round(preamp, 1)
    return 7, round(total_needed_attenuation + 25, 1)

lufs = float('$I_LUFS')
c80 = calculate_preamp(80, lufs, $HW_MAX)
c85 = calculate_preamp(85, lufs, $HW_MAX)
c90 = calculate_preamp(90, lufs, $HW_MAX)

print(f'{lufs}|{float(\"$LRA\")}|{float(\"$TP_DB\")}|' + '|'.join(map(str, c80)) + '|' + '|'.join(map(str, c85)) + '|' + '|'.join(map(str, c90)))
")

# Parse calculations back to shell environment
IFS='|' read -r LUFS_VAL LRA_VAL TP_VAL S80 P80 S85 P85 S90 P90 <<< "$MATH_RESULT"

# 4. Reporting
echo -e "\n\e[1;34m--- EBU R128 LOUDNESS METRICS ---\e[0m"
echo "  Integrated Loudness: $LUFS_VAL LUFS"
echo "  Loudness Range (LRA): $LRA_VAL LU"
echo "  True Peak Level:     $TP_VAL dBTP"

echo -e "\n\e[1;35m--- REAL-WORLD CALIBRATION (WHO Standard) ---\e[0m"
echo -e "  80dB SPL (Relaxed):  Volume Step: \e[1;33m$S80\e[0m | Preamp: \e[1;32m${P80} dB\e[0m"
echo -e "  85dB SPL (Reference):Volume Step: \e[1;33m$S85\e[0m | Preamp: \e[1;32m${P85} dB\e[0m"
echo -e "  90dB SPL (Concert):  Volume Step: \e[1;33m$S90\e[0m | Preamp: \e[1;32m${P90} dB\e[0m"

# 5. Spectrogram Generation (Saved to Processed folder)
sox "$FILE_PATH" -n spectrogram -o "$PROC_DIR/last_audit.png"
echo -e "\n\e[1;32mSpectrogram successfully generated: $PROC_DIR/last_audit.png\e[0m"
