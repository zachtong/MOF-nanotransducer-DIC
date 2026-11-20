function [X0_opt, Y0_opt, R0_opt, R_opt, residual_opt, history] = optimize_bubble_4params( ...
    UWorld, coords, X0_initial, Y0_initial, R0_initial, R_initial, varargin)
%OPTIMIZE_BUBBLE_4PARAMS  Refine the primary-bubble center and reference radius.
%
%   [X0, Y0, R0, R, residual, history] = OPTIMIZE_BUBBLE_4PARAMS( ...
%       UWorld, coords, X0_initial, Y0_initial, R0_initial, R_initial, ...)
%
%   Hierarchical grid search that fits the incompressible bubble model
%   (fun_bubble_strain) to the DIC displacement field UWorld. R (current
%   radius from the image-based circle fit) is kept fixed; per iteration
%     1) (X0, Y0) is searched on a center_resolution^2 grid, R0 fixed;
%     2) R0 is searched on a radius_resolution grid, center fixed;
%   until the residual changes by less than 'tolerance'. All search
%   windows stay inside the initial bounds (initial value +/- range).
%
%   Name-value options (defaults are the original function defaults; the
%   values used in the analysis are set in config/default_params.m)
%     'center_search_range'  20      px
%     'center_resolution'    21
%     'radius_search_range'  5       px
%     'radius_resolution'    21
%     'max_iterations'       10
%     'tolerance'            1e-6
%     'local_radius'         []      [] = global misfit, else local region
%     'verbose'              false
%
%   R_opt is returned unchanged (= R_initial).

p = inputParser;
addParameter(p, 'center_search_range', 20, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'center_resolution', 21, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'radius_search_range', 5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'radius_resolution', 21, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'max_iterations', 10, @(x) isnumeric(x) && isscalar(x) && x >= 1);
addParameter(p, 'tolerance', 1e-6, @(x) isnumeric(x) && isscalar(x) && x >= 0);
addParameter(p, 'local_radius', [], @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x > 0));
addParameter(p, 'verbose', false, @islogical);
parse(p, varargin{:});
opt = p.Results;

% Bounds relative to the initial guesses
X0_min = X0_initial - opt.center_search_range;
X0_max = X0_initial + opt.center_search_range;
Y0_min = Y0_initial - opt.center_search_range;
Y0_max = Y0_initial + opt.center_search_range;
R0_min = max(0, R0_initial - opt.radius_search_range);
R0_max = R0_initial + opt.radius_search_range;

X0_curr = X0_initial;
Y0_curr = Y0_initial;
R0_curr = R0_initial;
R_fixed = R_initial;
prev_residual = Inf;
history = struct('iteration', {}, 'X0', {}, 'Y0', {}, 'R0', {}, 'R', {}, ...
    'residual_after_center', {}, 'residual_after_radii', {});

for iter = 1:opt.max_iterations
    % Search windows shrink so that the bounds above are never exceeded
    center_range_iter = max(0, min([X0_curr - X0_min, X0_max - X0_curr, ...
        Y0_curr - Y0_min, Y0_max - Y0_curr]));
    radius_range_iter = max(0, min([R0_curr - R0_min, R0_max - R0_curr]));

    [X0_curr, Y0_curr, residual_center] = search_center(UWorld, coords, ...
        R0_curr, R_fixed, X0_curr, Y0_curr, center_range_iter, ...
        opt.center_resolution, opt.local_radius);

    [R0_curr, residual_R0] = search_reference_radius(UWorld, coords, ...
        X0_curr, Y0_curr, R_fixed, R0_curr, radius_range_iter, ...
        opt.radius_resolution, opt.local_radius);

    history(end + 1) = struct('iteration', iter, 'X0', X0_curr, 'Y0', Y0_curr, ...
        'R0', R0_curr, 'R', R_fixed, 'residual_after_center', residual_center, ...
        'residual_after_radii', residual_R0); %#ok<AGROW>
    if opt.verbose
        fprintf('  iter %d: X0=%.3f Y0=%.3f R0=%.3f residual=%.6f\n', ...
            iter, X0_curr, Y0_curr, R0_curr, residual_R0);
    end

    if abs(prev_residual - residual_R0) < opt.tolerance
        prev_residual = residual_R0;
        break
    end
    prev_residual = residual_R0;
end

X0_opt = X0_curr;
Y0_opt = Y0_curr;
R0_opt = R0_curr;
R_opt = R_fixed;
residual_opt = prev_residual;
end

function [X0_opt, Y0_opt, residual_opt] = search_center(UWorld, coords, R0, R, ...
    X0_init, Y0_init, search_range, resolution, local_radius)
% Exhaustive search of the bubble center on a square grid.
X0_range = linspace(X0_init - search_range, X0_init + search_range, resolution);
Y0_range = linspace(Y0_init - search_range, Y0_init + search_range, resolution);
[X0_grid, Y0_grid] = meshgrid(X0_range, Y0_range);
residual_surface = zeros(size(X0_grid));
for k = 1:numel(X0_grid)
    residual_surface(k) = bubble_fit_residual(UWorld, coords, X0_grid(k), ...
        Y0_grid(k), R0, R, local_radius);
end
[residual_opt, idx] = min(residual_surface(:));  % NaN-ignoring, first minimum
X0_opt = X0_grid(idx);
Y0_opt = Y0_grid(idx);
end

function [R0_opt, residual_opt] = search_reference_radius(UWorld, coords, X0, Y0, ...
    R_fixed, R0_init, search_range, resolution, local_radius)
% Exhaustive 1-D search of R0 with the constraint R > R0 (bubble expansion).
R0_range = linspace(R0_init - search_range, R0_init + search_range, resolution);
residual_values = Inf(size(R0_range));
for k = 1:numel(R0_range)
    if R_fixed <= R0_range(k)
        continue
    end
    residual_values(k) = bubble_fit_residual(UWorld, coords, X0, Y0, ...
        R0_range(k), R_fixed, local_radius);
end
[residual_opt, idx] = min(residual_values);
R0_opt = R0_range(idx);
end
