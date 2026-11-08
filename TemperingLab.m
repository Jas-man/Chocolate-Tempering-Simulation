function TemperingLab()
%TEMPERINGLAB  Point-and-click interface for "Engineer the Perfect Chocolate".
%
%   Type   TemperingLab   at the MATLAB prompt (needs MATLAB R2019a or newer).
%
%   1. Type your team name.
%   2. Edit the numbers in the table: jacket set-point, duration and stirrer
%      speed for each of the five stages.
%   3. Press "Run simulation" and study the graphs and the score breakdown.
%   4. When you are happy, press "Save submission" and hand in the file.
%
%   No MATLAB programming is needed.

addpath(fileparts(mfilename('fullpath')));
cfg       = tempering_config();
design    = default_design();
lastRes   = [];
prevRes   = [];
dirty     = true;
runCount  = 0;

% ======================= window and layout ==============================
fig = uifigure('Name', 'Chocolate Tempering Lab', 'Position', [30 30 1340 820]);
root = uigridlayout(fig, [1 2]);
root.ColumnWidth = {400, '1x'};
root.Padding = [10 10 10 10];

% ---------------- left: inputs ------------------
L = uigridlayout(root, [10 1]);
L.Layout.Row = 1;  L.Layout.Column = 1;
L.RowHeight = {30, 20, 28, 20, 200, 22, 38, 34, 34, '1x'};
L.Padding = [0 0 0 0];

lblTitle = uilabel(L, 'Text', 'Engineer the Perfect Chocolate', ...
    'FontSize', 20, 'FontWeight', 'bold');
lblTitle.Layout.Row = 1;

lblName = uilabel(L, 'Text', 'Team name');
lblName.Layout.Row = 2;
nameField = uieditfield(L, 'text', 'Value', design.team_name, ...
    'ValueChangedFcn', @onEdit);
nameField.Layout.Row = 3;

lblTable = uilabel(L, 'Text', 'Jacket programme  (edit the numbers; duration 0 skips a stage)');
lblTable.Layout.Row = 4;

tbl = uitable(L);
tbl.Layout.Row = 5;
tbl.ColumnName = {'Jacket set-point (degC)', 'Duration (min)', 'Stirrer (rpm)'};
tbl.RowName = {'1 Cool', '2 Seed', '3 Reheat', '4 Work', '5 Extra'};
tbl.ColumnEditable = [true true true];
tbl.ColumnWidth = {105, 75, 75};
tbl.Data = design2table(design);
tbl.CellEditCallback = @onEdit;
tbl.FontSize = 13;

lblTotals = uilabel(L, 'Text', '', 'FontSize', 12, 'FontWeight', 'bold');
lblTotals.Layout.Row = 6;

btnRun = uibutton(L, 'push', 'Text', 'Run simulation', 'FontSize', 15, ...
    'FontWeight', 'bold', 'ButtonPushedFcn', @onRun);
btnRun.Layout.Row = 7;
btnRun.BackgroundColor = [0.36 0.20 0.09];
btnRun.FontColor = [1 1 1];

rowB = uigridlayout(L, [1 2]);
rowB.Layout.Row = 8;
rowB.Padding = [0 0 0 0];
btnReset = uibutton(rowB, 'push', 'Text', 'Reset to starter design', ...
    'ButtonPushedFcn', @onReset);
btnReset.Layout.Column = 1;
btnPng = uibutton(rowB, 'push', 'Text', 'Export graphs (PNG)', ...
    'ButtonPushedFcn', @onExportPng);
btnPng.Layout.Column = 2;

btnSave = uibutton(L, 'push', 'Text', 'Save submission', 'FontSize', 14, ...
    'ButtonPushedFcn', @onSave);
btnSave.Layout.Row = 9;

resultBox = uitextarea(L, 'Editable', 'off', 'FontName', 'Courier New', 'FontSize', 11);
resultBox.Layout.Row = 10;

% ---------------- right: graphs ------------------
R = uigridlayout(root, [3 1]);
R.Layout.Row = 1;  R.Layout.Column = 2;
R.RowHeight = {'1.1x', '1x', '1x'};
R.Padding = [0 0 0 0];

