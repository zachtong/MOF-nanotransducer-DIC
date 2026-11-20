# Data set layout

The data set (Zenodo, [10.5281/zenodo.24386878](https://doi.org/10.5281/zenodo.24386878)) is described file by file in
[`dataset_README.md`](dataset_README.md), which is also the README of the
Zenodo record. This page summarizes which files each step of the code
reads.

Zenodo allows at most 100 files per record. The 6,880 data files are
therefore packed into 16 zip files: one per recording and two of camera
files. Unzipping all of them into one folder gives the
layout below. By default the code expects it in `data/` of the repository
(`dataRoot` in `main.m` sets another folder).

```
<dataRoot>/
├── <material>/                           ZIF-8, ZIF-67, NU-1003, Microbubble
│   ├── Jin_HH_MM_SS/                     TIFF frames used for DIC
│   ├── Jin_HH_MM_SS_masks/<subfolder>/   binary masks (subfolder: case_table.m)
│   └── Jin_HH_MM_SS_DIC_results/
│       ├── R_data_primary.mat            primary-bubble radius / center per frame
│       ├── R_data_secondary.mat          secondary-bubble radius / center per frame
│       ├── before_sec8.mat               DIC result (input of run_postprocessing_case)
│       └── before_sec9.mat               workspace after the original post-processing
├── raw/Jin_HH_MM_SS.dat                  camera files of the 14 recordings (not read by the code)
└── raw_not_analysed/                     4 recordings not used in the paper
```

| Files | Read by |
|---|---|
| TIFF frames + masks | `run_dic_case`, `run_postprocessing_case` |
| `R_data_*.mat` | `run_postprocessing_case`, `validate_against_archive` |
| `before_sec8.mat` | `run_postprocessing_case` (default `'dic', 'archive'`), `compare_dic_with_archive` |
| `before_sec9.mat` | `validate_against_archive`, `compare_rerun_with_archive`, `make_kymograph_figures('archive')` |

The TIFF folders hold the frames from the cavitation onset to the end of
the 256-frame camera sequence: 023/024–256 at 10 Mfps and 004/005–256 at
1 Mfps (`dataset_README.md` lists them per recording).

The data set is built with `tools/build_zenodo_dataset.py` from the
analysis folders and the camera files. Only files that the code reads are
packed.
