# PID Control Design for Power Factor Correction in an AC–DC Boost Converter

> **Kesavaraj K, Gowtham J, Bala Subramanian S, Jeevika V**  
> Department of Electrical and Electronics Engineering  
> KPR Institute of Engineering and Technology, Coimbatore, Tamil Nadu, India

---

## Abstract

A dual-loop PID-controlled boost-type PFC stage that forces the input current to follow the rectified line voltage while holding the 400 V output bus steady. Built as an averaged continuous-time model in MATLAB/Simulink at 230 V, 50 Hz input with an 800 W resistive load switching at 100 kHz. The closed-loop system settles to a mean output of 400.25 V (0.062% regulation error) with 14.32 V peak-to-peak ripple, an input power factor of 0.9412 and a current THD of 20.38%.

---

## System Architecture

The control follows an average-current-mode structure with two nested loops:

- **Outer Voltage Loop** — compares sensed Vout against 400 V reference; output sets the amplitude of the current template
- **Inner Current Loop** — multiplies voltage loop output by normalized rectified AC to form iref; forces iL to track iref at every switching instant
- **Control Law** — PI compensator in both loops: `C(s) = Kp + Ki/s` (Kd = 0)

---

## Design Specifications

| Parameter | Value |
|-----------|-------|
| Input voltage | 230 V rms, 50 Hz |
| Output voltage | 400 V DC |
| Rated load | 800 W (200 Ω) |
| Switching frequency | 100 kHz |
| Output capacitor | 470 µF |
| Boost inductor | L (averaged model) |
| Target power factor | ≥ 0.95 |
| Target THD | ≤ 8% (IEC 61000-3-2 Class A) |
| Output regulation | ≤ 1% steady-state error |

---

## PID Gains

| Loop | Kp | Ki | Kd | N |
|------|----|----|----|---|
| Voltage (outer) | 0.15 | 8.0 | 0 | 10 |
| Current (inner) | 2.5 | 500 | 0 | 1000 |

---

## Mathematical Model

**Averaged boost converter state equations:**

```
L · diL/dt   = vin(t) − (1 − d(t)) · vout(t)
C · dvout/dt = (1 − d(t)) · iL(t) − vout(t) / R
```

**Current reference generation:**

```
iref(t) = Gnorm · |vin(t)| · uv(t)
```

**Power factor decomposition:**

```
PF  = DF × DPF
DF  = I1 / Irms
DPF = cos(φ1)
THD = sqrt(sum(Ih²)) / I1    for h = 2, 3, ...
DF  = 1 / sqrt(1 + THD²)
```

---

## Simulated Performance

| Metric | Value |
|--------|-------|
| Mean output voltage | 400.25 V |
| Output regulation error | 0.062% |
| Output ripple (pk-pk) | 14.32 V |
| True power factor | 0.9412 |
| Displacement power factor | ≈ 0.99 |
| Current THD | 20.38% |
| Peak overshoot (start-up) | ≈ 17.5% (470 V peak) |
| Settling time (±2% of 400 V) | ≈ 24 ms |
| IEC 61000-3-2 Class A | Not met (THD > 8%) |

---

## Comparison with Literature

| Method | Reference | PF | THD |
|--------|-----------|----|-----|
| Fixed-gain dual PID (this work) | — | 0.9412 | 20.38% |
| Modulated-carrier control | Kim et al., 2018 | > 0.99 | not reported |
| PSO-tuned fractional PI | Demirtas & Ahmad, 2023 | ≈ 0.99 | below PI baseline |
| MPSO-tuned 4-param PID | Guarnizo et al., 2023 | improved | not directly stated |
| GWO-tuned FOPID | Lai & Wang, 2024 | — | below integer PID |
| GEO-tuned fractional PI | Vijayakumar & Sudhakar, 2024 | high | 1.85% |

---

## Key Findings

- Fixed-gain PID achieves **excellent voltage regulation (0.062%)** and **near-unity displacement PF (≈ 0.99)**
- THD shortfall (20.38%) traced to **current-shape flattening near AC zero crossings**
- Averaged model omits **saturation and anti-windup** — real hardware transients may differ
- Dual-loop architecture is **upgrade-compatible** with fractional-order or metaheuristic compensators without structural redesign

---

## Future Work

- PSO / GWO metaheuristic gain tuning (following Guarnizo et al., Lai & Wang)
- Fractional-order PID extension (FOPID) for improved THD
- Feedforward of rectified line voltage near zero crossings
- Switched device-level Simulink model with dead-time, ripple and anti-windup
- Hardware-in-the-loop or physical prototype validation
- Bridgeless / interleaved power stage extension

---

## Requirements

- MATLAB R2025a
- Simulink
- Control System Toolbox

---

## References

| # | Citation |
|---|----------|
| [1] | Ortiz-Castrillón et al., *Applied Sciences*, 2021 |
| [2] | Chen, Davari & Wang, *IEEE Trans. Power Electron.*, 2020 |
| [3] | Kim, Choi & Won, *IEEE Trans. Power Electron.*, 2018 |
| [4] | Espitia, *Technologies*, 2025 |
| [5] | Ortatepe & Karaarslan, *IET Power Electron.*, 2020 |
| [6] | Ibrahim, *Int. J. Power Electron. Drive Syst.*, 2023 |
| [9] | Romero et al., *IEEE CCAC*, 2021 |
| [10] | Guarnizo et al., *Automatika*, 2023 |
| [11] | Demirtas & Ahmad, *IJOCTA*, 2023 |
| [13] | Lai & Wang, *Int. J. Dyn. Control*, 2024 |
| [15] | Vijayakumar & Sudhakar, *Sci. Rep.*, 2024 |
| [22] | González-Castaño et al., *Sensors*, 2021 |
| — | IEC 61000-3-2: Limits for Harmonic Current Emissions |
| — | IEEE Std 519-2014: Harmonic Control in Electric Power Systems |