function plot_kymograph_comparison(loadKymograph, outputDir, varargin)
%PLOT_KYMOGRAPH_COMPARISON  r*-time kymographs and strain-time curves per material.
%
%   PLOT_KYMOGRAPH_COMPARISON(loadKymograph, outputDir) draws, for each
%   material and frame rate, the kymographs of the particle-induced von
%   Mises strain (one panel per condition) and the strain-time curves at
%   r* = 1.5, 2.0, 2.5 (solid: solvent-filled, dashed: gas-loaded), as in
%   Fig. 2D(ii-iii), 2F and Figs. S10-S13. SVG files are written to
%   <outputDir>/<group>/.
%
%   loadKymograph  function handle  k = loadKymograph(caseInfo) returning a
%                  struct with fields evm (n_r x n_t), r_star (n_r), time
%                  (n_t, frame index). See scripts/make_kymograph_figures.m.
%   Name-value options
%     'groups'   cell array of group names to draw (default: all)
%     'visible'  'on' | 'off' figure visibility (default 'off')

ip = inputParser;
addParameter(ip, 'groups', {}, @iscell);
addParameter(ip, 'visible', 'off', @(x) any(strcmp(x, {'on', 'off'})));
parse(ip, varargin{:});

style = default_style();
kp = default_params().kymo;
groups = kymograph_groups();
if ~isempty(ip.Results.groups)
    groups = groups(ismember({groups.name}, ip.Results.groups));
end

