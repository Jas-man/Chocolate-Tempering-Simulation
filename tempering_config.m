function cfg = tempering_config()
%TEMPERING_CONFIG  Organiser settings for the "Engineer the Perfect Chocolate" challenge.
%
%   cfg = tempering_config()
%
%   Every constant used by the simulation, the scoring and the ranking lives
%   here, so the organisers can retune the competition in one place.
%   PARTICIPANTS SHOULD NOT NEED TO EDIT THIS FILE (and rank_teams.m always
%   re-simulates submissions with the organisers' copy of this file).
%
%   IMPORTANT: this is a teaching model.  The numbers below are plausible,
%   round, order-of-magnitude values chosen so that the exercise is
%   instructive - they are NOT measured chocolate properties and the model
%   does not predict real chocolate quality.  See README.md, "Assumptions".

% ------------------------------------------------------------------------
% COMPETITION LIMITS (hard constraints)
% ------------------------------------------------------------------------
cfg.limits.t_max_min   = 35;     % maximum total processing time          [min]
cfg.limits.E_max_Wh    = 40;     % maximum electrical energy use          [Wh]
cfg.limits.sp_min_C    = 10;     % allowed jacket set-point range         [degC]
cfg.limits.sp_max_C    = 50;
cfg.limits.dur_min_min = 0;      % allowed duration of one stage          [min]
cfg.limits.dur_max_min = 60;     %   (0 = skip the stage)
cfg.limits.rpm_min     = 0;      % allowed stirrer speed                  [rpm]
cfg.limits.rpm_max     = 150;

% ------------------------------------------------------------------------
% RANKING RULES (used by rank_teams.m)
% ------------------------------------------------------------------------
% Primary criterion  : quality score.  Scores are grouped into "bands" of
%                      width band_width points; teams in a higher band
%                      always rank higher.
% Secondary criteria : inside a band, teams are ordered by an efficiency
%                      index  w_time*(1 - t/t_max) + w_energy*(1 - E/E_max)
%                      (0..1, higher is better).  Raw quality breaks any
%                      remaining tie.
% Designs that violate a hard constraint rank below every valid design.
cfg.rank.band_width = 2.0;       % points
cfg.rank.w_time     = 0.5;
cfg.rank.w_energy   = 0.5;
cfg.rank.best_per_team = true;   % only a team's best submission is listed

% ------------------------------------------------------------------------
% EQUIPMENT / PROCESS  (lumped jacketed mixing vessel)
% ------------------------------------------------------------------------
cfg.proc.n_stages   = 5;         % number of programmable stages
cfg.proc.M_kg       = 2.0;       % chocolate batch mass                   [kg]
cfg.proc.cp_JkgK    = 1700;      % effective specific heat                [J/kg/K]
cfg.proc.Cj_JK      = 4000;      % thermal mass of jacket fluid + steel   [J/K]
cfg.proc.UA_ref_WK  = 20;        % jacket UA at N_ref rpm                 [W/K]
cfg.proc.UA_min_WK  = 6;         % jacket UA with no stirring (natural conv.)
cfg.proc.N_ref_rpm  = 100;       % reference stirrer speed                [rpm]
cfg.proc.UA_amb_WK  = 2;         % jacket loss to room                    [W/K]
cfg.proc.T_amb_C    = 20;        % room temperature                       [degC]
cfg.proc.T0_C       = 45;        % chocolate AND jacket start (fully melted) [degC]
cfg.proc.Kc_WK      = 150;       % jacket temperature controller gain     [W/K]
cfg.proc.Q_heat_max_W = 500;     % max heater duty into jacket fluid      [W]
cfg.proc.Q_cool_max_W = 300;     % max chiller duty out of jacket fluid   [W]
cfg.proc.COP_chiller  = 3;       % chiller coefficient of performance     [-]
cfg.proc.P_ref_W    = 15;        % stirrer shaft power at N_ref rpm       [W]
cfg.proc.eta_motor  = 0.6;       % electrical -> shaft efficiency         [-]
cfg.proc.dH_Jkg     = 6000;      % latent heat if crystallinity went 0->1 [J/kg choc]

% ------------------------------------------------------------------------
% SIMPLIFIED CRYSTALLISATION KINETICS
% Two crystal populations, each a fraction (0..1) of a fixed "capacity":
%   xV = stable Form V crystals (what we want)
%   xU = unstable lower-melting crystals (what we want to avoid / melt out)
% ------------------------------------------------------------------------
cfg.kin.TmV_C       = 33.5;      % melting point, stable Form V           [degC]
cfg.kin.TmU_C       = 30.0;      % melting point, unstable crystals       [degC]
cfg.kin.kV_per_min  = 1.0;       % growth rate constant, Form V           [1/min]
cfg.kin.kU_per_min  = 3.0;       % growth rate constant, unstable (faster!)
cfg.kin.nuc_V       = 0.012;     % nucleation "seed" term, Form V         [-]
cfg.kin.nuc_U       = 0.012;     % nucleation "seed" term, unstable       [-]
cfg.kin.dT_ref_K    = 10;        % undercooling scale                     [K]
cfg.kin.order       = 1.5;       % undercooling exponent                  [-]
cfg.kin.T_visc_C    = 17;        % mobility mid-point (viscous below this) [degC]
cfg.kin.w_visc_K    = 2;         % mobility transition width              [K]
cfg.kin.shear_gain  = 1.0;       % nucleation boost = 1 + gain*N/N_ref    [-]
cfg.kin.k_melt      = 0.2;       % melting rate per K above Tm            [1/min/K]

% ------------------------------------------------------------------------
% SCORING  (maximum points add to 100)
% ------------------------------------------------------------------------
% A. Temperature-profile compliance (30 points)
cfg.score.w.seed_time    = 10;   % time in the seeding window
cfg.score.w.work_temp    = 12;   % final working temperature
cfg.score.w.corridor     =  8;   % no excursions outside the corridor
% B. Crystallisation opportunity (35 points)
cfg.score.w.V_amount     = 25;   % peak stable-crystal fraction reached
cfg.score.w.V_select     = 10;   % stable share of crystals at that peak
% C. Crystal retention during/after reheating (35 points)
cfg.score.w.retention    = 15;   % fraction of the Form V peak that survives
cfg.score.w.final_window = 10;   % final Form V level inside target window
cfg.score.w.purge        = 10;   % unstable crystals removed by the end

cfg.score.seed_lo_C   = 26.0;    % seeding window                         [degC]
cfg.score.seed_hi_C   = 28.0;
cfg.score.seed_req_min= 6.0;     % residence time for full marks          [min]
cfg.score.work_lo_C   = 31.0;    % working-temperature window             [degC]
cfg.score.work_hi_C   = 32.0;
cfg.score.work_tol_K  = 2.0;     % distance outside window giving 0 marks [K]
cfg.score.work_avg_min= 3.0;     % average T over the last ... minutes    [min]
cfg.score.corr_lo_C   = 25.0;    % allowed corridor once cooling begins   [degC]
cfg.score.corr_hi_C   = 34.0;
cfg.score.corr_ref_Kmin = 12.0;  % K*min outside corridor giving 0 marks
cfg.score.xV_peak_target = 0.45; % peak Form V for full marks
cfg.score.R_full      = 0.90;    % retention ratio for full marks
cfg.score.xf_lo       = 0.30;    % target window for final Form V
cfg.score.xf_hi       = 0.50;
cfg.score.xf_zero_lo  = 0.05;    % final Form V at which marks fall to zero
cfg.score.xf_zero_hi  = 0.80;
cfg.score.xU_tol      = 0.03;    % final unstable fraction giving 0 marks

% ------------------------------------------------------------------------
% NUMERICS
% ------------------------------------------------------------------------
cfg.sim.dt_s = 1;                % fixed RK4 time step                    [s]
end
