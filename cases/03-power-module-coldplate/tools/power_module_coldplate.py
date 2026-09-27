"""Representative power-module cold-plate thermal-resistance benchmark.

No supplier geometry or employer data. The aim is to show the trade-off between
junction temperature, TIM specification and coolant-side pressure drop.
"""
from math import pi
import csv

Q, T_IN = 650.0, 35.0
R_JC, R_SPREAD = 0.025, 0.020
L_CH, N_CH, W_CH, H_CH = 0.180, 6, 0.003, 0.008
RHO, MU, K, CP = 1040.0, 1.5e-3, 0.40, 3700.0
PR, AREA_TIM = MU * CP / K, 0.004

def coldplate(mdot):
    dh = 4 * W_CH * H_CH / (2 * (W_CH + H_CH))
    flow_area = N_CH * W_CH * H_CH
    velocity = mdot / (RHO * flow_area)
    re = RHO * velocity * dh / MU
    nu = 4.36 if re < 2300 else 0.023 * re**0.8 * PR**0.4
    h = nu * K / dh
    wetted_area = N_CH * 2 * (W_CH + H_CH) * L_CH
    r_conv = 1 / (h * wetted_area)
    f = 64 / re if re < 2300 else 0.3164 / re**0.25
    dp = f * (L_CH / dh) * RHO * velocity**2 / 2
    return re, h, r_conv, dp

def solve(mdot=0.10, tim_k=3.0, tim_t=0.10e-3):
    r_tim = tim_t / (tim_k * AREA_TIM)
    re, h, r_conv, dp = coldplate(mdot)
    coolant_rise = Q / (mdot * CP)
    r_total = R_JC + r_tim + R_SPREAD + r_conv
    tj = T_IN + 0.5 * coolant_rise + Q * r_total
    return dict(mdot_kg_s=mdot, tim_k_W_mK=tim_k, tim_t_mm=tim_t*1e3,
                Re=re, h_W_m2K=h, dp_kPa=dp/1000,
                coolant_rise_K=coolant_rise, R_total_K_W=r_total, Tj_C=tj)

base = solve()
print("Baseline cold-plate result")
for key, value in base.items():
    print(f"{key:18s} {value:.3f}")

rows = [solve(mdot, k_tim, t_tim)
        for mdot in (0.03, 0.05, 0.07, 0.10, 0.15, 0.20)
        for k_tim in (1.0, 2.0, 3.0, 6.0)
        for t_tim in (0.05e-3, 0.10e-3, 0.20e-3)]
with open("coldplate_sweep.csv", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys())
    writer.writeheader(); writer.writerows(rows)
print("wrote coldplate_sweep.csv")
