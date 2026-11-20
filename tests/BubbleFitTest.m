classdef BubbleFitTest < matlab.unittest.TestCase
    %BUBBLEFITTEST  Primary-bubble refinement.

    methods (Test)
        function recoversCenterOnSyntheticField(tc)
            [coords, U] = synthetic_field(181, 197, 30, 100);
            [x0, y0, r0] = optimize_bubble_4params(U, coords, 182, 195, 30, 100, ...
                'center_search_range', 3, 'center_resolution', 11, ...
                'radius_search_range', 3, 'radius_resolution', 21, ...
                'local_radius', 120);
            tc.verifyEqual([x0, y0], [181, 197], 'AbsTol', 1.0);
            tc.verifyEqual(r0, 30, 'AbsTol', 1.0);
        end

        function exactModelGivesZeroResidual(tc)
            [coords, U] = synthetic_field(0, 0, 20, 40);
            tc.verifyEqual(bubble_fit_residual(U, coords, 0, 0, 20, 40, 60), 0, 'AbsTol', 1e-12);
            tc.verifyEqual(bubble_fit_residual(U, coords, 0, 0, 20, 40, []), 0, 'AbsTol', 1e-12);
        end

        function tooFewLocalPointsGiveInf(tc)
            coords = [0 10; 0 -10; 50 0];
            tc.verifyEqual(bubble_fit_residual((1:6)', coords, 0, 0, 5, 5, 20), Inf);
        end

        function globalModeUsesAllEntries(tc)
            coords = [0 10; 0 -10; 50 0];
            U = [1; -2; 3; -4; 5; -6];
            tc.verifyEqual(bubble_fit_residual(U, coords, 0, 0, 5, 5, []), 3.5, 'AbsTol', 1e-12);
        end
    end
end

function [coords, U] = synthetic_field(xc, yc, R0, R)
[X, Y] = meshgrid(xc - 150:6:xc + 150, yc - 120:6:yc + 120);
keep = hypot(X(:) - xc, Y(:) - yc) > R + 2;
coords = [X(keep), Y(keep)];
[ux, uy] = fun_bubble_strain(coords(:, 1), coords(:, 2), xc, yc, R0, R);
U = reshape([ux, uy]', [], 1);
end
