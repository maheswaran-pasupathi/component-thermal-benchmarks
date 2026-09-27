# Case 02 — HV Cable, Lug & Junction-Box Electro-Thermal Benchmark

**Status:** Tier 0 analytical and Tier 1 1-D electro-thermal model complete. 3-D CHT is deliberately a next stage, not claimed here.

## Engineering decision

Select a high-voltage cable section for a representative 600 V battery-electric power path while respecting continuous temperature, transient overload, voltage-drop and mass constraints. The component boundary includes the cable conductor, insulation/jacket, lugs and the thermal influence of the two junction boxes.

This is a **generic, representative benchmark**. No employer or programme data are used.

## Why it belongs in a component benchmark library

A cable termination, busbar joint or connector is an electro-thermal component problem: electrical current creates `I²R` heat; resistance rises with temperature; conduction, convection and radiation set the allowable current; contact resistance can create a local hot spot. The benchmark separates what a quick sizing calculation can decide from what needs a 1-D network or 3-D CHT.

## Tiers and evidence

| Tier | Model | Physics added | Evidence / outcome |
|---|---|---|---|
| 0 | Python steady radial heat balance | temperature-dependent resistance; insulation conduction; Churchill–Chu natural convection; grey-body radiation | 185 mm² Al: 533 A continuous at 85 °C ambient; passes 500 A with ~33 A margin |
| 1 | OpenModelica axial RC network | 20 axial sections; thermal mass; live convection/radiation; zoned ambient; lug `I²R`; junction-box heat sinking; mission current | 535 A steady ampacity (0.5% vs Tier 0); a 667 A / 3-minute peak reaches 150.6 °C, making 185 mm² Al borderline |
| 2 | Planned 3-D CHT | resolved lug/busbar/housing; contact resistance; airflow and radiation view factors | use only after the 1-D model identifies the governing uncertainty |

## Tier 0 equations

For a conductor section \(A\), the temperature-dependent resistance per length is:

```text
R'(T) = rho20 [1 + alpha (T - 20 °C)] / A
q'(T) = I² R'(T)
```

At the conductor temperature limit, the radial path is solved iteratively:

```text
q' = (T_conductor - T_ambient) / (R'_insulation + R'_surface)
R'_surface = 1 / [pi D_outer (h_convection + h_radiation)]
```

The code uses Churchill–Chu for natural convection around the horizontal cable and a linearised grey-body radiation coefficient. The case is transparent rather than tied to a solver licence.

## Results

### Candidate selection — 85 °C still air, 150 °C conductor limit

| Candidate | Continuous ampacity | Verdict at 500 A |
|---|---:|---|
| 150 mm² Al | 463 A | fail |
| **185 mm² Al** | **533 A** | **pass** |
| 240 mm² Al | 635 A | pass, larger mass |
| 120 mm² Cu | 514 A | pass, much higher conductor mass |

### Decision changed by transient system context

The steady calculation selects 185 mm² Al. The 1-D mission model shows the peak arrives after sustained rated load, giving little thermal-mass credit: the mid-span conductor reaches **150.6 °C**. The correct engineering decision is therefore not a false “pass”:

- retain 185 mm² Al only with a measured peak-current trace and installed airflow;
- otherwise select 240 mm² Al at design freeze;
- resolve lug/contact hot spots and the real convection environment with a 3-D CHT case only if they govern the decision.

The completed 1-D network also shows a different risk: a representative 95 mm² Cu inverter-to-motor phase cable is over temperature (about 161 °C), while short auxiliary PDU branches are not thermally limiting. This is the useful system-level result: **the worst cable is not necessarily the longest DC cable.**

## Reproduce Tier 0

```bash
pip install numpy matplotlib
python cases/02-hv-cable-lug-electrothermal/tools/verify_tier0.py
python cases/02-hv-cable-lug-electrothermal/tools/tier0_sweep.py
```

The sweep writes a candidate table and sensitivity plot. Inputs are representative design assumptions and must be replaced for any real programme.

## Scope and limitations

- This case does **not** claim a completed IGBT, MOSFET or PCB thermal model.
- Cable geometry, ambient and duty cycle are representative; no proprietary values are used.
- The Tier 0 code is a transparent engineering sizing model, not a substitute for installation-specific qualification.
- Tier 1 results are reported as a model result and clearly retain uncertainty in airflow, contact resistance and mission duty.
- The planned 3-D CHT model should resolve the smallest geometry that drives the decision: lug/busbar/housing plus local air domain—not an unnecessarily large vehicle model.
