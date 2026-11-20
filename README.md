# MOF-nanotransducer-DIC

This repository holds the MATLAB code for the ultra-high-speed digital image
correlation (DIC) analysis in

> W. Wang *et al.*, liquid-phase gas nanotransducers based on metal–organic
> frameworks, *Science* (in revision; title and DOI will be added).

It measures the strain that liquid-phase gas nanotransducers (ZIF-8, ZIF-67
and NU-1003 metal–organic-framework particles, with and without loaded gas)
and microbubbles induce in a gelatin hydrogel. The particles are excited by
the pressure wave of a laser-induced cavitation bubble.

The code produces the data behind Fig. 2C–F, Figs. S9–S13 and Movie S2.

Data set (Zenodo): [10.5281/zenodo.24386878](https://doi.org/10.5281/zenodo.24386878). Unzip it into `data/`.
Code (this repository, Zenodo): [10.5281/zenodo.24386905](https://doi.org/10.5281/zenodo.24386905).

## Pipeline

1. **DIC.** Incremental STAQ-DIC computes the displacement of the speckle
   pattern between consecutive frames (`src/dic/run_dic_case.m`).
2. **Cumulative displacement and strain.** Displacements are accumulated
   and strain is computed by local plane fitting
   (`src/postprocessing/run_postprocessing_case.m`).
3. **Primary bubble.** An incompressible spherical-cavity model is fitted
   to the DIC field around the laser-induced bubble, starting from its
   radius–time curve (`fun_bubble_strain.m`, `optimize_bubble_4params.m`).
4. **Particle-induced strain.** The DIC strain minus the model strain
   (`compute_secondary_strain.m`).
5. **r\* profile.** At every frame, the particle-induced von Mises strain
   is fitted as a function of the distance to the particle,
   r\* = r / R_particle (`fit_rstar_profile.m`).
6. **Kymograph.** The fits are assembled into a smoothed r\*–time map,
   with strain–time curves at r\* = 1.5, 2.0 and 2.5
   (`build_kymograph.m`, `plot_kymograph_comparison.m`).

See `docs/methodology.md` for equations and parameters.

## Recordings

| ID | Material | Gas | Frame rate | Used in |
|---|---|---|---|---|
| 171925 / 181404 | ZIF-8 | no / yes | 10 Mfps | Fig. 2C–D, Fig. S9 |
| 172655 / 180814 | ZIF-8 | no / yes | 1 Mfps | Fig. 2F, Fig. S10 |
| 163902 / 113847 | ZIF-67 | no / yes | 10 Mfps | Fig. S11 |
| 164311 / 115047 | ZIF-67 | no / yes | 1 Mfps | Fig. S11 |
| 162005 / 155040 | NU-1003 | no / yes | 10 Mfps | Fig. S12 |
| 162445 / 160901 | NU-1003 | no / yes | 1 Mfps | Fig. S12 |
| 111031 / 112138 | Microbubbles | – | 10 / 1 Mfps | Fig. S13 |

The full list is in `config/case_table.m`. The data set (Zenodo) and its
layout are described in `docs/dataset_README.md` and `docs/data_layout.md`.

## Requirements

* MATLAB R2022a or newer. Development used Windows; macOS and Linux should
  also work.
* Toolboxes:
  * Image Processing
  * Statistics and Machine Learning
  * Optimization
  * Signal Processing
  * Curve Fitting (optional)
* A C++ compiler for the two interpolation MEX files (`mex -setup C++`),
  only to re-run DIC.

## Quick start

1. Unzip the data set (Zenodo) into `data/` of this repository.
2. Open `main.m` in MATLAB, choose what to compute in its *Settings*
   block, and run it. Results and figures are written to `output/`.

By default `main.m` runs the unit tests, draws Fig. 2D/F and Figs. S10–S13
from the archived results, and checks the code against the archived
analysis (about 10 minutes). Re-running the post-processing (~1 h per
recording) and DIC (hours per recording) are switched off by default.

Step-by-step instructions, expected results and the equivalent
Command Window calls are in **[`docs/reproduce.md`](docs/reproduce.md)**.

## Reproducibility notes

The default settings reproduce the published analysis. The original
implementation of the r\* fit was lost; it was re-implemented and
validated against the archived results. Details and other notes are in
`docs/analysis_notes.md`.

`docs/provenance.md` describes where each part of the code comes from.

## Repository structure

```
main.m             start here: choose the steps and run
data/              unzip the data set here (ignored by git)
config/            case table, parameters
src/dic/           STAQ-DIC driver (non-interactive)
src/io/            image, mask and R-t loaders
src/postprocessing bubble model, fit, particle-induced strain, r* fit, kymograph
src/plotting/      full-field maps and kymograph figures
src/rt/            manually defined particle tracks (4 solvent-filled cases)
scripts/           batch runs, figures, comparison with the archived analysis
tools/             build_zenodo_dataset.py (packs the data set for Zenodo)
tests/             unit tests (matlab.unittest)
third_party/       subset of STAQ-DIC used (BSD 3-Clause)
docs/              reproduce.md, methodology, data set, provenance, analysis notes
```

## Citation and license

If you use this code, please cite the paper and the STAQ-DIC method
(Yang *et al.*, *Exp. Mech.* 62, 1191–1215, 2022). See `CITATION.cff`.

The code in this repository is released under the BSD 3-Clause license
(`LICENSE`). `third_party/STAQ-DIC` keeps its own BSD 3-Clause license.

Contact: Zixiang Tong and Jin Yang, The University of Texas at Austin
(see the paper for e-mail addresses), or open an issue in this repository.
