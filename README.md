# LineageOS 20 device tree — Infinix SMART 8 (X6525)

Unisoc T616 (`ums9230` / `qogirl6`) device tree for LineageOS 20 (Android 13),
matching the stock Android 13 / VNDK 33 vendor image.

Generated with [aospdtgen](https://github.com/sebaubuntu-python/aospdtgen) from a
dump of the official firmware `X6525-TGo-OP-250919V1964` and then corrected by
hand (see *Post-generation fixes* below).

## Device specifications

| | |
|---|---|
| SoC | Unisoc T616 (`ums9230`, `qogirl6`) |
| CPU | 2 × Cortex-A75 + 6 × Cortex-A55 |
| GPU | Mali-G57 MC1 |
| RAM / storage | 4/6 GB / 64/128 GB |
| Display | 720 × 1612, 6.6" |
| Android | 13 (SDK 33), first API 33 |
| Treble | enabled, VNDK 33 |
| A/B | virtual A/B (`ro.virtual_ab.enabled=true`) |
| Dynamic partitions | yes (`super`, groups `group_unisoc_a` / `group_unisoc_b`) |
| Kernel | 5.4.210 (stock GKI v4 layout, prebuilt) |

## Building

```sh
source build/envsetup.sh
lunch lineage_X6525-userdebug
mka bacon
```

The stock kernel, DTB, DTBO and all kernel modules (vendor ramdisk and
`vendor_dlkm`) are shipped as prebuilts under `prebuilts/` because no GPL kernel
source drop is available for this device:

| Path | Installed to |
|---|---|
| `prebuilts/kernel` | `boot.img` (kernel only, generic ramdisk) |
| `prebuilts/dtb/dtb.dtb` | `vendor_boot.img` (`BOARD_PREBUILT_DTBIMAGE_DIR`) |
| `prebuilts/dtbo.img` | `dtbo.img` |
| `prebuilts/modules/vendor_ramdisk/*.ko` | vendor ramdisk (`BOARD_VENDOR_RAMDISK_KERNEL_MODULES`) |
| `prebuilts/modules/vendor_dlkm/*.ko` | `vendor_dlkm/lib/modules` (`BOARD_VENDOR_KERNEL_MODULES`) |

`init.insmod.sh`, `init.insmod.cfg` and `modules.load{,.cali,.charger}` are
copied into `vendor_dlkm/lib/modules` so the stock two-stage module loading
works unchanged (`/vendor/lib/modules` is a symlink to `/vendor_dlkm/lib/modules`
created by the build system).

## Extracting proprietary files

The blobs live in the separate
[`Classity-Real/vendor_infinix_X6525`](https://github.com/Classity-Real/vendor_infinix_X6525)
repository. To regenerate them from a dump of the stock firmware, use the
LineageOS 20 `tools/extract-utils` (the Python `extract-files.py` from aospdtgen
needs the newer `main`-branch extract-utils and does not work on `lineage-20.0`):

```sh
# from the root of the LineageOS 20 checkout
mkdir -p tools/extract-utils
git clone --depth=1 -b lineage-20.0 \
    https://github.com/LineageOS/android_tools_extract-utils.git tools/extract-utils

device/infinix/X6525/extract-files.sh /path/to/dump
```

`dump` must contain the extracted `system`, `system_ext`, `vendor`, `product`,
`odm` and `vendor_dlkm` partitions (as produced by an EROFS dump / a
`super.img` unpack). The script copies the blobs into
`vendor/infinix/X6525/proprietary` and regenerates `X6525-vendor.mk`,
`Android.bp` and `BoardConfigVendor.mk` through `setup-makefiles.sh`.

Only `vendor/`, `odm/` and `system_ext/` blobs are taken from stock; everything
else is built from source. Two large, non-essential stock items are dropped from
`proprietary-files.txt`: the 620 MB `vendor/app/Manual/Manual.apk` user manual and
the `libOpenCL.so*` symlink aliases (copying them dereferences ~325 MB of
duplicate `libGLES_mali_cl.so`), keeping the `vendor` image inside the 5.24 GB
`super` budget.

## Partition layout

Fixed sizes are taken from the stock `X6525.xml` (PAC partition table):

| Partition | Size |
|---|---|
| `boot` | 64 MB |
| `vendor_boot` | 100 MB |
| `dtbo` | 8 MB |
| `super` | 5,242,880,000 B (group `group_unisoc`: 5,238,685,696 B) |

The group size is declared the way AOSP 13 expects it
(`BOARD_SUPER_PARTITION_GROUPS` + `BOARD_<GROUP>_SIZE` /
`BOARD_<GROUP>_PARTITION_LIST`), so `build_super_image.py` appends the `_a`/`_b`
suffixes and produces the same `group_unisoc_a` / `group_unisoc_b` layout as
stock. All read-only partitions use EROFS so they fit.

## Boot flow

Stock uses a GKI v4 split:

* `boot.img` — prebuilt kernel, no DTB, no device cmdline, stock generic ramdisk
* `vendor_boot.img` — DTB, vendor ramdisk, recovery fragment
  (`TARGET_NO_RECOVERY := true`,
  `BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true`,
  `BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true`)

`BOARD_KERNEL_CMDLINE := console=ttyS1,115200n8` is written to the `vendor_boot`
cmdline (the build system appends `buildvariant=...`), matching stock.

## Post-generation fixes

`aospdtgen` output was corrected as follows:

* codename `Infinix-X6525` → `X6525` and path `device/infinix/X6525`
* `TARGET_BOOTLOADER_BOARD_NAME` → `ums9230`
* filled `AB_OTA_PARTITIONS` (was empty)
* `BOARD_SUPER_PARTITION_SIZE` 9126805504 → **5242880000** and the group/partition
  list replaced with the stock `group_unisoc` layout (was empty)
* GKI boot flow: `BOARD_USES_RECOVERY_AS_BOOT` removed (illegal with a generic
  kernel image), recovery moved to `vendor_boot`
* `TARGET_RECOVERY_FSTAB` → `rootdir/etc/fstab.X6525` (was `fstab.enableswap`)
* removed the bogus `TARGET_KERNEL_CONFIG` / `TARGET_KERNEL_SOURCE` entries and
  kept the prebuilt kernel
* restored the stock vendor ramdisk kernel modules and `modules.load[.recovery]`
* pruned the `rootdir` init files belonging to other Infinix/Unisoc models
* EROFS images for all read-only partitions, matching the stock layout
* all stock init scripts and VINTF fragments (`vendor`, `odm` and `system_ext`
  `etc/init` and `etc/vintf/manifest`) are extracted with an `infinix-` prefix
  (a `src:dst` rename in `proprietary-files.txt`); the stock face fragment is
  extracted as `vendor.sprd.hardware.biometrics.face.xml` instead. Soong
  generates an install rule for the VINTF fragment and init script of every
  module that declares one, even when the module is not in `PRODUCT_PACKAGES`,
  so identically named stock files (e.g. `face-default.xml`, `face-default.rc`,
  `android.hardware.wifi@1.0-service.xml`, `power.stats-default.xml`) would
  otherwise create duplicate make targets and abort the build
* stock copies of files that AOSP builds and installs into the vendor image are
  not shipped at all: the boringssl self tests, `dumpsys`, `mkshrc`, the
  `rkp_factory_extraction_tool`, the AOSP HAL services (`android.hardware.
  audio.service`, `camera.provider@2.4-service`, `graphics.composer@2.4-service`,
  `sensors-service.multihal`, the health/usb/power.stats examples, ...) and their
  impl/helper libraries (`audio.primary.default.so`, `libvpx.so`,
  `libstagefright_*`, ...). Soong installs those exact paths, so the stock
  `PRODUCT_COPY_FILES` rules collided with the source-built install rules. Only
  the Unisoc-specific blobs are kept
* `BUILD_BROKEN_DUP_RULES := true`: the stock vendor image also duplicates paths
  installed by Android.mk based modules (the vendor HIDL/AIDL HAL services such
  as `android.hardware.wifi@1.0-service-lazy`). With this flag kati warns and
  keeps the last definition, i.e. the stock file, instead of aborting
* `--flags 3` on vbmeta, matching the stock "verification disabled" setup
