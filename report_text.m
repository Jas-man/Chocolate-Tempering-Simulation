function lines = report_text(res, cfg)
%REPORT_TEXT  Human-readable results summary (cell array of strings).
%   Used by the interface, run_team_inputs and the saved submission report.
if nargin < 2, cfg = tempering_config(); end
sc = res.score;
L  = cfg.limits;
lines = {};
lines{end+1} = sprintf('TEAM: %s', res.design.team_name);
if sc.valid
    lines{end+1} = 'STATUS: VALID - within all limits';
else
    lines{end+1} = 'STATUS: *** INVALID - ranked below all valid designs ***';
    for i = 1:numel(sc.reasons)
        lines{end+1} = ['   - ' sc.reasons{i}]; %#ok<AGROW>
    end
end
lines{end+1} = '';
lines{end+1} = sprintf('QUALITY SCORE: %.1f / 100   (simulated game metric)', sc.quality);
lines{end+1} = sprintf('  Profile compliance      %5.1f / %g', sc.compliance,  sc.max_compliance);
lines{end+1} = sprintf('  Crystallisation chance  %5.1f / %g', sc.opportunity, sc.max_opportunity);
lines{end+1} = sprintf('  Crystal retention       %5.1f / %g', sc.retention,   sc.max_retention);
lines{end+1} = '';
lines{end+1} = 'Breakdown (points earned / available):';
for i = 1:numel(sc.names)
    lines{end+1} = sprintf('  %-28s %5.1f / %g', sc.names{i}, sc.pts(i), sc.max_pts(i)); %#ok<AGROW>
end
lines{end+1} = '';
lines{end+1} = 'Resources:';
lines{end+1} = sprintf('  Processing time  %5.1f min   (limit %g)', res.t_total_min, L.t_max_min);
lines{end+1} = sprintf('  Energy used      %5.1f Wh    (limit %g)', res.E_total_Wh,  L.E_max_Wh);
lines{end+1} = sprintf('     heater %.1f | chiller (electric) %.1f | stirrer (electric) %.1f Wh', ...
                       res.E_heat_Wh, res.E_cool_Wh, res.E_stir_Wh);
lines{end+1} = sprintf('  Efficiency index %5.3f  (0-1, used for tie-breaks only)', sc.efficiency);
lines{end+1} = '';
d = sc.diag;
lines{end+1} = 'Diagnostics:';
lines{end+1} = sprintf('  Coldest chocolate temperature  %.1f degC', d.T_min_C);
lines{end+1} = sprintf('  Time inside seeding window     %.1f min (full marks at %g)', d.t_in_seed_min, cfg.score.seed_req_min);
lines{end+1} = sprintf('  Final working temperature      %.1f degC (window %g-%g)', d.T_end_C, cfg.score.work_lo_C, cfg.score.work_hi_C);
lines{end+1} = sprintf('  Excursions outside corridor    %.1f K*min', d.excursion_Kmin);
lines{end+1} = sprintf('  Peak stable crystals (xV)      %.2f at t = %.1f min (target %.2f)', d.xV_peak, d.t_xV_peak_min, cfg.score.xV_peak_target);
lines{end+1} = sprintf('  Stable share at peak           %.0f %%', 100*d.selectivity);
lines{end+1} = sprintf('  Final stable crystals (xV)     %.2f (target %.2f-%.2f)', d.xV_end, cfg.score.xf_lo, cfg.score.xf_hi);
lines{end+1} = sprintf('  Retained through reheat        %.0f %% of the peak', 100*d.retention_ratio);
lines{end+1} = sprintf('  Final unstable crystals (xU)   %.3f', d.xU_end);
if ~isempty(res.warnings)
    lines{end+1} = '';
    lines{end+1} = 'Input warnings:';
    for i = 1:numel(res.warnings)
        lines{end+1} = ['  ! ' res.warnings{i}]; %#ok<AGROW>
    end
end
lines{end+1} = '';
lines{end+1} = 'Teaching model only - not a prediction of real chocolate quality.';
end
