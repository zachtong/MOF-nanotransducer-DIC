classdef BubbleModelTest < matlab.unittest.TestCase
    %BUBBLEMODELTEST  Analytical bubble field (fun_bubble_strain).

    properties
        X
        Y
    end

    methods (TestMethodSetup)
        function makeGrid(tc)
            [tc.X, tc.Y] = meshgrid(linspace(-200, 200, 41), linspace(-150, 150, 31));
            tc.X = tc.X(:);
            tc.Y = tc.Y(:);
            keep = hypot(tc.X - 10, tc.Y + 5) > 40;   % outside the bubble
            tc.X = tc.X(keep);
            tc.Y = tc.Y(keep);
        end
    end

    methods (Test)
        function noRadiusChangeGivesZeroField(tc)
            [ux, uy, exx, eyy, exy, ~, ~, ~, evm] = fun_bubble_strain(tc.X, tc.Y, 10, -5, 30, 30);
            tc.verifyEqual([ux; uy; exx; eyy; exy; evm], zeros(6 * numel(tc.X), 1), 'AbsTol', 1e-12);
        end

        function volumeConservation(tc)
            R0 = 30; R = 45; xc = 10; yc = -5;
            [ux, uy] = fun_bubble_strain(tc.X, tc.Y, xc, yc, R0, R);
            r0 = hypot(tc.X - xc, tc.Y - yc);
            r = hypot(tc.X + ux - xc, tc.Y + uy - yc);
            tc.verifyEqual(r.^3 - r0.^3, (R^3 - R0^3) * ones(size(r0)), 'RelTol', 1e-10);
        end

        function displacementIsRadial(tc)
            [ux, uy] = fun_bubble_strain(tc.X, tc.Y, 10, -5, 30, 45);
            cross = (tc.X - 10) .* uy - (tc.Y + 5) .* ux;
            tc.verifyEqual(cross, zeros(size(cross)), 'AbsTol', 1e-9);
        end

        function polarStrainsOnXAxis(tc)
            % On the x axis through the center, exx = err and eyy = ett.
            R0 = 20; R = 35; x = (60:10:150)'; y = zeros(size(x));
            [~, ~, exx, eyy, exy] = fun_bubble_strain(x, y, 0, 0, R0, R);
            r = (x.^3 + R^3 - R0^3).^(1/3);
            tc.verifyEqual(exx, (x ./ r).^2 - 1, 'RelTol', 1e-12);
            tc.verifyEqual(eyy, r ./ x - 1, 'RelTol', 1e-12);
            tc.verifyEqual(exy, zeros(size(x)), 'AbsTol', 1e-15);
        end

        function vonMisesMatchesComponents(tc)
            [~, ~, exx, eyy, exy, ~, ~, ~, evm] = fun_bubble_strain(tc.X, tc.Y, 10, -5, 30, 45);
            tc.verifyEqual(evm, sqrt(exx.^2 + eyy.^2 - exx .* eyy + 3 * exy.^2), 'RelTol', 1e-12);
        end

        function secondaryStrainRemovesPrimaryField(tc)
            % A DIC field equal to the model leaves zero secondary strain.
            xc = 10; yc = -5; R0 = 30; R = 45;
            [~, ~, exx, eyy, exy] = fun_bubble_strain(tc.X, tc.Y, xc, yc, R0, R);
            F = reshape([exx, exy, exy, eyy]', [], 1);   % [e11; e21; e12; e22]
            s = compute_secondary_strain(F, [tc.X, tc.Y], xc, yc, R0, R);
            tc.verifyEqual(s.secondary.vonMises, zeros(size(tc.X)), 'AbsTol', 1e-12);
        end
    end
end
