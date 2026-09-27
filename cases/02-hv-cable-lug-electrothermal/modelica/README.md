# Tier 1 — OpenModelica 1-D electro-thermal model

## Run

```
cd tools/tier1_modelica
omc run_tier1.mos          # builds + simulates SteadyValidation, AmpacityCheck, Mission
python analyze_tier1.py    # cross-checks vs Tier 0, writes ../../results/tier1_results.png
```

Needs OpenModelica (tested on 1.26.3) with the Modelica Standard Library 4.x, and
Python with numpy / pandas / matplotlib.

## Models in `HVCableTier1.mo`

| Model | Purpose |
|---|---|
| `CableAxial` | the reusable component — N axial RC-stack segments, temperature-dependent conductor resistance, Churchill–Chu convection + radiation, optional axial conduction and junction-box heat sinks, current as a `RealInput` |
| `SteadyValidation` | axial/JB off, uniform 85 °C, constant 500 A — must reproduce the Tier 0 steady conductor temperature |
| `AmpacityCheck` | a slow integral loop holds the mid node at 150 °C and reports the current → the Tier 1 continuous ampacity |
| `Mission` | full model: axial conduction, both junction boxes, zoned ambient, driven by a representative mission current profile → `T_c(x, t)`, hot spot, peak, cycle `ΔV` |

## Key parameters (all on `CableAxial`, representative — not measured MAN data)

| | value | |
|---|---|---|
| `A` | 185e-6 m² | conductor cross-section |
| `d_c`, `d_out` | 15.35, 21.35 mm | conductor / cable-over-jacket diameters |
| `rho20`, `alpha` | 2.84e-8 Ω·m, 0.00403 /K | Al resistivity + tempco |
| `k_ins` | 0.29 W/m·K | combined insulation + jacket |
| `T_amb_zone` | array[N] | per-station ambient (default 85 °C) |
| `axialConduction`, `junctionBoxes` | Boolean | set both false + uniform ambient to recover Tier 0 |
| `R_contact` | 30e-6 Ω | lug contact resistance per joint |

Results and the engineering discussion: [`../../docs/tier1-results.md`](../../docs/tier1-results.md).
