#!/usr/bin/env python3
"""Patch /chosen/bootargs in the prebuilt Unisoc DTB container.

The Unisoc LK bootloader on the X6525 takes the kernel command line from
/chosen/bootargs of the DTB that is loaded from vendor_boot.img (the DTB in
_prebuilts/dtb/dtb.dtb_). It ignores the `cmdline` field of boot.img, so
BOARD_KERNEL_CMDLINE never reaches the kernel. Options that have to be seen by
the kernel -- most importantly androidboot.selinux=permissive during bring-up --
therefore have to be added to this DTB before the build.

The prebuilt file is a Unisoc/DTBO style container (magic 0xd7b7ab1e) holding
one flattened device tree. The tree itself is edited with dtc; a decompile /
recompile round trip of the unmodified tree is byte identical with dtc 1.7, so
only the bootargs property changes.

Usage (from the Lineage tree, before `mka`):

    python3 device/infinix/X6525/tools/dtb_bootargs.py \
        device/infinix/X6525/prebuilts/dtb/dtb.dtb \
        --add androidboot.selinux=permissive

Pass --check to only print the current bootargs. The operation is idempotent:
an option that is already present is not added twice.
"""

import argparse
import hashlib
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

CONTAINER_MAGIC = 0xD7B7AB1E
HEADER_SIZE = 32
ENTRY_SIZE = 32
PAGE_SIZE = 2048


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def parse_container(path):
    data = path.read_bytes()
    if len(data) < HEADER_SIZE:
        die(f"{path} is too short to be a DTB container")
    magic, total, hsize, esize, ecount, eoff, psize, version = struct.unpack(
        ">8I", data[:HEADER_SIZE]
    )
    if magic != CONTAINER_MAGIC:
        die(f"{path}: bad magic {magic:#010x}, expected {CONTAINER_MAGIC:#010x}")
    if hsize != HEADER_SIZE or esize != ENTRY_SIZE:
        die(f"{path}: unexpected header/entry size {hsize}/{esize}")
    entries = []
    for i in range(ecount):
        off = eoff + i * esize
        if off + esize > len(data):
            die(f"{path}: entry {i} lies outside the file")
        size, doff, ident, rev = struct.unpack_from(">4I", data, off)
        if doff + size > len(data):
            die(f"{path}: entry {i} payload lies outside the file")
        entries.append({"size": size, "offset": doff, "id": ident, "rev": rev})
    return data, entries


def build_container(blobs, metas, version=0):
    ecount = len(blobs)
    if ecount != len(metas):
        die("internal error: blob/metadata count mismatch")
    table_offset = HEADER_SIZE
    data_offset = table_offset + ecount * ENTRY_SIZE

    table = bytearray()
    body = bytearray()
    for blob, meta in zip(blobs, metas):
        offset = data_offset + len(body)
        entry = struct.pack(">4I", len(blob), offset, meta["id"], meta["rev"])
        table += entry.ljust(ENTRY_SIZE, b"\0")
        body += blob

    total = data_offset + len(body)
    header = struct.pack(
        ">8I", CONTAINER_MAGIC, total, HEADER_SIZE, ENTRY_SIZE, ecount,
        table_offset, PAGE_SIZE, version,
    )
    return bytes(header) + bytes(table) + bytes(body)


def run(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        die(f"{' '.join(map(str, cmd))} failed:\n{result.stderr.strip()}")
    return result


def decompile(dtb, dts):
    run(["dtc", "-I", "dtb", "-O", "dts", "-o", str(dts), str(dtb)])
    return dts.read_text()


def compile_(dts, dtb):
    # -f: force even though the source may trigger unit-address warnings, which
    # are expected for the vendor trees Unisoc ships.
    run(["dtc", "-f", "-I", "dts", "-O", "dtb", "-o", str(dtb), str(dts)])


def get_bootargs(dtb):
    with tempfile.TemporaryDirectory() as tmp:
        dts = Path(tmp) / "check.dts"
        return find_bootargs(decompile(dtb, dts))


def find_bootargs(dts):
    for line in dts.splitlines():
        stripped = line.strip()
        if stripped.startswith("bootargs") and "=" in stripped:
            value = stripped.split("=", 1)[1].strip().rstrip(";").strip()
            if value.startswith('"') and value.endswith('"'):
                return value[1:-1]
    die("no /chosen/bootargs property found in the DTB")


def set_bootargs(dts, bootargs):
    out = []
    replaced = False
    for line in dts.splitlines(keepends=True):
        stripped = line.strip()
        if not replaced and stripped.startswith("bootargs") and "=" in stripped:
            indent = line[: len(line) - len(line.lstrip())]
            out.append(f'{indent}bootargs = "{bootargs}";\n')
            replaced = True
        else:
            out.append(line)
    if not replaced:
        die("no /chosen/bootargs property found in the DTB")
    return "".join(out)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("container", type=Path, help="DTB container to patch in place")
    parser.add_argument("--add", action="append", default=[], metavar="OPTION",
                        help="command line option to append (may be repeated)")
    parser.add_argument("--drop", action="append", default=[], metavar="OPTION",
                        help="command line option to remove (may be repeated)")
    parser.add_argument("--check", action="store_true",
                        help="only print the current bootargs and exit")
    parser.add_argument("--backup", action="store_true",
                        help="keep a .orig copy of the container")
    args = parser.parse_args()

    container = args.container
    if not container.is_file():
        die(f"{container} does not exist")
    data, entries = parse_container(container)
    if len(entries) != 1:
        die(f"expected exactly one device tree in {container}, found {len(entries)}")

    blobs = [data[e["offset"] : e["offset"] + e["size"]] for e in entries]
    metas = [{"id": e["id"], "rev": e["rev"]} for e in entries]

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        dtb = tmp / "inner.dtb"
        dts = tmp / "inner.dts"
        new_dtb = tmp / "inner.new.dtb"
        dtb.write_bytes(blobs[0])

        tree = decompile(dtb, dts)
        bootargs = find_bootargs(tree)
        print(f"current bootargs: {bootargs}")
        if args.check:
            return

        options = bootargs.split()
        changed = False
        for option in args.drop:
            key = option.split("=", 1)[0]
            kept = [o for o in options if o.split("=", 1)[0] != key]
            if len(kept) != len(options):
                options = kept
                changed = True
        for option in args.add:
            key = option.split("=", 1)[0]
            if any(o.split("=", 1)[0] == key for o in options):
                print(f"keeping existing {key} option")
                options = [o for o in options if o.split("=", 1)[0] != key]
            options.append(option)
            changed = True

        if not changed:
            print("nothing to do")
            return

        new_bootargs = " ".join(options)
        dts.write_text(set_bootargs(tree, new_bootargs))
        compile_(dts, new_dtb)
        new_blob = new_dtb.read_bytes()

        # Sanity check: the patched tree must decompile and expose the new value.
        check_dtb = tmp / "check.dtb"
        check_dtb.write_bytes(new_blob)
        if get_bootargs(check_dtb) != new_bootargs:
            die("patched DTB does not report the expected bootargs")

        rebuilt = build_container([new_blob] + blobs[1:], metas)
        if args.backup:
            shutil.copyfile(container, container.with_suffix(container.suffix + ".orig"))
        container.write_bytes(rebuilt)

    print(f"new bootargs:     {new_bootargs}")
    print(f"dtb: {len(blobs[0])} -> {len(new_blob)} bytes, "
          f"container: {len(data)} -> {len(rebuilt)} bytes")
    print(f"sha256: {hashlib.sha256(rebuilt).hexdigest()}")


if __name__ == "__main__":
    main()
