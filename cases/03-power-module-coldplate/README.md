# Case 03 — Power-Module Cold-Plate Thermal Benchmark

**Status:** Tier 0/1 thermal-resistance and coolant-channel model complete. A resolved 3-D CHT model is the next fidelity, not a completed claim.

## Engineering decision

Can a cold plate keep a representative **650 W power module** below a junction-temperature target without excessive pump pressure loss? The model separates:

```text
junction → case → TIM → base/spreading → internal convection → bulk coolant
```

All values are **transparent generic design assumptions**, not supplier data or employer data.

## Model

```text
Tj = Tin + Q/(2 m_dot cp) + Q [Rjc + Rtim + Rspread + Rconv]
Rtim = t_TIM / (k_TIM A_TIM)
Rconv = 1 / (h A_wetted)
```

A six-channel rectangular cold plate is represented with hydraulic diameter, Reynolds number, a stated laminar/turbulent Nusselt correlation, and Darcy–Weisbach pressure loss. The point is to expose the engineering trade, not to claim a finished commercial geometry.

## First executed result

Baseline: 650 W loss, 35 °C inlet, 0.10 kg/s coolant flow, 3 W/m·K / 0.10 mm TIM.

| KPI | Result | Meaning |
|---|---:|---|
| Reynolds number | 2,020 | still laminar / near transition |
| Internal h | 400 W/m²·K | weak internal convection |
| Pressure loss | 0.30 kPa | very low—because flow is also weak |
| Coolant temperature rise | 1.76 K | not the main limitation |
| Predicted junction temperature | **139.0 °C** | cold plate is not adequate at this operating point |

This is the initial design decision: raising flow must be assessed with its pressure-loss cost; merely choosing a high-conductivity TIM cannot compensate for poor convection. A sweep at 0.20 kg/s with 6 W/m·K, 0.05 mm TIM gives 71.9 °C in this *generic model* at 1.52 kPa. That is a direction for design exploration, not a production recommendation.

## Reproduce

```bash
python cases/03-power-module-coldplate/tools/power_module_coldplate.py
```

The script writes a 72-point sweep of flow, TIM conductivity and TIM thickness.

## Next fidelity

A 3-D CHT study would resolve manifold maldistribution, local base spreading, channel geometry, module footprint, interface non-uniformity and temperature-dependent coolant properties. Its acceptance data would be a module thermal test and measured pressure-flow curve.
