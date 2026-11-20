# Analysis notes

These notes were written while preparing this repository (November 2026),
by re-reading the original code and checking it against the archived
MATLAB workspaces. The code reproduces the published analysis.

## 1. Reference radius R0 often ends at its search bound

`R0` is searched within the circle-fit value ± 3 px. In the archived last
frames it often ends exactly on the upper bound. For example, 181404 gives
28.02 + 3 = 31.02. The search range may be too narrow. This affects only
the primary-bubble field that is subtracted.

## 2. Original r\*-fit code was lost; it was re-implemented

The code that filled `DICpara.fitResults` was not found in any surviving
copy of the analysis code. `fit_rstar_profile.m` re-implements it from
the intermediate variables saved in the archived workspaces, which
include region indices, filtered data, `p0`, `lb`, `ub` and `p_opt`.
Checks against the archive:

* Region selection, data filtering, `polyfit` coefficients and residuals
  reproduce the archived last frame of all 14 cases.
* In 7 of 14 cases the last frame needs the curvature constraint a ≤ 0
  (`lsqcurvefit`). Re-running `lsqcurvefit` in MATLAB is expected to
  reproduce the archived values exactly. Checked independently outside
  MATLAB, the archived solutions differ from the exact constrained optimum
  by at most 7e-4 in strain.

Run `validate_against_archive` (last frame) and `compare_rerun_with_archive`
(all frames, after `run_all_postprocessing`) to repeat these checks in MATLAB.

## 3. Mixed strain measures

DIC strains are Green–Lagrangian (`StrainType = 2`). The subtracted
primary-bubble field (`fun_bubble_strain`) uses infinitesimal strain.
Their difference is interpreted under the small-strain assumption. Close
to the primary bubble, where strains are larger, this assumption is
weakest.

## 4. Other notes

* `max_iterations = 10` was always passed to the refinement. A workspace
  variable `max_iterations = 5` in one archive is a leftover and was not
  used.
* The full-field figure export of April 2026 drew every 5th frame
  (`2:5:N`). The kymographs always used every frame. In this repository
  both are separate options of `run_postprocessing_case`.
