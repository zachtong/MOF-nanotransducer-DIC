function [disp_x, disp_y, exx, eyy, exy, e1, e2, e_shear_max, e_vm] = fun_bubble_strain( ...
    X0, Y0, Xc0, Yc0, R0, R)
%FUN_BUBBLE_STRAIN  Analytical field of a spherical bubble in an incompressible medium.
%
%   [disp_x, disp_y, exx, eyy, exy, e1, e2, e_shear_max, e_vm] = ...
%       FUN_BUBBLE_STRAIN(X0, Y0, Xc0, Yc0, R0, R)
%
%   Displacement and infinitesimal strain in the imaging plane induced by
%   a bubble whose radius changes from R0 to R (Equations S7-S9).
%
%   Inputs (all in px)
%     X0, Y0   point coordinates in the reference configuration
%     Xc0, Yc0 bubble center in the reference configuration
%     R0, R    bubble radius in the reference / current configuration
%
%   Outputs
%     disp_x, disp_y   displacement components (px)
%     exx, eyy, exy    infinitesimal strain components
%     e1, e2           max / min in-plane principal strain
%     e_shear_max      max in-plane shear strain
%     e_vm             von Mises equivalent strain
%
%   Model: volume conservation r^3 - r0^3 = R^3 - R0^3, radial strain
%   err = (r0/r)^2 - 1, hoop strain ett = r/r0 - 1, projected onto x-y.

dist_X0 = X0 - Xc0;
dist_Y0 = Y0 - Yc0;

% Incompressibility constant: r^3 - r0^3 = R^3 - R0^3
ConstC = R^3 - R0^3;

r0 = sqrt(dist_X0.^2 + dist_Y0.^2);   % reference radial distance
r = (r0.^3 + ConstC).^(1/3);          % current radial distance

% Radial displacement and its Cartesian components
disp_r = r - r0;
disp_x = (dist_X0 ./ r0) .* disp_r;
disp_y = (dist_Y0 ./ r0) .* disp_r;

% Radial and hoop strains (polar basis)
err = (r0 ./ r).^2 - 1;
ett = (r ./ r0) - 1;

% Direction cosines of the reference radial direction
c2 = (dist_X0 ./ r0).^2;
s2 = (dist_Y0 ./ r0).^2;
cs = (dist_X0 ./ r0) .* (dist_Y0 ./ r0);

% Cartesian strain components
exx = err .* c2 + ett .* s2;
exy = (err - ett) .* cs;
eyy = err .* s2 + ett .* c2;

% Principal strains, max shear and von Mises equivalent strain
e_avg = 0.5 * (exx + eyy);
e_shear_max = sqrt(((exx - eyy) / 2).^2 + exy.^2);
e1 = e_avg + e_shear_max;
e2 = e_avg - e_shear_max;
e_vm = von_mises_strain(exx, exy, eyy);
end
