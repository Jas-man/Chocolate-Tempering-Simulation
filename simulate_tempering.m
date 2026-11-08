function res = simulate_tempering(design, cfg)
%SIMULATE_TEMPERING  Heat transfer + simplified crystallisation kinetics.
%
%   res = simulate_tempering(design, cfg)
%
%   WHAT IS MODELLED  (all assumptions are listed in README.md)
%   --------------------------------------------------------------------
%   States (integrated with fixed-step 4th-order Runge-Kutta, dt = 1 s):
%     T   chocolate temperature (lumped, perfectly mixed)            [degC]
%     Tj  jacket-fluid temperature                                   [degC]
%     xV  stable (Form V) crystals, fraction of a fixed capacity     [-]
%     xU  unstable crystals, fraction of the same capacity           [-]
%
%   Heat transfer
%     M*cp*dT/dt  = UA(N)*(Tj - T) + P_shaft(N) + Q_latent
%     Cj*dTj/dt   = Q_util - UA(N)*(Tj - T) - UA_amb*(Tj - T_amb)
%     Q_util      = clip( Kc*(setpoint - Tj), -Q_cool_max, +Q_heat_max )
%     UA(N)       = UA_min + (UA_ref - UA_min)*(N/N_ref)^0.67
%     P_shaft(N)  = P_ref*(N/N_ref)^3          (all dissipated as heat)
%     Q_latent    = M*dH*(dxV/dt + dxU/dt)     (crystallising releases heat)
%
%   Crystallisation, for each population i in {V, U}  (autocatalytic growth
%   from a small nucleation term, bounded by the free capacity, plus melting):
%     s_i      = max(0, (Tm_i - T)/dT_ref)               driving force
%     mob(T)   = 1/(1+exp(-(T - T_visc)/w_visc))         sluggish when cold
%     growth_i = k_i * s_i^order * mob * (x_i + nuc_i*(1+g*N/N_ref)) * (1-xV-xU)
%     melt_i   = k_melt * max(0, T - Tm_i) * x_i
%     dx_i/dt  = (growth_i - melt_i)/60                  (rates in 1/min)
%
%   Energy (electrical):
%     heating  = integral of positive Q_util
%     cooling  = integral of negative Q_util, divided by chiller COP
%     stirring = integral of P_shaft, divided by motor efficiency
%
%   The chocolate and jacket start fully melted at cfg.proc.T0_C.  The
%   energy needed to melt/hold the chocolate BEFORE t = 0 is not counted.
%
%   Output RES contains time series (column vectors) and totals.
if nargin < 2, cfg = tempering_config(); end
[design, warn] = validate_design(design, cfg);
p   = cfg.proc;
kin = cfg.kin;
dt  = cfg.sim.dt_s;

dur_s  = design.duration_min * 60;          % stage durations [s]
edges  = cumsum(dur_s);                     % stage end times [s]
t_end  = edges(end);
nStep  = round(t_end / dt);
lastActive = find(dur_s > 0, 1, 'last');

t   = (0:nStep)' * dt;                      % [s]
Y   = zeros(nStep+1, 4);
Qu  = zeros(nStep+1, 1);
Psh = zeros(nStep+1, 1);
SP  = zeros(nStep+1, 1);
ST  = zeros(nStep+1, 1);

y = [p.T0_C; p.T0_C; 0; 0];
for i = 1:nStep+1
    s = find(t(i) < edges, 1, 'first');     % stage active at this instant
    if isempty(s), s = lastActive; end
    sp = design.setpoint_C(s);
    N  = design.stir_rpm(s);

    [k1, Q, Ps] = rates(y, sp, N, p, kin);
    Y(i,:) = y.';  Qu(i) = Q;  Psh(i) = Ps;  SP(i) = sp;  ST(i) = s;
    if i == nStep+1, break; end

    [k2, ~, ~] = rates(y + 0.5*dt*k1, sp, N, p, kin);
    [k3, ~, ~] = rates(y + 0.5*dt*k2, sp, N, p, kin);
    [k4, ~, ~] = rates(y + dt*k3,     sp, N, p, kin);
    y = y + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
    y(3:4) = min(max(y(3:4), 0), 1);        % crystal fractions stay in [0,1]
end

% ---- electrical power and cumulative energy ----------------------------
P_heat = max(Qu, 0);                        % [W] electric heater
P_cool = max(-Qu, 0) / p.COP_chiller;       % [W] electricity for chiller
P_stir = Psh / p.eta_motor;                 % [W] electricity for stirrer
Eh = cumtrapz(t, P_heat) / 3600;            % [Wh]
Ec = cumtrapz(t, P_cool) / 3600;
Es = cumtrapz(t, P_stir) / 3600;

res.design       = design;
res.warnings     = warn;
res.dt_min       = dt / 60;
res.t_min        = t / 60;
res.T_choc       = Y(:,1);
res.T_jacket     = Y(:,2);
res.xV           = Y(:,3);
res.xU           = Y(:,4);
res.x_total      = Y(:,3) + Y(:,4);
res.setpoint     = SP;
res.stage        = ST;
res.stage_edges_min = edges / 60;
res.P_heat_W     = P_heat;
res.P_cool_el_W  = P_cool;
res.P_stir_el_W  = P_stir;
res.E_heat_cum_Wh = Eh;
res.E_cool_cum_Wh = Ec;
res.E_stir_cum_Wh = Es;
res.E_cum_Wh     = Eh + Ec + Es;
res.E_heat_Wh    = Eh(end);
res.E_cool_Wh    = Ec(end);
res.E_stir_Wh    = Es(end);
res.E_total_Wh   = res.E_cum_Wh(end);
res.t_total_min  = t_end / 60;
end

% ========================================================================
function [dy, Qutil, Pshaft] = rates(y, sp, N, p, kin)
T  = y(1);  Tj = y(2);  xV = y(3);  xU = y(4);
r  = N / p.N_ref_rpm;

UA     = p.UA_min_WK + (p.UA_ref_WK - p.UA_min_WK) * r^0.67;
Pshaft = p.P_ref_W * r^3;
Qutil  = min(max(p.Kc_WK * (sp - Tj), -p.Q_cool_max_W), p.Q_heat_max_W);

free  = max(0, 1 - xV - xU);                          % unused capacity
shear = 1 + kin.shear_gain * r;                       % stirring helps nucleation
mob   = 1 / (1 + exp(-(T - kin.T_visc_C) / kin.w_visc_K));

rV = crystal_rate(xV, T, kin.TmV_C, kin.kV_per_min, kin.nuc_V, mob, shear, free, kin);
rU = crystal_rate(xU, T, kin.TmU_C, kin.kU_per_min, kin.nuc_U, mob, shear, free, kin);

Qlat = p.M_kg * p.dH_Jkg * (rV + rU);                 % [W]
dT   = (UA*(Tj - T) + Pshaft + Qlat) / (p.M_kg * p.cp_JkgK);
dTj  = (Qutil - UA*(Tj - T) - p.UA_amb_WK*(Tj - p.T_amb_C)) / p.Cj_JK;
dy   = [dT; dTj; rV; rU];
end

function r = crystal_rate(x, T, Tm, kg, n0, mob, shear, free, kin)
% net crystallisation rate of one polymorph [1/s]
s      = max(0, (Tm - T) / kin.dT_ref_K);
growth = kg * s^kin.order * mob * (x + n0*shear) * free;     % [1/min]
melt   = kin.k_melt * max(0, T - Tm) * x;                    % [1/min]
r      = (growth - melt) / 60;                               % [1/s]
end
