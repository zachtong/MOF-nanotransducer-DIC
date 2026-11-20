# Provenance

This document records where each file of this repository comes from and
how it was adapted from the code that produced the published figures.

## Original analysis code

* The analysis ran as an interactive MATLAB session (Windows, 2025-09 to
  2026-04).
* It was based on a local copy of STAQ-DIC (fork `zachtong/STAQ-DIC`,
  commit `33cf05a`) with uncommitted changes:
  * `main_ALDIC_Quadtree_inc_Wenliang.m`, the main script (version of
    2026-04-28);
  * `func_ultrasound_particle_Wenliang/`, the project functions.
* Results of every recording were saved as full workspaces in
  `<case>_DIC_results/before_sec8.mat` and `before_sec9.mat`.

## Mapping

| Original | This repository | Changes |
|---|---|---|
| Main script, Sections 1–2 (interactive image, ROI, mask and parameter input) | `src/io/load_case_images.m`, `load_case_masks.m`, `config/` | Values taken from the archived `DICpara`; no GUI or prompts |
| Main script, frame loop, Sections 3–6 (lines 102–662) | `src/dic/run_dic_case.m` | Copied verbatim except removed comment blocks and debug plots (list: `provenance/run_dic_case_removed_lines.txt`), debug figures behind `showPlots`, two thresholds read from `default_params`. Same saved variables; the file is named `<id>_dic_results.mat` (original `results_<lastImage>_ws20_st8.mat`, archived as `before_sec8.mat`) |
| Main script, Section 7 (ADMM convergence printout) | — | Diagnostic only, not included |
| Main script, incremental → cumulative block | `src/postprocessing/compute_cumulative_displacement.m` | Interactive `pause` replaced by a warning |
| Main script, Section 8 | `src/postprocessing/run_postprocessing_case.m` | Prompts replaced by `default_params`; the circle-fit y-flip `251` is computed from the image height; loop over all frames |
| `fun_bubble_strain.m` (version used for the archived analysis) | same name | Disabled visualisation block removed |
| `optimize_bubble_4params.m`, `optimize_bubble_center(_local).m`, `optimize_bubble_radii_local.m` | `optimize_bubble_4params.m` + `bubble_fit_residual.m` | Merged. The global variant called a non-existent `bubble_strain`, and unused defaults had wrong `nargin` indices; both are fixed (neither path was used). |
| `PlotstrainQuadtreeMasks_secondary.m` (computation part) | `compute_secondary_strain.m` | Plotting removed; relative-path loads of unused colormaps removed |
| `PlotstrainQuadtreeMasks_secondary.m` (von Mises figure) + `SaveFigFilesDispAndStrainQuadtree_secondary.m` + `set_color_range_secondary.m` | `src/plotting/plot_secondary_vonmises.m`, `case_table.m` (`vonMisesClim`) | Only the von Mises map was exported; color ranges moved to the case table |
| r\* fit (lost) | `fit_rstar_profile.m` | Re-implemented and validated against the archive (`analysis_notes.md`, note 2) |
| "Preview" kymograph section of the main script | `build_kymograph.m` | Only the selected option kept (median + Gaussian, piecewise) |
| `plot_evm_evolution_and_rstar_comparison.m` | `src/plotting/plot_kymograph_comparison.m`, `scripts/make_kymograph_figures.m` | Hard-coded paths and `uigetdir` removed; groups taken from `case_table`. The top colorbar tick is no longer lost to floating-point rounding: for limit 0.15 with step 0.05, the original showed ticks only up to 0.10. Cosmetic only |
| `manually_define_R_t.m` | `src/rt/manual_secondary_tracks.m` | Manual tracks of the four solvent-filled recordings without a visible secondary bubble |
| STAQ-DIC library | `third_party/STAQ-DIC/` | Unchanged copy of the files actually used; see its `PROVENANCE.md` |

## New code without an original counterpart

* `scripts/`: batch runs, figure generation and the comparisons with the
  archived analysis (`validate_against_archive`,
  `compare_rerun_with_archive`, `compare_dic_with_archive`).
* `src/io/` loaders (replace the interactive file dialogs), `config/`.
* `tools/build_zenodo_dataset.py`: packs the data set.

## Not included

* `optimize_bubble_center.m` as a separate file; it is merged as described
  above.
* `plot_4param_optimization.m`, `plot_residual_surface.m` and
  `draw_sec_bubble.m`: diagnostic plots only.
* Main script Sections 9.5–10 and the "Nomin's dataset" block: template
  leftovers, not used for this paper.
