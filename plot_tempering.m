function plot_tempering(res, cfg, axT, axX, axE, axS, prev)
%PLOT_TEMPERING  Temperature, crystallization, energy and score-breakdown plots.
%
%   plot_tempering(res)                       % opens a new figure
%   plot_tempering(res, cfg, axT, axX, axE, axS, prev)
%
%   axT/axX/axE/axS are axes (or uiaxes) handles.  PREV is an optional earlier
%   result that is drawn as a faint dashed "ghost" for comparison.
if nargin < 2 || isempty(cfg), cfg = tempering_config(); end
if nargin < 3 || isempty(axT)
    figure('Name', 'Tempering results', 'Color', 'w', 'Position', [80 60 1000 820]);
    axT = subplot(3, 2, [1 2]);
    axX = subplot(3, 2, [3 4]);
    axE = subplot(3, 2, 5);
    axS = subplot(3, 2, 6);
end
if nargin < 7, prev = []; end

deg  = char(176);
brown = [0.36 0.20 0.09];   % chocolate temperature
slate = [0.35 0.45 0.60];   % jacket
teal  = [0.05 0.55 0.50];   % stable crystals
amber = [0.85 0.45 0.05];   % unstable crystals
red   = [0.75 0.15 0.15];   % limits
grey  = [0.60 0.60 0.60];

tlim = max(res.t_total_min, cfg.limits.t_max_min) * 1.02;
S    = cfg.score;

