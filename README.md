# Forensic Sonic Overclocking (FSO)
> A Termux-based Digital Signal Processing (DSP) and Psychoacoustic Analysis Suite for Mobile Environments.

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
