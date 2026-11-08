function sc = score_tempering(res, cfg)
%SCORE_TEMPERING  Simulated quality score (0-100) and constraint check.
%
%   sc = score_tempering(res, cfg)
%
%   The score is a game metric built from the simulated curves.  It is NOT a
%   prediction of real chocolate quality.
%
%   A. Temperature-profile compliance (30)
%        seed_time    time the chocolate spends inside the seeding window
%        work_temp    mean chocolate temperature over the final minutes vs
%                     the working window
%        corridor     no excursions (K*min) outside a corridor once the
%                     chocolate first cools below its upper limit
%   B. Crystallisation opportunity (35)
%        V_amount     peak stable-crystal fraction vs target
%        V_select     share of stable crystals at that peak (xV/(xV+xU))
%   C. Crystal retention (35)
%        retention    final xV / peak xV (did the seeds survive reheating?)
%        final_window final xV inside target window (not under/over-tempered)
%        purge        unstable crystals melted out by the end
if nargin < 2, cfg = tempering_config(); end
S  = cfg.score;
W  = S.w;
dt = res.dt_min;
t  = res.t_min;
T  = res.T_choc;
xV = res.xV;
xU = res.xU;

% ---- A. compliance ------------------------------------------------------
t_in   = dt * sum(T >= S.seed_lo_C & T <= S.seed_hi_C);
f_seed = min(1, t_in / S.seed_req_min);

idx    = (t >= t(end) - S.work_avg_min);
T_end  = mean(T(idx));
dist   = max([0, S.work_lo_C - T_end, T_end - S.work_hi_C]);
f_work = max(0, 1 - dist / S.work_tol_K);

k = find(T < S.corr_hi_C, 1, 'first');
if isempty(k)
    excursion = S.corr_ref_Kmin;             % never cooled: full penalty
else
    out = max(0, max(S.corr_lo_C - T(k:end), T(k:end) - S.corr_hi_C));
    excursion = dt * sum(out);
end
f_corr = max(0, 1 - excursion / S.corr_ref_Kmin);

% ---- B. crystallisation opportunity ------------------------------------
[xV_peak, ip] = max(xV);
f_amount = min(1, xV_peak / S.xV_peak_target);
if xV_peak > 1e-3
    selectivity = xV(ip) / (xV(ip) + xU(ip));
else
    selectivity = 0;
end

% ---- C. retention -------------------------------------------------------
xV_end = xV(end);
xU_end = xU(end);
if xV_peak > 1e-3
    R = min(1, xV_end / xV_peak);
else
    R = 0;
end
f_ret = min(1, R / S.R_full);

if xV_end < S.xf_lo
    f_win = max(0, (xV_end - S.xf_zero_lo) / (S.xf_lo - S.xf_zero_lo));
elseif xV_end > S.xf_hi
    f_win = max(0, (S.xf_zero_hi - xV_end) / (S.xf_zero_hi - S.xf_hi));
else
    f_win = 1;
end
% (purge marks only count if stable crystals were actually made - otherwise
%  "doing nothing" would earn free points)
f_purge = (1 - min(1, xU_end / S.xU_tol)) * f_amount;

% ---- assemble -----------------------------------------------------------
sc.names = {'Time in seeding window', 'Final working temperature', ...
            'No temperature excursions', 'Stable-crystal amount', ...
            'Stable-crystal selectivity', 'Crystal retention', ...
            'Final crystal level', 'Unstable crystals purged'};
sc.fractions = [f_seed f_work f_corr f_amount selectivity f_ret f_win f_purge];
sc.max_pts   = [W.seed_time W.work_temp W.corridor W.V_amount W.V_select ...
                W.retention W.final_window W.purge];
sc.pts       = sc.fractions .* sc.max_pts;

sc.compliance  = sum(sc.pts(1:3));
sc.opportunity = sum(sc.pts(4:5));
sc.retention   = sum(sc.pts(6:8));
sc.max_compliance  = sum(sc.max_pts(1:3));
sc.max_opportunity = sum(sc.max_pts(4:5));
sc.max_retention   = sum(sc.max_pts(6:8));
sc.quality     = sum(sc.pts);

% key diagnostics (shown to teams)
sc.diag.t_in_seed_min = t_in;
sc.diag.T_end_C       = T_end;
sc.diag.excursion_Kmin = excursion;
sc.diag.T_min_C       = min(T);
sc.diag.xV_peak       = xV_peak;
sc.diag.t_xV_peak_min = t(ip);
sc.diag.selectivity   = selectivity;
sc.diag.xV_end        = xV_end;
sc.diag.xU_end        = xU_end;
sc.diag.retention_ratio = R;

% ---- hard constraints ---------------------------------------------------
L = cfg.limits;
sc.reasons = {};
if res.t_total_min > L.t_max_min + 1e-9
    sc.reasons{end+1} = sprintf('Processing time %.1f min exceeds the %g min limit.', ...
                                res.t_total_min, L.t_max_min);
end
if res.E_total_Wh > L.E_max_Wh
    sc.reasons{end+1} = sprintf('Energy use %.1f Wh exceeds the %g Wh limit.', ...
                                res.E_total_Wh, L.E_max_Wh);
end
sc.valid = isempty(sc.reasons);

% ---- secondary ranking metrics -----------------------------------------
sc.speed_index  = max(0, 1 - res.t_total_min / L.t_max_min);
sc.energy_index = max(0, 1 - res.E_total_Wh  / L.E_max_Wh);
sc.efficiency   = cfg.rank.w_time * sc.speed_index + cfg.rank.w_energy * sc.energy_index;
end
