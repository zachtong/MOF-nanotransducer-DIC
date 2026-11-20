# Reproducing the DIC analysis

This guide goes from the quickest check (minutes) to a full re-run from the
raw images (days).

## Quick way: `main.m`

1. Get the code and unzip the data set into `data/` of the repository
   (step 1 below).
2. Open `main.m` in MATLAB and set what to compute in its *Settings*
   block:

   | Setting in `main.m` | Step | What it reproduces | Data needed | Time |
   |---|---|---|---|---|
   | `runUnitTests` | [3](#3-unit-tests) | unit tests of the analysis functions | none | < 1 min |
   | `makeFigures` | [4](#4-published-figures) | Fig. 2D, 2F, Figs. S10–S13 from the archived results | recording zips | minutes |
   | `validateArchive` | [5](#5-check-the-code-against-the-archive) | last frame of every recording, recomputed and compared | recording zips | minutes |
   | `rerunPostprocessing`, `saveVonMisesMaps` | [6](#6-re-run-the-post-processing) | all frames, from the archived DIC displacements | recording zips | ~1 h per recording |
   | `rerunDIC` | [7](#7-re-run-dic-from-the-images) | DIC itself, from the TIFF frames | recording zips | several hours per recording |

   `cases` selects the recordings (`'all'` or a list of IDs such as
   `{'181404', '171925'}`). By default, steps 3–5 are switched on (about
   10 minutes in total) and the re-runs are off.
3. Run the script (Editor: *Run*, or type `main` in the Command Window).
   Results and figures are written to `output/`.

The sections below describe each step, the files it writes and the
expected result. Each step can also be run on its own from the Command
Window (step 2).

The default parameters (`config/default_params.m`) are those of the
published analysis. Do not change them to reproduce the paper.

## 0. Requirements

* MATLAB R2022a or newer.
* Toolboxes: Image Processing, Statistics and Machine Learning,
  Optimization and Signal Processing.
* Step 7 only: a C++ compiler for MATLAB (`mex -setup C++`, once). On Windows,
  for example, the free MinGW-w64 add-on or Visual Studio.
* Disk space: ~5 GB for the data, up to ~5 GB for the outputs of steps 6–7.

## 1. Get the code and the data

```
git clone https://github.com/zachtong/MOF-nanotransducer-DIC.git
```

Or download the release archive from Zenodo (DOI in `README.md`).

Download the data set from Zenodo. Unzip **all** downloaded zip files into
the folder `data/` of the repository. Each zip file already contains its
folders, so the result is:

```
MOF-nanotransducer-DIC/data/
├── ZIF-8/  ZIF-67/  NU-1003/  Microbubble/
│   ├── Jin_HH_MM_SS/                    TIFF frames
│   ├── Jin_HH_MM_SS_masks/<subfolder>/  masks
│   └── Jin_HH_MM_SS_DIC_results/        R_data_*.mat, before_sec8.mat, before_sec9.mat
├── raw/                                 camera files (not read by the code)
└── raw_not_analysed/
```

Nothing is ever written to the data folder.

To keep the data somewhere else, for example on a larger disk, set
`dataRoot` in `main.m` to that folder. Any folder with the layout above
works, for example the original analysis folder. Likewise, `outputRoot`
sets where results are written (default `output/`).

## 2. Running single steps from the Command Window

```matlab
cd('C:\path\to\MOF-nanotransducer-DIC')
setup_paths(false)   % steps 3-6 (no compiler needed); after every MATLAB start
setup_paths          % step 7: also compiles the two MEX files once
```

With the data in `data/` nothing else is needed. For other folders call
`set_data_paths('D:\my-data', 'D:\my-output')` once per MATLAB session.
The commands of steps 3–7 below can then be typed directly.

## 3. Unit tests

```matlab
run_tests
```

Expected: a table of tests, all `Passed`. No data are needed.

## 4. Published figures

```matlab
make_kymograph_figures('archive')
```

This reads `before_sec9.mat` of every recording, the state saved at the end
of the original analysis, and draws the r\*–time kymographs and
strain–time curves (r\* = 1.5, 2.0, 2.5) for the eight groups:

| Group | Recordings | Paper |
|---|---|---|
| ZIF-8 (10M) | 171925, 181404 | Fig. 2D |
| ZIF-8 (1M) | 172655, 180814 | Fig. 2F, Fig. S10 |
| ZIF-67 (10M), ZIF-67 (1M) | 163902, 113847; 164311, 115047 | Fig. S11 |
| NU-1003 (10M), NU-1003 (1M) | 162005, 155040; 162445, 160901 | Fig. S12 |
| Microbubble (10M), Microbubble (1M) | 111031; 112138 | Fig. S13 |

Output: `<outputRoot>/figures/kymographs_archive/<group>/` with
`<group>_heatmaps.svg`, `<group>_strain_time.svg` and `<group>_legend.svg`.
If `cases` selects only part of a group, the IDs are appended to these
names (e.g. `ZIF-8 (10M)_heatmaps_181404.svg`), so the files of the
complete group are kept.
The plotted data are those of the paper. Layout and fonts of the final
paper figures may differ from these SVG files.

## 5. Check the code against the archive

```matlab
validate_against_archive
```

For each recording, the last frame is recomputed from the archived
intermediate data with the code of this repository:

* primary-bubble refinement;
* particle-induced strain;
* r\* fit;
* kymograph smoothing (all frames);
* R–t data and initial guess.

Each result is compared with the values saved in `before_sec9.mat`.

Expected: 14 lines, each ending in `PASS` or `PASS*`, and
`14 / 14 cases pass`. The table is saved to
`<outputRoot>/validation/validation_summary.csv`.

* `PASS`: identical to round-off.
* `PASS*`: identical except the r\* fit coefficients, which differ by less
  than 1e-3. This is possible only for frames where the fit needs the
  curvature constraint (`lsqcurvefit`). Another MATLAB version may stop
  the optimizer at a slightly different point.

## 6. Re-run the post-processing

One recording (about 1 h):

```matlab
run_postprocessing_case('181404')
```

All 14 recordings (about 14 h; the loop continues if one fails):

```matlab
run_all_postprocessing
```

This repeats, for every frame:

* cumulative displacement and strain (plane fit) from the archived DIC
  result `before_sec8.mat`;
* primary-bubble refinement;
* particle-induced strain;
* r\* fit;

and then builds the kymograph. Results:
`<outputRoot>/processed/<id>_postprocessing.mat`.

Compare with the paper and draw the figures from your own results:

```matlab
compare_rerun_with_archive          % all frames vs. before_sec9.mat
make_kymograph_figures('rerun')     % -> <outputRoot>/figures/kymographs_rerun/
```

Expected: `PASS` or `PASS*` for every recording that was run, and
`MISSING` for recordings without a result. The table is saved to
`<outputRoot>/validation/rerun_vs_archive.csv`. Here `PASS*` allows the
r\* fit coefficients to differ by less than 1e-3, as in step 5. It also
allows the kymograph to differ by the corresponding amount, up to 0.013,
because the kymograph is built from these fits.

**Full-field von Mises maps** (Fig. 2C, Fig. S9, frames of Movie S2):

```matlab
run_postprocessing_case('181404', 'saveFigures', true)
```

This writes one 300-dpi JPG for every 5th frame to
`<outputRoot>/figures/vonmises_maps/181404/`. Other frames can be selected
with `'figureFrames', [2 50 100]`.

## 7. Re-run DIC from the images

Requires the MEX files (`setup_paths` without `false`).

```matlab
run_dic_case('181404')               % several hours
compare_dic_with_archive('181404')   % your displacements vs. before_sec8.mat
```

`run_dic_case` writes `<outputRoot>/dic/181404_dic_results.mat`.
`compare_dic_with_archive` reports:

* `meshDiffer`: the number of frame increments whose quadtree mesh
  differs;
* `maxDiffU`: the largest displacement difference, in px.

Expected: `PASS`, meaning identical meshes and differences below 1e-6 px.
Different MATLAB versions or compilers can give round-off differences; the
status is then `CHECK`. Judge it by the size of `maxDiffU` compared with
`maxAbsU`.

Then run the post-processing on your own DIC result and compare again:

```matlab
run_postprocessing_case('181404', 'dic', 'rerun')
compare_rerun_with_archive('181404')
```

The status here is normally `FAIL`, because even round-off differences in
the displacements change the primary-bubble fit slightly. Judge the result
by the size of the differences in the table instead: `maxDiffFitCoeff` and
`maxDiffKymograph` in strain, `maxDiffPrimaryLastFrame` in px.

For all recordings use `run_all_dic`, then `run_all_postprocessing('dic', 'rerun')`.

DIC runs on one worker (`params.dic.ClusterNo = 1`). The original analysis
used 16 workers. The IC-GN subsets are independent, so this changes only
the speed. With the Parallel Computing Toolbox you can pass

```matlab
p = default_params(); p.dic.ClusterNo = 8;
run_dic_case('181404', 'params', p)
```

## Outputs

```
output/   (or outputRoot set in main.m)
├── dic/<id>_dic_results.mat              run_dic_case
├── processed/<id>_postprocessing.mat     run_postprocessing_case, run_all_postprocessing
├── figures/kymographs_<source>/<group>/  make_kymograph_figures(source)
├── figures/vonmises_maps/<id>/           run_postprocessing_case(..., 'saveFigures', true)
└── validation/*.csv                      validate_against_archive, compare_*_with_archive
```

## Troubleshooting

| Message | Cause and fix |
|---|---|
| `Data folder not found: ...` | Unzip the data set into `data/` of the repository, or set `dataRoot` in `main.m` (Command Window: `set_data_paths`) |
| `Unrecognized function or variable 'run_postprocessing_case'` (or another function of this repository) | Run `setup_paths(false)` in the repository folder (again after restarting MATLAB) |
| `Could not compile ba_interp2.cpp` | No C++ compiler: run `mex -setup C++` (only needed for step 7) |
| `Unable to find file or directory ...before_sec9.mat` (or `before_sec8.mat`, `R_data_*.mat`), `DIC result file not found`, `Image folder not found`, `file not found: ...before_sec9.mat` | The recording zip of that case was not unzipped into the data folder. With only some recordings downloaded, list them in `cases` in `main.m` |
| `file not found: ...processed\<id>_postprocessing.mat` | Figures from your own results (`make_kymograph_figures('rerun')`) need step 6 first |
| Out of memory | Each `before_sec9.mat` is ~140 MB and is loaded one at a time; close other programs |
