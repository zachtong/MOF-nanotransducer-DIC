# Ultra-high-speed DIC data: MOF liquid-phase gas nanotransducers

Data set for the digital image correlation (DIC) analysis in

> *[Manuscript title]*, W. Wang *et al.*, *Science* (in revision).

The analysis code is in the repository
[`MOF-nanotransducer-DIC`](https://github.com/zachtong/MOF-nanotransducer-DIC)
(code DOI: *to be added*). This data set and the code together reproduce
Fig. 2C–F, Figs. S9–S13 and Movie S2 of the paper.

Each recording shows a gelatin hydrogel that contains one particle
(ZIF-8, ZIF-67 or NU-1003, solvent-filled or gas-loaded) or one
microbubble. A laser-induced cavitation bubble near the particle sends a
pressure wave through the gel. Recordings are 400 × 250 px at 3.2 µm/px,
taken at 10 Mfps (0.1 µs between frames) or 1 Mfps (1 µs between frames).

## Recordings

| ID | Material | Loaded gas | Frame rate | Frames used | Used in |
|---|---|---|---|---|---|
| 171925 | ZIF-8 | no | 10 Mfps | 024–256 (233) | Fig. 2D, Fig. S9 |
| 181404 | ZIF-8 | yes | 10 Mfps | 024–256 (233) | Fig. 2C–D, Fig. S9 |
| 172655 | ZIF-8 | no | 1 Mfps | 004–256 (253) | Fig. 2F, Fig. S10 |
| 180814 | ZIF-8 | yes | 1 Mfps | 004–256 (253) | Fig. 2F, Fig. S10 |
| 163902 | ZIF-67 | no | 10 Mfps | 023–256 (234) | Fig. S11 |
| 113847 | ZIF-67 | yes | 10 Mfps | 023–256 (234) | Fig. S11 |
| 164311 | ZIF-67 | no | 1 Mfps | 005–256 (252) | Fig. S11 |
| 115047 | ZIF-67 | yes | 1 Mfps | 005–256 (252) | Fig. S11 |
| 162005 | NU-1003 | no | 10 Mfps | 023–256 (234) | Fig. S12 |
| 155040 | NU-1003 | yes | 10 Mfps | 023–256 (234) | Fig. S12 |
| 162445 | NU-1003 | no | 1 Mfps | 004–256 (253) | Fig. S12 |
| 160901 | NU-1003 | yes | 1 Mfps | 005–256 (252) | Fig. S12 |
| 111031 | Microbubble | – | 10 Mfps | 024–256 (233) | Fig. S13 |
| 112138 | Microbubble | – | 1 Mfps | 004–256 (253) | Fig. S13 |

The ID is the acquisition time (HHMMSS). The recording folder is
`Jin_HH_MM_SS`. Frame numbers refer to the 256-frame camera sequence. The
first frame used is the DIC reference; the frames before the cavitation
onset are not used.

## Files in this record

| File | Contents | Size |
|---|---|---|
| `<id>_<material>[_<gas>]_<fps>.zip` (14), e.g. `181404_ZIF-8_gas_10Mfps.zip`, `111031_Microbubble_10Mfps.zip` | everything of one recording needed by the code (see below) | 270–430 MB each |
| `processed.zip` | `processed/<id>_postprocessing.mat`: r\* fits and kymographs of all 14 recordings | < 50 MB |
| `raw_camera_files.zip` | `raw/Jin_HH_MM_SS.dat`: original camera files of the 14 recordings | 0.72 GB |
| `raw_camera_files_not_analysed.zip` | `raw_not_analysed/`: 4 recordings of the same sessions that were **not analysed and not used in the paper** (11:20:09, 11:37:40, 11:41:55, 16:21:34) | 0.20 GB |
| `MANIFEST.tsv` | every file inside the zip files with size and SHA-256 | |
| `README.md` | this file | |

## How to use

1. Download the zip files you need (see the table below) and unzip all of
   them into **one** folder, for example `MOF-nanotransducer-DIC-data/`.
   Each zip already contains its folder structure, so the result is:

   ```
   MOF-nanotransducer-DIC-data/
   ├── ZIF-8/  ZIF-67/  NU-1003/  Microbubble/
   │   ├── Jin_HH_MM_SS/                    TIFF frames
   │   ├── Jin_HH_MM_SS_masks/<subfolder>/  binary masks
   │   └── Jin_HH_MM_SS_DIC_results/        R_data_*.mat, before_sec8.mat, before_sec9.mat
   ├── processed/                           <id>_postprocessing.mat
   ├── raw/                                 camera files
   └── raw_not_analysed/
   ```

2. Get the code, and in MATLAB point `dataRoot` in `config/data_paths.m` to
   this folder. `docs/reproduce.md` of the code repository describes every
   step.

| Goal | Zip files needed |
|---|---|
| Figures only (kymographs and strain–time curves) | `processed.zip` |
| Check the code against the archived analysis | the recording zips |
| Re-run the post-processing (strain, bubble model, r\* fits) | the recording zips |
| Re-run DIC from the images | the recording zips |
| Original camera data | `raw_camera_files.zip` |

## File formats

All MATLAB files are MAT-file version 7 and can also be read with
`scipy.io.loadmat`. Lengths are in pixels and image coordinates are
1-based [row, column] unless stated otherwise.

**TIFF frames** `Jin_HH_MM_SS/Jin_HH_MM_SS_NNN.tiff`, NNN = frame number.
400 × 250 px, 8-bit grayscale (stored as palette images with a linear gray
color map, so the pixel index is the gray value). The frames of 163902
are 16-bit grayscale. These are the exact files used for DIC; their names
and byte sizes match the file list stored in `before_sec8.mat`.

**Masks** `Jin_HH_MM_SS_masks/<subfolder>/`, one binary 8-bit TIFF per
frame. Nonzero = region analysed by DIC, zero = excluded (bubbles). Mask
file names do not always match the frame names. The k-th mask in
alphabetical order belongs to the k-th frame. The subfolder that was used
is given in `config/case_table.m` of the code; only that subfolder is
included.

**R_data_primary.mat** Radius and center of the laser-induced (primary)
bubble in every frame, from circle fits to the bubble edge:
`CircleR_primary` (N × 1), `CircleCenterSave_primary` (N × 2, [row col]),
`CircleEdgePtSave_primary` (edge points). In 171925 and 181404 the same
variables are named without the `_primary` suffix (`CircleR`,
`CircleCenterSave`, …). These two files also contain `CircleR_smoothed`,
which was not used.

**R_data_secondary.mat** Radius and center of the particle-induced
(secondary) bubble, `CircleR_secondary` and `CircleCenterSave_secondary`.
In four solvent-filled recordings no secondary bubble is visible
(162005, 163902, 162445, 164311). There the particle position was defined
by hand, and the file holds that track.

**before_sec8.mat** MATLAB workspace after DIC: `DICpara` (parameters),
`DICmesh`, `ResultDisp{k}` (`U`: incremental displacement of increment k,
`U_accum`: cumulative displacement since the reference frame; interleaved
[u1 v1 u2 v2 …] in px), `ResultFEMeshEachFrame{k}` (quadtree mesh) and
`file_name` (the frames used). This is the input of the post-processing.

**before_sec9.mat** MATLAB workspace at the end of the original
post-processing. It contains the state of the last frame and the results of
all frames: `DICpara.fitResults` (r\* fit of every frame), `evm_raw`,
`evm_grid_smoothed`, `r_star_grid`, `time_grid` (kymograph). The code uses it
to check its results against the paper.

**processed/<id>_postprocessing.mat** Compact results, extracted from
`before_sec9.mat`: `fitResults`, `kymo` (`r_star_grid`, `time_grid`,
`time_us`, `evm_raw`, `evm_grid_smoothed`), `primaryFit`, `caseInfo`,
`params`, `imageNames`. Same layout as the output of the code's
`run_postprocessing_case`.

**raw/\*.dat** Original files of the high-speed camera, 256 frames each
(51,209,408 bytes, i.e. 256 × 400 × 250 × 16 bit plus a header). The code
does not read them; the TIFF frames above were used for the analysis.

## Notes

* Notes on the analysis are in `docs/analysis_notes.md` of the code
  repository.
* `MANIFEST.tsv` can be used to verify the unpacked files (SHA-256).

## License and citation

Data: CC BY 4.0. Please cite the paper and this data set.
