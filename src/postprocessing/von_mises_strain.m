function evm = von_mises_strain(exx, exy, eyy)
%VON_MISES_STRAIN  In-plane von Mises equivalent strain.
%
%   evm = VON_MISES_STRAIN(exx, exy, eyy) with exy the tensorial shear
%   strain. This is the corrected expression used throughout the analysis
%   (cf. YangMechanicsGroupUTAustin/STAQ-DIC commit 7630f93, 2025-11-12).

evm = sqrt(exx.^2 + eyy.^2 - exx .* eyy + 3 * exy.^2);
end
