# Methodology of the DIC post-processing

This note summarises the analysis behind Fig. 2C–F and Figs. S9–S13. All
lengths are in pixels (3.2 µm/px, 400 × 250 px images). Parameters are set
in `config/default_params.m`; the numbered steps match the code.

## 1. Digital image correlation (`src/dic/run_dic_case.m`)

The method is incremental STAQ-DIC (Yang et al., *Exp. Mech.* 2022) on the
masked image sequence. Each frame uses the previous frame as reference.

| Setting | Value |
|---|---|
| Subset size / step | 20 px / 8 px |
| Finest quadtree element | 2 px |
| Initial guess | Whole-field FFT cross-correlation, search zone 120 px. Points with correlation < 0.85 are filled by nearest neighbour, the rest by thin-plate RBF + `regularizeNd`. |
| Solver | Local IC-GN (Subproblem 1); global FE step (Subproblem 2); ADMM, at most 3 steps. |
| Interpolation | Bicubic B-spline (`ba_interp2_spline`) in the first local step |

Incremental displacements are accumulated on the first-frame mesh with
thin-plate RBF interpolation (`compute_cumulative_displacement.m`).

## 2. Strain (`run_postprocessing_case.m`, STAQ-DIC `ComputeStrainQuadtree`)

* The cumulative displacement is smoothed 3 times (`funSmoothDispQuadtree`).
* Strain comes from a plane fit with half window 40 px. It is expressed
  as Green–Lagrangian strain.

## 3. Primary bubble

The radius `R(t)` and center of the laser-induced bubble come from circle
fits of the bubble edge in each image (`R_data_primary.mat`, from the
MATLAB predecessor of
[BubbleTrack](https://github.com/YangMechanicsGroupUTAustin/BubbleTrack)).

The model is a spherical cavity in an incompressible medium
(`fun_bubble_strain.m`, Eqs. S7–S9):

r³ − r₀³ = R³ − R₀³,  u_r = r − r₀,  ε_rr = (r₀/r)² − 1,  ε_θθ = r/r₀ − 1.

For every frame, the center (X_c, Y_c) and R₀ are refined by fitting the
model displacement to the DIC displacement (`optimize_bubble_4params.m`):

* hierarchical grid search: center ± 3 px on an 11 × 11 grid, then R₀ ± 3 px
  on 21 values;
* R fixed; residual taken within 1.2 R of the center;
* at most 10 iterations.

See `analysis_notes.md` (note 1).

## 4. Particle-induced (secondary) strain (`compute_secondary_strain.m`)

ε_secondary = ε_DIC − ε_primary, component by component. The von Mises
strain is evaluated from the secondary components:

ε_vm = √(ε_xx² + ε_yy² − ε_xx ε_yy + 3 ε_xy²).

## 5. r\* profile (`fit_rstar_profile.m`)

* r is the distance from each node, in the current configuration, to the
  secondary-bubble (particle) center (`R_data_secondary.mat`).
* r\* = r / R₀,s, where R₀,s is the first-frame radius.
* Nodes are used when R_s(t) < r < 3 R₀,s and r < 70 px.
* ε_vm(r\*) = a r\*² + b r\* + c is fitted to points with 0 ≤ ε_vm ≤ 0.3,
  with a ≤ 0 (`polyfit`, then `lsqcurvefit` if needed).

## 6. Kymograph (`build_kymograph.m`)

* ε_vm(r\*, t) is evaluated from the per-frame fits on r\* = 1.01:0.01:3.
* It is smoothed with a temporal median filter (5 frames) and a Gaussian
  filter (σ_r\* = 0.5, σ_t = 2 frames).
* The first 4 frames are left unsmoothed.
* Strain–time curves are rows of this map at r\* = 1.5, 2.0, 2.5.
* Time in µs is frame / (frame rate in MHz).

## Assumptions

The model assumes:

* incompressibility;
* spherical symmetry of the primary bubble;
* small strain;
* linear superposition of the primary and particle-induced fields;
* no feedback of the particle on the primary bubble.