% ======================= 1. temperature ================================
cla(axT); hold(axT, 'on');
ylo = floor(min([res.T_choc; res.T_jacket; 20]) - 1);
yhi = 48;
hs = patch(axT, [0 tlim tlim 0], [S.seed_lo_C S.seed_lo_C S.seed_hi_C S.seed_hi_C], ...
           [0.55 0.75 0.95], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
hw = patch(axT, [0 tlim tlim 0], [S.work_lo_C S.work_lo_C S.work_hi_C S.work_hi_C], ...
           [0.60 0.85 0.60], 'FaceAlpha', 0.45, 'EdgeColor', 'none');
edges = [0 res.stage_edges_min];
for i = 2:numel(edges)
    if edges(i) > edges(i-1)
        plot(axT, [edges(i) edges(i)], [ylo yhi], '-', 'Color', [0.85 0.85 0.85]);
        text(axT, (edges(i-1)+edges(i))/2, yhi-1.2, sprintf('S%d', i-1), ...
             'HorizontalAlignment', 'center', 'Color', grey, 'FontSize', 9);
    end
end
if ~isempty(prev)
    plot(axT, prev.t_min, prev.T_choc, '--', 'Color', [0.7 0.6 0.5], 'LineWidth', 1.2);
end
hsp = plot(axT, res.t_min, res.setpoint, ':', 'Color', slate, 'LineWidth', 1.2);
hj  = plot(axT, res.t_min, res.T_jacket, '-', 'Color', slate, 'LineWidth', 1.2);
hc  = plot(axT, res.t_min, res.T_choc, '-', 'Color', brown, 'LineWidth', 2.5);
hm  = plot(axT, [0 tlim], [cfg.kin.TmV_C cfg.kin.TmV_C], '--', 'Color', red);
hu  = plot(axT, [0 tlim], [cfg.kin.TmU_C cfg.kin.TmU_C], '--', 'Color', amber);
ht  = plot(axT, [cfg.limits.t_max_min cfg.limits.t_max_min], [ylo yhi], '-', ...
           'Color', red, 'LineWidth', 1.5);
xlim(axT, [0 tlim]); ylim(axT, [ylo yhi]);
ylabel(axT, ['Temperature (' deg 'C)']);
title(axT, 'Temperature profile');
grid(axT, 'on'); box(axT, 'on');
legend(axT, [hc hj hsp hs hw hm hu ht], ...
    {'Chocolate', 'Jacket fluid', 'Jacket set-point', 'Seeding window', ...
     'Working window', 'Form V melts', 'Unstable crystals melt', 'Time limit'}, ...
    'Location', 'northeast', 'FontSize', 8, 'NumColumns', 2);
hold(axT, 'off');

% ======================= 2. crystallisation ============================
cla(axX); hold(axX, 'on');
hf = patch(axX, [0 tlim tlim 0], [S.xf_lo S.xf_lo S.xf_hi S.xf_hi], ...
           [0.60 0.85 0.60], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
for i = 2:numel(edges)
    if edges(i) > edges(i-1)
        plot(axX, [edges(i) edges(i)], [0 1], '-', 'Color', [0.85 0.85 0.85]);
    end
end
if ~isempty(prev)
    plot(axX, prev.t_min, prev.xV, '--', 'Color', [0.6 0.8 0.78], 'LineWidth', 1.2);
end
hv  = plot(axX, res.t_min, res.xV, '-', 'Color', teal,  'LineWidth', 2.5);
hu2 = plot(axX, res.t_min, res.xU, '-', 'Color', amber, 'LineWidth', 2);
htot = plot(axX, res.t_min, res.x_total, ':', 'Color', grey, 'LineWidth', 1.2);
[pk, ip] = max(res.xV);
hp = plot(axX, res.t_min(ip), pk, 'o', 'MarkerSize', 7, 'MarkerFaceColor', 'w', ...
          'MarkerEdgeColor', teal, 'LineWidth', 1.5);
xlim(axX, [0 tlim]); ylim(axX, [0 1]);
xlabel(axX, 'Time (min)');
ylabel(axX, 'Crystal fraction (-)');
title(axX, sprintf('Crystallisation  (peak xV %.2f, final xV %.2f, final xU %.3f)', ...
      pk, res.xV(end), res.xU(end)));
grid(axX, 'on'); box(axX, 'on');
legend(axX, [hv hu2 htot hp hf], ...
    {'Stable (Form V)', 'Unstable', 'Total', 'Peak Form V', 'Target final Form V'}, ...
    'Location', 'northeast', 'FontSize', 8, 'NumColumns', 2);
hold(axX, 'off');

% ======================= 3. energy =====================================
cla(axE); hold(axE, 'on');
h1 = plot(axE, res.t_min, res.E_heat_cum_Wh, '-', 'Color', red,   'LineWidth', 1.2);
h2 = plot(axE, res.t_min, res.E_cool_cum_Wh, '-', 'Color', slate, 'LineWidth', 1.2);
h3 = plot(axE, res.t_min, res.E_stir_cum_Wh, '-', 'Color', amber, 'LineWidth', 1.2);
h4 = plot(axE, res.t_min, res.E_cum_Wh, '-', 'Color', brown, 'LineWidth', 2.5);
h5 = plot(axE, [0 tlim], [cfg.limits.E_max_Wh cfg.limits.E_max_Wh], '--', 'Color', red, 'LineWidth', 1.5);
xlim(axE, [0 tlim]); ylim(axE, [0 max(cfg.limits.E_max_Wh, max(res.E_cum_Wh)) * 1.1]);
xlabel(axE, 'Time (min)'); ylabel(axE, 'Cumulative energy (Wh)');
title(axE, sprintf('Energy: %.1f Wh of %g Wh', res.E_total_Wh, cfg.limits.E_max_Wh));
grid(axE, 'on'); box(axE, 'on');
legend(axE, [h4 h1 h2 h3 h5], {'Total', 'Heater', 'Chiller (el.)', 'Stirrer (el.)', 'Limit'}, ...
       'Location', 'northwest', 'FontSize', 8);
hold(axE, 'off');

% ======================= 4. score breakdown ============================
sc = res.score;
n  = numel(sc.pts);
cla(axS); hold(axS, 'on');
barh(axS, 1:n, sc.max_pts(end:-1:1), 0.7, 'FaceColor', [0.88 0.88 0.88], 'EdgeColor', 'none');
if sc.valid, barcol = brown; else, barcol = red; end
barh(axS, 1:n, sc.pts(end:-1:1), 0.45, 'FaceColor', barcol, 'EdgeColor', 'none');
set(axS, 'YTick', 1:n, 'YTickLabel', sc.names(end:-1:1), 'FontSize', 8);
xlim(axS, [0 max(sc.max_pts) * 1.05]); ylim(axS, [0.4 n + 0.6]);
xlabel(axS, 'Points');
if sc.valid
    title(axS, sprintf('Quality score %.1f / 100', sc.quality));
else
    title(axS, sprintf('Quality score %.1f / 100  -  INVALID (limit exceeded)', sc.quality), 'Color', red);
end
box(axS, 'on');
hold(axS, 'off');
drawnow;
end
