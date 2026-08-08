# Forensic Sonic Overclocking (FSO)
> A Termux-based Digital Signal Processing (DSP) and Psychoacoustic Analysis Suite for Mobile Environments.

Repository: [harshv-iit/Forensic-Sonic-Overclocking](https://github.com/harshv-iit/Forensic-Sonic-Overclocking)

## Overview
**Forensic Sonic Overclocking (FSO)** is a command-line utility suite designed for advanced audio signal analysis, hardware-matched calibration, and custom spatial field reconstruction. 

By utilizing **Mid/Side (M/S) matrix algebra**, **EBU R128 loudness standards**, and **asymmetric phase rotation**, the suite bypasses the standard, flat stereo limitations of commercial audio players. It calibrates the digital output specifically to high-performance transducers (e.g., single dynamic Beryllium-plated drivers) operating within hardware-limited voltage constraints.

---

## Key Engineering Features
* **Linear-Impact Mid/Side Processing:** Decouples stereo tracks into Mid ($L+R$) and Side ($L-R$) components. It applies non-linear spatial expansion up to 5.0x while stabilizing the central mono anchor (1.3x - 2.5x gain) to prevent center-channel acoustic masking.
* **Dual-Pass Psychoacoustic Normalization:** Utilizes EBU R128 algorithms to perform dual-pass linear loudness normalization (targeting -14 to -18 LUFS). This prevents active gain-riding (pumping) and eliminates inter-sample peaks (True Peak clipping).
* **Hardware-Matched SPL Calibration:** Translates digital full-scale levels (0 dBFS) to physical Sound Pressure Level (dB SPL) based on real-world output limits (calibrated to a ~0.6Vrms hardware limit and 120dB/Vrms transducer sensitivity).
* **Asymmetric Phase Rotation:** Implements high-frequency all-pass filtering ($\approx 12\text{kHz}$) to rotate high-frequency phase, creating perceived spatial depth without altering the frequency response.

---

## System Architecture & Signal Flow

```
[Stereo Input] ──> [M/S Split] ──> [Mid Channel]  ──> [3kHz Eq / Gain Boost] ──┐
                                                                              ├──> [Sum & Decode L/R] ──> [Linear Loudnorm] ──> [24-bit FLAC]
                                   [Side Channel] ──> [12kHz Eq / 5x Expansion] ─┘
```

### Script Inventory
* `audit.sh`: Performs EBU R128 analysis, generates a real-time spectrogram (via SoX), and outputs the required digital/hardware volume steps to hit exact SPL targets (80dB, 85dB, 90dB).
* `far`: High-resolution daily mastering tool (2.5x Side / 1.3x Mid).
* `uw`: Asymmetric 5.0x "Ultra-Wide" spatializer with a heavy 2.5x center anchor.
* `sg`: 100x "Singularity" forensic analysis tool used to extract low-level studio room reflections and high-frequency quantization noise.
* `rip`: Splits and exports a track into isolated `CENTER_STEREO` (mono-summed) and `SIDE_STEREO` (180-degree out-of-phase) components.
* `uw_album` / `far_album`: Multi-thread safe batch album processors featuring real-time stopwatches, auto-resume logging, and automatic directory creation.
* `audit_recursive`: Walks through directory structures and automatically generates local `Loudness_Report.txt` files inside each sub-album directory.

---

## Installation & Setup

### Prerequisites
The environment is designed to operate within the **Termux** environment on Android (ARM64 architecture).

```bash
# Update repositories and install required binary packages
pkg update && pkg upgrade
pkg install ffmpeg sox python bc coreutils

# Install Python-based metadata scraper
pip install syncedlyrics
```

### Deployment
Clone this repository to your Termux home directory and link the functions:

```bash
git clone https://github.com/harshv-iit/Forensic-Sonic-Overclocking.git ~/FSO
chmod +x ~/FSO/audit.sh

# Append functions to your shell configuration
cat ~/FSO/bashrc_additions >> ~/.bashrc
source ~/.bashrc
```

---

## Technical Constraints & Mobile Optimizations
To successfully run complex floating-point DSP on budget mobile processors (e.g., Snapdragon 625), several system-level optimizations were implemented:
* **Thread Throttling:** Capped FFmpeg execution to 4 threads (`-threads 4`) to prevent system cache congestion and stay within the physical memory limits of 4GB RAM devices.
* **Thermal Mitigation:** Embedded automatic kernel sleep periods (`sleep 3`) between batch processes to allow thermal dissipation and prevent CPU throttling.
* **Low-Priority Scheduling:** Invoked Unix process priority scheduling (`nice -n 19`) to ensure background processing does not interfere with the host system's audio playback engines.
* **Metadata Integrity:** Bypassed standard output pipe redirections during conversion, ensuring the output container writes absolute metadata headers (preventing integer overflow bitrate errors in local media players).

##Note:v1.0-android is a cut-down version of the original code

---
## License
This project is licensed under the MIT License - see the LICENSE file for details.
