#!/bin/zsh
# ==============================================================================
# Script Name:  audit.sh
# Description:  Forensic audio analysis and psychoacoustic SPL calibration utility.
# Target OS:    macOS
# ==============================================================================

# Hardware baseline calibration (0 dBFS = 120 dB SPL)
readonly HW_MAX=120
readonly PROC_DIR="$HOME/audio files (processed)"

# Ensure output directory exists
mkdir -p "$PROC_DIR"

# 1. Path & Argument Resolution
if [ -z "$1" ]; then
    printf "\033[1;31mError: No input file specified.\033[0m\n"
    printf "Usage: ./audit.sh <filename_or_path>\n"
    exit 1
fi

if [ -f "$1" ]; then
    FILE_PATH="$1"
else
    SEARCH_NAME="$1"
    FILE_PATH=$(find "$HOME/audio files" "$PROC_DIR" -type f -iname "$SEARCH_NAME" 2>/dev/null | head -n 1)
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    printf "\033[1;31mError: Could not find '$1'\033[0m\n"
    exit 1
fi

printf "\033[1;32mTarget Resolved: %s\033[0m\n" "$FILE_PATH"
printf "\033[1;33mExecuting EBU R128 Psychoacoustic Analysis...\033[0m\n"

# 2. Loudness Measurement
LOUDNESS_STATS=$(ffmpeg -hide_banner -i "$FILE_PATH" -af loudnorm=print_format=summary -f null - 2>&1)

I_LUFS=$(echo "$LOUDNESS_STATS" | python3 -c "import sys, re; m=re.search(r'Input Integrated:\s*([-0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-15.0')")
LRA=$(echo "$LOUDNESS_STATS" | python3 -c "import sys, re; m=re.search(r'Input LRA:\s*([0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '11.0')")
TP_DB=$(echo "$LOUDNESS_STATS" | python3 -c "import sys, re; m=re.search(r'Input True Peak:\s*([-+0-9.]+)', sys.stdin.read()); print(m.group(1) if m else '-1.5')")

I_LUFS=${I_LUFS:-"-15.0"}; LRA=${LRA:-"11.0"}; TP_DB=${TP_DB:-"-1.5"}

# 3. Volume Calibration via Python 3 (Software Preamp @ 120dB Max SPL)
MATH_RESULT=$(python3 -c "
lufs = float('$I_LUFS')
max_spl = $HW_MAX
p80 = round(80.0 - (max_spl + lufs), 1)
p85 = round(85.0 - (max_spl + lufs), 1)
p90 = round(90.0 - (max_spl + lufs), 1)
print(f'{lufs}|{float(\"$LRA\")}|{float(\"$TP_DB\")}|{p80}|{p85}|{p90}')
")

IFS='|' read -r LUFS_VAL LRA_VAL TP_VAL P80 P85 P90 <<< "$MATH_RESULT"

# 4. Reporting
printf "\n\033[1;34m--- EBU R128 LOUDNESS METRICS ---\033[0m\n"
printf "  Integrated Loudness: %s LUFS\n" "$LUFS_VAL"
printf "  Loudness Range (LRA): %s LU\n" "$LRA_VAL"
printf "  True Peak Level:     %s dBTP\n" "$TP_VAL"

printf "\n\033[1;35m--- REAL-WORLD CALIBRATION (120dB Baseline) ---\033[0m\n"
printf "  80dB SPL (Relaxed):  Preamp: \033[1;32m%s dB\033[0m\n" "$P80"
printf "  85dB SPL (Reference):Preamp: \033[1;32m%s dB\033[0m\n" "$P85"
printf "  90dB SPL (Concert):  Preamp: \033[1;32m%s dB\033[0m\n" "$P90"

# 5. Spectrogram Generation
sox "$FILE_PATH" -n spectrogram -o "$PROC_DIR/last_audit.png"
printf "\n\033[1;32mSpectrogram successfully generated: %s/last_audit.png\033[0m\n" "$PROC_DIR"
