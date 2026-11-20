function res = bubble_fit_residual(UWorld, coords, Xc, Yc, R0, R, localRadius)
%BUBBLE_FIT_RESIDUAL  Mean absolute misfit between DIC and bubble-model displacements.
%
%   res = BUBBLE_FIT_RESIDUAL(UWorld, coords, Xc, Yc, R0, R, localRadius)
%
%   UWorld      measured displacement, interleaved [u1; v1; u2; v2; ...]
%   coords      N x 2 node coordinates (reference configuration)
%   Xc, Yc      trial bubble center
%   R0, R       trial reference / current bubble radius
%   localRadius []  -> use every node ("global" mode)
%               >0  -> use nodes within localRadius of (Xc, Yc)
%
%   Returns Inf when fewer than MIN_LOCAL_POINTS nodes are inside the local
%   region.

MIN_LOCAL_POINTS = 10;

[Ux, Uy] = fun_bubble_strain(coords(:, 1), coords(:, 2), Xc, Yc, R0, R);
U_model = [Ux, Uy].';
resid = UWorld - U_model(:);

if isempty(localRadius)
    res = mean(abs(resid));
    return
end

distances = sqrt((coords(:, 1) - Xc).^2 + (coords(:, 2) - Yc).^2);
local_mask = distances <= localRadius;
if sum(local_mask) < MIN_LOCAL_POINTS
    res = Inf;
    return
end
local_residuals = abs(resid(local_mask));
res = mean(local_residuals);
end
