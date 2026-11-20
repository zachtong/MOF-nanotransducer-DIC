#!/usr/bin/env python3
"""Build the Zenodo data set of the DIC analysis from the analysis folders.

Zenodo accepts at most 100 files per record, so the ~7,000 data files are
packed into 19 files:

    README.md                              data set description (docs/dataset_README.md)
    MANIFEST.tsv                           every packed file: zip, path, bytes, SHA-256
    <id>_<material>[_<gas>]_<fps>.zip      one per recording (14): TIFF frames, masks,
                                           R_data_*.mat, before_sec8.mat, before_sec9.mat
    processed.zip                          processed/<id>_postprocessing.mat (14)
    raw_camera_files.zip                   raw/<folder>.dat of the 14 analysed recordings
    raw_camera_files_not_analysed.zip      raw_not_analysed/*.dat, recordings of the same
                                           sessions that were not analysed

Unzipping all zip files into one folder recreates the layout that the
MATLAB code expects (dataRoot in config/data_paths.m).

Only the files the code reads are packed: image files of the frame folder
and of the mask folder listed in config/case_table.m, and the four result
files. Recordings are read from config/case_table.m.

Usage
    python3 tools/build_zenodo_dataset.py --data-root DIR --raw-dir DIR \
        [--processed-dir DIR] --out DIR [--dry-run]

    --data-root      folder with <material>/<folder>... (the analysis data)
    --raw-dir        folder with the camera files <folder>.dat
    --processed-dir  folder with <id>_postprocessing.mat, written by
                     export_processed_from_archive (MATLAB):
                     <outputRoot>/dataset_processed/processed
    --out            empty output folder for the record files
    --dry-run        list what would be packed (sizes only), write nothing

Standard library only (Python 3.8+).
"""
import argparse
import hashlib
import os
import re
import shutil
import sys
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CASE_TABLE = REPO / "config" / "case_table.m"
DATASET_README = REPO / "docs" / "dataset_README.md"
# Same extensions as src/io/list_image_files.m
IMAGE_EXT = (".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".png", ".jp2")
RESULT_FILES = ("R_data_primary.mat", "R_data_secondary.mat", "before_sec8.mat", "before_sec9.mat")
STORED_EXT = (".mat",)  # already compressed; store without deflate
CHUNK = 1 << 20


def read_case_table(path):
    """Rows of caseRows in config/case_table.m."""
    text = path.read_text(encoding="utf-8")
    block = re.search(r"caseRows\s*=\s*\{(.*?)\n\};", text, re.S)
    if not block:
        sys.exit(f"Could not find caseRows in {path}")
    cases = []
    for line in block.group(1).splitlines():
        line = line.strip()
        if not line.startswith("'"):
            continue
        tokens = re.findall(r"'[^']*'|\[[^\]]*\]|[^,\s]+", line)
        tokens = [t for t in tokens if t != "..."]
        cid, folder, material = (t.strip("'") for t in tokens[:3])
        gas, fps, mask_sub = tokens[3], float(tokens[4]), tokens[5].strip("'")
        cases.append({"id": cid, "folder": folder, "material": material,
                      "gas": gas, "fps": fps, "maskSubdir": mask_sub})
    if len(cases) != 14:
        sys.exit(f"Expected 14 recordings in {path}, found {len(cases)}")
    return cases


def zip_name(case):
    gas = {"0": "_no-gas", "1": "_gas"}.get(case["gas"], "")
    return f"{case['id']}_{case['material']}{gas}_{case['fps']:g}Mfps.zip"


def visible_files(folder, extensions=None):
    if not folder.is_dir():
        sys.exit(f"Folder not found: {folder}")
    files = [p for p in sorted(folder.iterdir())
             if p.is_file() and not p.name.startswith(".")
             and (extensions is None or p.suffix.lower() in extensions)]
    if not files:
        sys.exit(f"No files found in {folder}")
    return files


def case_members(root, case):
    """(source path, path inside the zip) of one recording."""
    mat, folder = case["material"], case["folder"]
    image_dir = Path(mat) / folder
    mask_dir = Path(mat) / f"{folder}_masks"
    if case["maskSubdir"]:
        mask_dir = mask_dir / case["maskSubdir"]
    result_dir = Path(mat) / f"{folder}_DIC_results"
    images = visible_files(root / image_dir, IMAGE_EXT)
    masks = visible_files(root / mask_dir, IMAGE_EXT)
    if len(images) != len(masks):
        sys.exit(f"{case['id']}: {len(images)} images but {len(masks)} masks")
    members = [(p, image_dir / p.name) for p in images]
    members += [(p, mask_dir / p.name) for p in masks]
    for name in RESULT_FILES:
        src = root / result_dir / name
        if not src.is_file():
            sys.exit(f"{case['id']}: missing {src}")
        members.append((src, result_dir / name))
    return members, len(images)


def plan(args, cases):
    """List of (zip name, [(source, arcname)]) for the whole record."""
    archives = []
    for case in cases:
        members, n_frames = case_members(args.data_root, case)
        case["frames"] = n_frames
        archives.append((zip_name(case), members))

    analysed = {f"{c['folder']}.dat" for c in cases}
    raw = visible_files(args.raw_dir, (".dat",))
    missing = analysed - {p.name for p in raw}
    if missing:
        sys.exit(f"Camera files not found in {args.raw_dir}: {sorted(missing)}")
    archives.append(("raw_camera_files.zip",
                     [(p, Path("raw") / p.name) for p in raw if p.name in analysed]))
    others = [p for p in raw if p.name not in analysed]
    if others:
        archives.append(("raw_camera_files_not_analysed.zip",
                         [(p, Path("raw_not_analysed") / p.name) for p in others]))

    if args.processed_dir:
        processed = []
        for case in cases:
            src = args.processed_dir / f"{case['id']}_postprocessing.mat"
            if not src.is_file():
                sys.exit(f"Missing processed file: {src}")
            processed.append((src, Path("processed") / src.name))
        archives.append(("processed.zip", processed))
    return archives


def add_file(zf, src, arcname):
    """Write one file into the zip and return its SHA-256."""
    digest = hashlib.sha256()
    compress = zipfile.ZIP_STORED if src.suffix.lower() in STORED_EXT else zipfile.ZIP_DEFLATED
    info = zipfile.ZipInfo.from_file(src, arcname.as_posix())
    info.compress_type = compress
    with open(src, "rb") as fin, zf.open(info, "w", force_zip64=True) as fout:
        for chunk in iter(lambda: fin.read(CHUNK), b""):
            digest.update(chunk)
            fout.write(chunk)
    return digest.hexdigest()


def write_record(args, archives):
    args.out.mkdir(parents=True, exist_ok=True)
    if any(not p.name.startswith(".") for p in args.out.iterdir()):
        sys.exit(f"Output folder is not empty: {args.out}")
    manifest = ["zip\tpath\tbytes\tsha256"]
    for name, members in archives:
        target = args.out / name
        print(f"Writing {name} ({len(members)} files) ...", flush=True)
        with zipfile.ZipFile(target, "w", allowZip64=True) as zf:
            for src, arcname in members:
                sha = add_file(zf, src, arcname)
                manifest.append(f"{name}\t{arcname.as_posix()}\t{src.stat().st_size}\t{sha}")
        with zipfile.ZipFile(target) as zf:
            bad = zf.testzip()
        if bad:
            sys.exit(f"CRC check failed for {bad} in {name}")
    (args.out / "MANIFEST.tsv").write_text("\n".join(manifest) + "\n", encoding="utf-8")
    shutil.copyfile(DATASET_README, args.out / "README.md")


def summarize(archives, out=None):
    total = 0
    print(f"{'file':45s} {'members':>8s} {'MB':>9s}")
    for name, members in archives:
        size = (out / name).stat().st_size if out else sum(s.stat().st_size for s, _ in members)
        total += size
        print(f"{name:45s} {len(members):8d} {size / 1e6:9.1f}")
    n_record = len(archives) + 2  # + README.md, MANIFEST.tsv
    n_packed = sum(len(m) for _, m in archives)
    print(f"\n{n_packed} data files in {len(archives)} zip files; "
          f"{n_record} files in the record (Zenodo limit 100); {total / 1e9:.2f} GB "
          f"(Zenodo limit 50 GB).")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--data-root", type=Path, required=True)
    parser.add_argument("--raw-dir", type=Path, required=True)
    parser.add_argument("--processed-dir", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if not args.dry_run and args.out is None:
        parser.error("--out is required unless --dry-run is given")

    cases = read_case_table(CASE_TABLE)
    archives = plan(args, cases)
    if args.dry_run:
        summarize(archives)
        if not args.processed_dir:
            print("processed.zip not included (no --processed-dir).")
        return
    write_record(args, archives)
    summarize(archives, args.out)


if __name__ == "__main__":
    main()