for g = 1:numel(groups)
    group = groups(g);
    groupDir = fullfile(outputDir, group.name);
    if ~isfolder(groupDir)
        mkdir(groupDir);
    end
    nCond = numel(group.caseIds);
    cases = repmat(get_case(group.caseIds{1}), nCond, 1);
    data = repmat(struct('evm', [], 'r_star', [], 'time', []), nCond, 1);
    for c = 1:nCond
        cases(c) = get_case(group.caseIds{c});
        k = loadKymograph(cases(c));
        data(c) = struct('evm', k.evm, 'r_star', k.r_star(:), 'time', k.time(:)');
    end
    widthScale = 1 + (group.fpsMHz == 1);  % 1 Mfps series are 10x longer
    cLimits = cases(1).kymographClim;

    draw_heatmaps(group, cases, data, cLimits, kp.rLines, widthScale, style, ...
        ip.Results.visible, groupDir);
    draw_strain_time(group, data, kp.rLines, widthScale, style, ...
        ip.Results.visible, groupDir);
end
end

% -------------------------------------------------------------------------
function groups = kymograph_groups()
% Condition order: solvent-filled first, then gas-loaded (as in the paper).
groups = struct( ...
    'name', {'ZIF-8 (10M)', 'ZIF-8 (1M)', 'NU-1003 (10M)', 'NU-1003 (1M)', ...
             'ZIF-67 (10M)', 'ZIF-67 (1M)', 'Microbubble (10M)', 'Microbubble (1M)'}, ...
    'fpsMHz', {10, 1, 10, 1, 10, 1, 10, 1}, ...
    'caseIds', {{'171925', '181404'}, {'172655', '180814'}, {'162005', '155040'}, ...
                {'162445', '160901'}, {'163902', '113847'}, {'164311', '115047'}, ...
                {'111031'}, {'112138'}}, ...
    'labels', {{'w/o gas', 'w gas'}, {'w/o gas', 'w gas'}, {'w/o gas', 'w gas'}, ...
               {'w/o gas', 'w gas'}, {'w/o gas', 'w gas'}, {'w/o gas', 'w gas'}, ...
               {'FPS-10M'}, {'FPS-1M'}});
end

function s = default_style()
s.axisFontSize = 26;
s.labelFontSize = 26;
s.titleFontSize = 30;
s.legendFontSize = 26;
s.colorbarFontSize = 26;
s.rLineWidth = 2.4;
s.curveLineWidth = 2.7;
s.heatmapPosition = [100 400 1000 400];
s.strainPosition = [800 150 800 500];
s.legendPosition = [1050 150 1200 400];
s.colorbarTickStep = 0.05;
s.timeLabel = ['Time (' char(181) 's)'];
end

% -------------------------------------------------------------------------
function draw_heatmaps(group, cases, data, cLimits, rLines, widthScale, style, visible, outDir)
nCond = numel(cases);
pos = style.heatmapPosition;
pos(3) = pos(3) * widthScale;
pos(4) = pos(4) * nCond;
fig = figure('Name', [group.name ' - Heatmaps'], 'Position', pos, 'Visible', visible);
for c = 1:nCond
    ax = subplot(nCond, 1, c, 'Parent', fig);
    imagesc(ax, data(c).time ./ group.fpsMHz, data(c).r_star, data(c).evm);
    set(ax, 'YDir', 'normal', 'FontSize', style.axisFontSize, 'TickDir', 'out', 'LineWidth', 1.0);
    box(ax, 'on');
    colormap(ax, 'turbo');
    caxis(ax, cLimits);
    cb = colorbar(ax);
    cb.FontSize = style.colorbarFontSize;
    tickMin = ceil(cLimits(1) / style.colorbarTickStep - 1e-9) * style.colorbarTickStep;
    tickMax = floor(cLimits(2) / style.colorbarTickStep + 1e-9) * style.colorbarTickStep;
    if tickMax >= tickMin
        cb.Ticks = tickMin:style.colorbarTickStep:tickMax;
    end
    xlabel(ax, style.timeLabel, 'FontSize', style.labelFontSize);
    ylabel(ax, 'r*', 'FontSize', style.labelFontSize);
    title(ax, sprintf('%s - %s', group.name, group.labels{c}), 'FontSize', style.titleFontSize);
    ylim(ax, [1, 3]);
    yticks(ax, 1:0.5:3);
    hold(ax, 'on');
    for k = 1:numel(rLines)
        yline(ax, rLines(k), '--', 'Color', 'k', 'LineWidth', style.rLineWidth);
    end
    hold(ax, 'off');
end
saveas(fig, fullfile(outDir, sprintf('%s_heatmaps.svg', group.name)), 'svg');
close(fig);
end

function draw_strain_time(group, data, rLines, widthScale, style, visible, outDir)
nCond = numel(data);
colors = lines(max(numel(rLines), 3));
pos = style.strainPosition;
pos(3) = pos(3) * widthScale;
fig = figure('Name', [group.name ' - Strain-time'], 'Position', pos, 'Visible', visible);
ax = axes(fig);
hold(ax, 'on');
handles = gobjects(0);
entries = {};
allT = [];
allE = [];
for k = 1:numel(rLines)
    ir = nearest_index(data(1).r_star, rLines(k));
    for c = 1:nCond
        lineStyle = '-';
        if c > 1
            lineStyle = '--';
        end
        t = data(c).time(:) ./ group.fpsMHz;
        e = data(c).evm(ir, :)';
        n = min(numel(t), numel(e));
        handles(end + 1) = plot(ax, t(1:n), e(1:n), lineStyle, ...
            'LineWidth', style.curveLineWidth, 'Color', colors(k, :)); %#ok<AGROW>
        entries{end + 1} = sprintf('%s | r* = %.1f | %s', group.name, rLines(k), group.labels{c}); %#ok<AGROW>
        allT = [allT; t(1:n)]; %#ok<AGROW>
        allE = [allE; e(1:n)]; %#ok<AGROW>
    end
end
set(ax, 'FontSize', style.axisFontSize, 'Box', 'off', 'TickDir', 'out', 'LineWidth', 2.0);
xlabel(ax, style.timeLabel, 'FontSize', style.labelFontSize);
ylabel(ax, 'von Mises strain', 'FontSize', style.labelFontSize);
title(ax, sprintf('Strain-time comparison (%s)', group.name), 'FontSize', style.titleFontSize);
if max(allT) > min(allT)
    xlim(ax, [min(allT), 1.05 * max(allT)]);
end
if max(allE) > min(allE)
    ylim(ax, [min(allE), 1.05 * max(allE)]);
end
hold(ax, 'off');
saveas(fig, fullfile(outDir, sprintf('%s_strain_time.svg', group.name)), 'svg');

% Legend as a separate figure (placeholder lines copy the curve styles)
legFig = figure('Name', [group.name ' - Legend'], 'Position', style.legendPosition, ...
    'Visible', visible);
axLeg = axes(legFig);
hold(axLeg, 'on');
legLines = gobjects(numel(handles), 1);
for i = 1:numel(handles)
    legLines(i) = plot(axLeg, NaN, NaN, 'LineStyle', handles(i).LineStyle, ...
        'Color', handles(i).Color, 'LineWidth', handles(i).LineWidth);
end
leg = legend(axLeg, legLines, entries, 'Location', 'northwest', 'FontSize', style.legendFontSize);
leg.Interpreter = 'none';
axis(axLeg, 'off');
saveas(legFig, fullfile(outDir, sprintf('%s_legend.svg', group.name)), 'svg');
close(fig);
close(legFig);
end

function idx = nearest_index(vector, value)
[~, idx] = min(abs(vector - value));
end
