"""Analyse the Tier 1 OpenModelica results and cross-check against Tier 0."""
import numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
import os

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(HERE, "..", "..", "results")
os.makedirs(RES, exist_ok=True)
K = 273.15
N = 20
L = 4.5
x = (np.arange(N) + 0.5) * (L / N)

def load(name):
    return pd.read_csv(os.path.join(HERE, f"{name}_res.csv"))

# ---------- 1. Steady validation vs Tier 0 ----------
s = load("SteadyValidation")
Tc_mid = s["cable.T_c_mid"].iloc[-1] - K
Tc_max = s["cable.T_c_max"].iloc[-1] - K
ploss  = s["cable.P_loss"].iloc[-1]
dv     = s["cable.dV"].iloc[-1]
print("=== SteadyValidation (500 A, uniform 85 C, no axial / JB) ===")
print(f"  steady T_c        : {Tc_mid:6.1f} degC   (Tier 0: ~140-142 degC)")
print(f"  Joule loss (1 cbl): {ploss:6.1f} W/ ({ploss/L:.1f} W/m)   (Tier 0: ~57 W/m)")
print(f"  voltage drop      : {dv:6.2f} V over {L} m  (Tier 0 full 9 m: ~1.0 V -> ~0.5 V per run)")

# ---------- 2. Ampacity ----------
a = load("AmpacityCheck")
I_amp = a["I_amp"].iloc[-1]
Tset  = a["cable.T_c_mid"].iloc[-1] - K
print("\n=== AmpacityCheck (feedback to 150 C) ===")
print(f"  settled current   : {I_amp:6.1f} A   (Tier 0: ~533 A)")
print(f"  mid node held at  : {Tset:6.1f} degC")
print(f"  delta vs Tier 0   : {100*(I_amp-533)/533:+.1f} %  (acceptance: within 3 %)")

# ---------- 3. Mission ----------
m = load("Mission")
tcols = [f"cable.cond[{k+1}].T" for k in range(N)]
Tfield = m[tcols].values - K            # (nt, N)
t = m["time"].values
Imis = m["cable.I_cable"].values
peak = Tfield.max()
it, ix = np.unravel_index(np.argmax(Tfield), Tfield.shape)
print("\n=== Mission (representative duty, zoned ambient, axial + JB) ===")
print(f"  peak T_c          : {peak:6.1f} degC at t={t[it]:.0f} s, x={x[ix]:.2f} m "
      f"(segment {ix+1}/{N})")
print(f"  limit 150 degC    : {'REACHED' if peak >= 150 else 'not reached'} "
      f"-> 185 mm2 Al {'FAILS' if peak >= 150 else 'passes'} this mission")
print(f"  end-of-run T_c mid: {Tfield[-1, N//2]:.1f} degC")
print(f"  JB heat sinking   : end seg {Tfield[-1,0]:.1f} / {Tfield[-1,-1]:.1f} degC "
      f"vs mid {Tfield[-1,N//2]:.1f} degC")
print(f"  cycle max dV      : {m['cable.dV'].abs().max():.2f} V (one cable)")

# ---------- plots ----------
fig, ax = plt.subplots(1, 3, figsize=(16, 4.6))

ax[0].plot(s["time"]/60, s["cable.T_c_mid"]-K, label="Tier 1 mid node")
ax[0].axhline(140, ls="--", c="grey", label="Tier 0 (~140 degC)")
ax[0].axhline(150, ls=":", c="firebrick", label="limit 150 degC")
ax[0].set_title("Steady validation - 500 A, still air 85 degC")
ax[0].set_xlabel("time [min]"); ax[0].set_ylabel("conductor T [degC]")
ax[0].legend(fontsize=8); ax[0].grid(alpha=.3)

axb = ax[1].twinx()
axb.plot(t/60, Imis, c="grey", alpha=.35, lw=1)
axb.set_ylabel("cable current [A]", color="grey")
for kk, lbl in [(0, "segment 1 (front JB end)"),
                (N//2 - 1, "segment 10 (mid-span)"),
                (N - 1, "segment 20 (rear JB end)")]:
    ax[1].plot(t/60, Tfield[:, kk], label=lbl)
ax[1].axhline(150, ls=":", c="firebrick")
ax[1].set_title("Mission - conductor T vs time")
ax[1].set_xlabel("time [min]"); ax[1].set_ylabel("conductor T [degC]")
ax[1].legend(fontsize=8, loc="lower right"); ax[1].grid(alpha=.3)

# axial profile at a few times
for frac in [0.25, 0.5, 0.58, 1.0]:
    ti = int(frac*(len(t)-1))
    ax[2].plot(x, Tfield[ti], marker="o", ms=3, label=f"t={t[ti]/60:.0f} min")
ax[2].axhline(150, ls=":", c="firebrick", label="limit")
ax[2].set_title("Mission - axial temperature profile")
ax[2].set_xlabel("distance from front JB [m]"); ax[2].set_ylabel("conductor T [degC]")
ax[2].legend(fontsize=8); ax[2].grid(alpha=.3)

plt.tight_layout()
out = os.path.join(RES, "tier1_results.png")
plt.savefig(out, dpi=130)
print("\nwrote", out)

# small CSV summary
pd.DataFrame({
    "x_m": x,
    "T_c_end_of_mission_C": Tfield[-1],
    "T_c_peak_over_mission_C": Tfield.max(axis=0),
}).to_csv(os.path.join(RES, "tier1_axial_profile.csv"), index=False)
print("wrote", os.path.join(RES, "tier1_axial_profile.csv"))
