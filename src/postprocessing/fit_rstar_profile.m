function fit = fit_rstar_profile(coordsCurrent, evmSecondary, e1Secondary, ...
    centerXY, Rs, R0s, frame, opts)
%FIT_RSTAR_PROFILE  Quadratic fit of particle-induced strain versus r*.
%
%   fit = FIT_RSTAR_PROFILE(coordsCurrent, evmSecondary, e1Secondary, ...
%       centerXY, Rs, R0s, frame, opts)
%
%   coordsCurrent  N x 2 node coordinates in the current configuration (px)
%   evmSecondary   N x 1 particle-induced von Mises strain
%   e1Secondary    N x 1 particle-induced max principal strain
%   centerXY       [Xc_s, Yc_s] current secondary-bubble center (px)
%   Rs, R0s        current / reference (first-frame) secondary radius (px)
%   frame          image index (stored in fit.frame)
%   opts           struct with fields
%                    radiusUpperBound   outer bound of the region (px)
%                    vonMisesStrainBounds  [lo hi] accepted strain values
%                    rstarOuterFactor   region limited to r < factor * R0s
%
%   Region: Rs < r < rstarOuterFactor*R0s and r < radiusUpperBound, with
%   r the distance of each node (current configuration) to the secondary
%   center; r* = r / R0s.
%
%   von Mises:  evm(r*) = a r*^2 + b r* + c with a <= 0, fitted to finite
%               points inside vonMisesStrainBounds. Initial guess from
%               polyfit; constrained solution from lsqcurvefit
%               (Optimization Toolbox) when the polyfit curvature is > 0.
%   principal:  unconstrained polyfit of e1 versus r* on finite points.
%
%   Output fields (same layout as DICpara.fitResults in the archive):
%     frame, principal_coeff, principal_range, principal_residual,
%     vonmises_coeff, vonmises_range, vonmises_residual
%   Residuals are data - model; ranges are [min max] of r* of the points used.
%
%   NOTE  The original implementation of this step was lost. This function
%   re-implements it from the variables saved in the archived workspaces and
%   reproduces the archived fitResults (see scripts/validate_against_archive.m
%   and docs/provenance.md).

MIN_POINTS = 3;

dist = sqrt((coordsCurrent(:, 1) - centerXY(1)).^2 + (coordsCurrent(:, 2) - centerXY(2)).^2);
inRegion = dist > Rs & dist < opts.rstarOuterFactor * R0s & dist < opts.radiusUpperBound;
rStar = dist(inRegion) / R0s;
evm = real_or_error(evmSecondary(inRegion), 'evmSecondary');
e1 = real_or_error(e1Secondary(inRegion), 'e1Secondary');

fit = struct('frame', frame, ...
    'principal_coeff', nan(1, 3), 'principal_range', nan(1, 2), 'principal_residual', [], ...
    'vonmises_coeff', nan(1, 3), 'vonmises_range', nan(1, 2), 'vonmises_residual', []);

% ---- max principal strain: unconstrained quadratic ----
validP = isfinite(rStar) & isfinite(e1);
if nnz(validP) >= MIN_POINTS
    pCoeff = polyfit(rStar(validP), e1(validP), 2);
    fit.principal_coeff = pCoeff;
    fit.principal_range = [min(rStar(validP)), max(rStar(validP))];
    fit.principal_residual = e1(validP) - polyval(pCoeff, rStar(validP));
end

% ---- von Mises strain: quadratic with non-positive curvature ----
validV = isfinite(rStar) & isfinite(evm);
r = rStar(validV);
v = evm(validV);
lo = opts.vonMisesStrainBounds(1);
hi = opts.vonMisesStrainBounds(2);
keep = v >= lo & v <= hi;
r = r(keep);
v = v(keep);
if numel(r) >= MIN_POINTS
    vCoeff = fit_quadratic_nonpositive_curvature(r, v);
    fit.vonmises_coeff = vCoeff;
    fit.vonmises_range = [min(r), max(r)];
    fit.vonmises_residual = v - polyval(vCoeff, r);
end
end

function v = real_or_error(v, name)
% Strain values inside the r* region must be real.
if ~isreal(v)
    if any(imag(v(isfinite(v))) ~= 0)
        error('fit_rstar_profile:Complex', '%s is complex inside the r* region.', name);
    end
    v = real(v);
end
end

function p = fit_quadratic_nonpositive_curvature(x, y)
% polyfit initial guess; lsqcurvefit with a <= 0 only if needed.
p0 = polyfit(x, y, 2);
if p0(1) <= 0
    p = p0;
    return
end
model = @(c, xx) c(1) * xx.^2 + c(2) * xx + c(3);
lb = [-Inf, -Inf, -Inf];
ub = [0, Inf, Inf];
options = optimoptions('lsqcurvefit', 'Display', 'off');
p = lsqcurvefit(model, p0, x, y, lb, ub, options);
end
