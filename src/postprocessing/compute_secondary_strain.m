function s = compute_secondary_strain(FStrainWorld, coords, Xc0, Yc0, R0, R)
%COMPUTE_SECONDARY_STRAIN  Particle-induced strain = DIC strain - primary-bubble strain.
%
%   s = COMPUTE_SECONDARY_STRAIN(FStrainWorld, coords, Xc0, Yc0, R0, R)
%
%   FStrainWorld  DIC strain in world axes, interleaved per node as
%                 [e11; e21; e12; e22; ...] (output of ComputeStrainQuadtree)
%   coords        N x 2 node coordinates (reference configuration, px)
%   Xc0, Yc0, R0, R  primary-bubble parameters (px)
%
%   Returns a struct with N x 1 fields
%     total.*      exx, exy, eyy, principalMax, principalMin, maxShear, vonMises
%     primary.*    exx, exy, eyy, principalMax, principalMin
%     secondary.*  exx, exy, eyy, principalMax, principalMin, maxShear, vonMises
%
%   As in the original analysis, the component-wise difference is taken for
%   exx, exy, eyy; secondary principal strains are differences of principal
%   values; secondary von Mises strain is evaluated from the secondary
%   components (it is not the difference of the two von Mises strains).

u_x = FStrainWorld(1:4:end);
v_x = FStrainWorld(2:4:end);
u_y = FStrainWorld(3:4:end);
v_y = FStrainWorld(4:4:end);

total.exx = u_x;
total.exy = 0.5 * (v_x + u_y);
total.eyy = v_y;
total.maxShear = sqrt((0.5 * (total.exx - total.eyy)).^2 + total.exy.^2);
total.principalMax = 0.5 * (total.exx + total.eyy) + total.maxShear;
total.principalMin = 0.5 * (total.exx + total.eyy) - total.maxShear;
total.vonMises = von_mises_strain(total.exx, total.exy, total.eyy);

[~, ~, p_exx, p_eyy, p_exy, p_e1, p_e2] = fun_bubble_strain( ...
    coords(:, 1), coords(:, 2), Xc0, Yc0, R0, R);
primary = struct('exx', p_exx, 'exy', p_exy, 'eyy', p_eyy, ...
    'principalMax', p_e1, 'principalMin', p_e2);

secondary.exx = total.exx - primary.exx;
secondary.exy = total.exy - primary.exy;
secondary.eyy = total.eyy - primary.eyy;
secondary.principalMax = total.principalMax - primary.principalMax;
secondary.principalMin = total.principalMin - primary.principalMin;
secondary.maxShear = sqrt((0.5 * (secondary.exx - secondary.eyy)).^2 + secondary.exy.^2);
secondary.vonMises = von_mises_strain(secondary.exx, secondary.exy, secondary.eyy);

s = struct('total', total, 'primary', primary, 'secondary', secondary);
end
