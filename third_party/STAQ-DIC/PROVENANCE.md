# Vendored STAQ-DIC files

This folder holds the subset of STAQ-DIC (© 2018 Jin Yang, BSD 3-Clause,
see `LICENSE`) that the analysis calls. The subset was determined by a
static dependency scan of the original main script.

**Upstream.** Files are taken from the analysis working copy: fork
`github.com/zachtong/STAQ-DIC` at commit `33cf05a`, itself based on
`github.com/FranckLab/STAQ-DIC` at `581bb0b`. They are copied byte for
byte, except that CRLF line endings were converted to LF.

**Reference.** J. Yang, V. Rubino, Z. Ma, J. Tao, Y. Yin, A. McGhee,
W. Pan, C. Franck. SpatioTemporally Adaptive Quadtree mesh (STAQ) digital
image correlation for resolving large deformations around complex
geometries and discontinuities. *Exp. Mech.* 62, 1191–1215 (2022).

## Local modifications already present in the working copy

These changes are uncommitted edits on top of fork commit `33cf05a` and
were part of the analysis. They are kept as they were. Commit `33cf05a`
itself also changes some upstream files; see the fork history.

| File | Change |
|---|---|
| `func/IntegerSearch.m` | Interactive search-zone prompt replaced by a fixed 120 px |
| `func/funICGNQuadtree.m` | Mask threshold written as `<= 0.4*(winsize+1)^2` (was `<`); image interpolation `ba_interp2(...,'cubic')` replaced by `ba_interp2_spline(...,'cubicspline')` (bicubic B-spline) |

`ReadImageQuadtree.m` and `ReadImageMasks.m` are interactive loaders. They
were also modified locally and are not included here. The non-interactive
loaders in `src/io/` replace them.

## Toolboxes

The code uses functions from these MATLAB toolboxes:

* Image Processing: `regionprops`, `bwconncomp`, `imgaussfilt`
* Statistics and Machine Learning: `knnsearch`, `pdist2`
* Curve Fitting: `fit`, inside a `try` block with a fallback
* Optimization: `lsqcurvefit`
* Signal Processing: `medfilt1`
