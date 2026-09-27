import numpy as np

SIGMA = 5.670374e-8
g = 9.81

def air_props(Tf_K):
    k = 0.0243 + 7.7e-5*(Tf_K-300)
    nu = 1.57e-5 + 1.10e-7*(Tf_K-300)
    Pr = 0.712 - 1.6e-4*(Tf_K-300)
    rho = 101325/(287.05*Tf_K)
    return k, nu, Pr, k/(rho*1007.0), 1.0/Tf_K

def churchill_chu(Ra, Pr):
    return (0.60 + 0.387*Ra**(1/6)/(1 + (0.559/Pr)**(9/16))**(8/27))**2

def solve(A_mm2, rho20, alpha, d_ins_mm, d_jkt_mm, k_ins, Tamb_C=85.0, Tlim_C=150.0, eps=0.9, L_m=9.0, I_rated=500.0):
    A = A_mm2*1e-6
    dc = np.sqrt(4*A/np.pi)
    dout = dc + 2*d_ins_mm*1e-3 + 2*d_jkt_mm*1e-3
    Tamb, Tlim = Tamb_C + 273.15, Tlim_C + 273.15
    Rp20 = rho20/A
    Rp_lim = Rp20*(1 + alpha*(Tlim_C - 20))
    Rp_ins = np.log(dout/dc)/(2*np.pi*k_ins)
    Ts = Tlim - 10
    for _ in range(60):
        k, nu, Pr, a, beta = air_props(0.5*(Ts + Tamb))
        Ra = g*beta*max(Ts-Tamb, 1e-6)*dout**3/(nu*a)
        h = churchill_chu(Ra, Pr)*k/dout + eps*SIGMA*(Ts**2 + Tamb**2)*(Ts + Tamb)
        Rp_surf = 1/(np.pi*dout*h)
        Qp = (Tlim-Tamb)/(Rp_ins+Rp_surf)
        Ts_new = Tlim-Qp*Rp_ins
        if abs(Ts_new-Ts)<1e-4: break
        Ts = Ts_new
    I_amp = np.sqrt(Qp/Rp_lim)
    return I_amp

AL = dict(rho20=2.84e-8, alpha=0.00403)
CU = dict(rho20=1.72e-8, alpha=0.00393)
cases = [("150 Al",150,AL,1.7,1.2),("185 Al",185,AL,1.8,1.2),("240 Al",240,AL,1.9,1.3),("120 Cu",120,CU,1.7,1.2)]
for name, A, mat, ti, tj in cases:
    print(f"{name:8}: {solve(A, mat['rho20'], mat['alpha'], ti, tj, 0.29):.0f} A")
