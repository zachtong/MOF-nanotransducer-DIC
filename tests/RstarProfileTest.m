classdef RstarProfileTest < matlab.unittest.TestCase
    %RSTARPROFILETEST  fit_rstar_profile and build_kymograph.

    properties
        Opts = struct('radiusUpperBound', 1e6, 'vonMisesStrainBounds', [0, 0.3], ...
            'rstarOuterFactor', 3)
    end

    methods (Test)
        function recoversQuadraticProfile(tc)
            [coords, rStar] = ring_nodes(10);
            coeff = [-0.05, 0.1, 0.12];
            evm = polyval(coeff, rStar);
            fit = fit_rstar_profile(coords, evm, evm, [0 0], 10, 10, 7, tc.Opts);
            tc.verifyEqual(fit.vonmises_coeff, coeff, 'AbsTol', 1e-10);
            tc.verifyEqual(fit.principal_coeff, coeff, 'AbsTol', 1e-10);
            tc.verifyEqual(fit.frame, 7);
            tc.verifyEqual(fit.vonmises_residual, zeros(size(fit.vonmises_residual)), 'AbsTol', 1e-10);
        end

        function regionExcludesBubbleAndFarField(tc)
            [coords, rStar] = ring_nodes(10);
            evm = 0.1 * ones(size(rStar));
            fit = fit_rstar_profile(coords, evm, evm, [0 0], 12, 10, 1, tc.Opts);
            tc.verifyGreaterThan(fit.vonmises_range(1), 1.2);   % r > Rs = 12
            tc.verifyLessThan(fit.vonmises_range(2), 3);        % r < 3 R0s
        end

        function upperBoundLimitsRegion(tc)
            [coords, rStar] = ring_nodes(10);
            evm = 0.1 * ones(size(rStar));
            opts = tc.Opts;
            opts.radiusUpperBound = 20;
            fit = fit_rstar_profile(coords, evm, evm, [0 0], 10, 10, 1, opts);
            tc.verifyLessThan(fit.vonmises_range(2), 2);
        end

        function strainBoundsDropOutliers(tc)
            [coords, rStar] = ring_nodes(10);
            coeff = [-0.02, 0.05, 0.1];
            evm = polyval(coeff, rStar);
            evm(1:7:end) = 0.9;                                  % outside [0, 0.3]
            fit = fit_rstar_profile(coords, evm, evm, [0 0], 10, 10, 1, tc.Opts);
            tc.verifyEqual(fit.vonmises_coeff, coeff, 'AbsTol', 1e-10);
        end

        function curvatureIsNonPositive(tc)
            % Convex data: unconstrained curvature > 0 -> constrained a <= 0.
            [coords, rStar] = ring_nodes(10);
            evm = 0.05 * (rStar - 2).^2 + 0.05;
            fit = fit_rstar_profile(coords, evm, evm, [0 0], 10, 10, 1, tc.Opts);
            tc.verifyLessThanOrEqual(fit.vonmises_coeff(1), 0);
            tc.verifyGreaterThan(fit.principal_coeff(1), 0);     % principal fit is unconstrained
        end

        function tooFewPointsGiveNaN(tc)
            coords = [15 0; 0 15];
            fit = fit_rstar_profile(coords, [0.1; 0.1], [0.1; 0.1], [0 0], 10, 10, 1, tc.Opts);
            tc.verifyTrue(all(isnan(fit.vonmises_coeff)));
        end

        function kymographKeepsFirstFramesRaw(tc)
            kp = default_params().kymo;
            n = 12;
            fits = repmat(struct('vonmises_coeff', [0 0 0]), n, 1);
            for i = 1:n
                fits(i).vonmises_coeff = [-0.01 * i, 0.02, 0.05 + 0.01 * mod(i, 3)];
            end
            kymo = build_kymograph(fits, 10, kp);
            tc.verifySize(kymo.evm_raw, [numel(kp.rStarGrid), n]);
            tc.verifyEqual(kymo.evm_grid_smoothed(:, 1:kp.frameCut), ...
                kymo.evm_raw(:, 1:kp.frameCut));
            tc.verifyEqual(kymo.time_us, (1:n) / 10, 'AbsTol', 1e-12);
        end
    end
end

function [coords, rStar] = ring_nodes(R0s)
[X, Y] = meshgrid(-40:1.5:40, -40:1.5:40);
coords = [X(:), Y(:)];
rStar = hypot(X(:), Y(:)) / R0s;
end
