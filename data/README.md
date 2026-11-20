# Data folder

Unzip the zip files of the data set (Zenodo, DOI in the main `README.md`)
here. Each zip file contains its own folders, so the result is:

```
data/
├── ZIF-8/  ZIF-67/  NU-1003/  Microbubble/
│   ├── Jin_HH_MM_SS/                    TIFF frames
│   ├── Jin_HH_MM_SS_masks/<subfolder>/  masks
│   └── Jin_HH_MM_SS_DIC_results/        R_data_*.mat, before_sec8.mat, before_sec9.mat
```

Everything in this folder except this file is ignored by git. To keep the
data elsewhere, set `dataRoot` in `main.m`.
