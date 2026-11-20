function fig = plot_secondary_vonmises(imageFile, imageMask, coords, UWorld, elementsFEM, ...
    evmSecondary, DICpara, cLimits, visible)
%PLOT_SECONDARY_VONMISES  Particle-induced von Mises strain over the DIC image.
%
%   fig = PLOT_SECONDARY_VONMISES(imageFile, imageMask, coords, UWorld, ...
%       elementsFEM, evmSecondary, DICpara, cLimits, visible)
%
%   Reproduces the full-field maps of Fig. 2C(iii) / Movie S2: the
%   quadtree mesh is drawn in the deformed configuration over the current
%   frame, nodes outside the image mask are hidden, and the color range is
%   cLimits (config/case_table.m, field vonMisesClim).
%
%   coords       N x 2 reference node coordinates (world axes)
%   UWorld       interleaved displacement in world axes
%   imageMask    logical mask of the current frame (STAQ-DIC orientation)
%   visible      'on' | 'off' (default 'off')

if nargin < 9
    visible = 'off';
end

um2px = DICpara.um2px;
img = imread(imageFile);
if size(img, 3) == 4
    img = img(:, :, 1:3);
end

coordsDef = coords + DICpara.Image2PlotResults * [UWorld(1:2:end), UWorld(2:2:end)];
coordsDef = hide_masked_nodes(coordsDef, imageMask, um2px, DICpara.Image2PlotResults);

fig = figure('Visible', visible);
ax1 = axes(fig);
imshow(flipud(img), 'InitialMagnification', 'fit', 'Parent', ax1);
axis(ax1, 'on'); axis(ax1, 'equal'); axis(ax1, 'tight'); box(ax1, 'on');
set(ax1, 'FontSize', 18, 'YDir', 'normal'); view(ax1, 2);

hold(ax1, 'on');
ax2 = axes(fig);
h2 = show([], elementsFEM(:, 1:4), coordsDef / um2px, evmSecondary, 'NoEdgeColor');
set(ax2, 'FontSize', 18); view(ax2, 2); box(ax2, 'on'); axis(ax2, 'equal'); axis(ax2, 'tight');
alpha(h2, DICpara.OrigDICImgTransparency);
colormap(ax2, turbo);
caxis(ax2, cLimits);

linkaxes([ax1, ax2]);
ax2.Visible = 'off'; ax2.XTick = []; ax2.YTick = [];
colormap(ax1, 'gray');
set([ax1, ax2], 'Position', [.17 .11 .685 .815]);
ax1.Visible = 'on';
xticklabels(ax1, num2cell(round(um2px * ax1.XTick * 10) / 10, length(ax1.XTick))');
yticklabels(ax1, num2cell(round(um2px * ax1.YTick * 10) / 10, length(ax1.YTick))');
colorbar(ax2, 'Position', [.17 + 0.685 + 0.012, .11 + .128, .03, .557]);
end

function coordsDef = hide_masked_nodes(coordsDef, imageMask, um2px, image2PlotResults)
% Nodes that fall outside the image or on a zero mask pixel are not drawn
% (same rule as STAQ-DIC PlotstrainQuadtreeMasks).
if image2PlotResults ~= 1 || isempty(imageMask)
    return
end
ix = floor(coordsDef(:, 1) / um2px);
iy = size(imageMask, 2) + 1 - ceil(coordsDef(:, 2) / um2px);
inside = isfinite(ix) & isfinite(iy) & ix >= 1 & ix <= size(imageMask, 1) & ...
    iy >= 1 & iy <= size(imageMask, 2);
keep = false(size(ix));
keep(inside) = imageMask(sub2ind(size(imageMask), ix(inside), iy(inside))) ~= 0;
coordsDef(~keep, :) = NaN;
end