axT = uiaxes(R);  axT.Layout.Row = 1;
axX = uiaxes(R);  axX.Layout.Row = 2;
B = uigridlayout(R, [1 2]);
B.Layout.Row = 3;
B.Padding = [0 0 0 0];
B.ColumnWidth = {'1x', '1.3x'};
axE = uiaxes(B);  axE.Layout.Column = 1;
axS = uiaxes(B);  axS.Layout.Column = 2;

refreshTotals();
onRun();                                   % show the starter design straight away

% ======================= callbacks (nested) =============================
    function onEdit(~, ~)
        syncDesign();
        dirty = true;
        refreshTotals();
    end

    function onRun(~, ~)
        try
            syncDesign();
            if ~isempty(lastRes), prevRes = lastRes; end
            lastRes = run_design(design, cfg);
            runCount = runCount + 1;
            dirty = false;
            plot_tempering(lastRes, cfg, axT, axX, axE, axS, prevRes);
            txt = report_text(lastRes, cfg);
            resultBox.Value = txt(:);
            refreshTotals();
        catch err
            uialert(fig, err.message, 'Could not run the simulation');
        end
    end

    function onReset(~, ~)
        keep = nameField.Value;
        design = default_design();
        design.team_name = keep;
        tbl.Data = design2table(design);
        prevRes = [];  lastRes = [];
        dirty = true;
        onRun();
    end

    function onSave(~, ~)
        syncDesign();
        if isempty(strtrim(nameField.Value)) || strcmp(strtrim(nameField.Value), 'Team Name')
            uialert(fig, 'Please type your team name first.', 'Team name needed', 'Icon', 'warning');
            return
        end
        if dirty || isempty(lastRes), onRun(); end
        try
            f = save_submission(lastRes, cfg);
            if lastRes.score.valid
                msg = sprintf('Saved:\n%s\n\nQuality %.1f, %.1f min, %.1f Wh.', ...
                    f, lastRes.score.quality, lastRes.t_total_min, lastRes.E_total_Wh);
                uialert(fig, msg, 'Submission saved', 'Icon', 'success');
            else
                msg = sprintf(['Saved:\n%s\n\nWARNING: this design breaks a limit and will rank below ' ...
                    'all valid designs.'], f);
                uialert(fig, msg, 'Submission saved (invalid design)', 'Icon', 'warning');
            end
        catch err
            uialert(fig, err.message, 'Could not save');
        end
    end

    function onExportPng(~, ~)
        if isempty(lastRes), onRun(); end
        [file, path] = uiputfile('tempering_graphs.png', 'Export graphs');
        if isequal(file, 0), return; end
        try
            f2 = figure('Visible', 'off', 'Color', 'w', 'Position', [80 60 1100 860]);
            a1 = subplot(3, 2, [1 2]);  a2 = subplot(3, 2, [3 4]);
            a3 = subplot(3, 2, 5);      a4 = subplot(3, 2, 6);
            plot_tempering(lastRes, cfg, a1, a2, a3, a4, []);
            saveas(f2, fullfile(path, file));
            close(f2);
        catch err
            uialert(fig, err.message, 'Could not export');
        end
    end

% ======================= helpers (nested) ===============================
    function syncDesign()
        D = tbl.Data;
        design.team_name    = nameField.Value;
        design.setpoint_C   = double(D(:, 1))';
        design.duration_min = double(D(:, 2))';
        design.stir_rpm     = double(D(:, 3))';
        % clip to the allowed ranges and write back, so the table never lies
        [design, ~] = validate_design(design, cfg);
        tbl.Data = design2table(design);
    end

    function refreshTotals()
        tot = sum(design.duration_min);
        if tot > cfg.limits.t_max_min
            lblTotals.FontColor = [0.75 0.1 0.1];
            lblTotals.Text = sprintf('Total time %.1f min  >  limit %g min  (INVALID)', ...
                tot, cfg.limits.t_max_min);
        else
            lblTotals.FontColor = [0.1 0.4 0.1];
            lblTotals.Text = sprintf('Total time %.1f / %g min.   Energy limit %g Wh.', ...
                tot, cfg.limits.t_max_min, cfg.limits.E_max_Wh);
        end
        if dirty && runCount > 0
            lblTotals.Text = [lblTotals.Text '   (edited - press Run)'];
        end
    end
end

function M = design2table(d)
M = [d.setpoint_C(:), d.duration_min(:), d.stir_rpm(:)];
end
