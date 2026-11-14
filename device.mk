#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# A/B
#
# launch_with_vendor_ramdisk is the variants that install the first-stage
# toolset into the *vendor* ramdisk: linker.vendor_ramdisk, e2fsck.vendor_ramdisk,
# fsck.f2fs.vendor_ramdisk, resize2fs.vendor_ramdisk and tune2fs.vendor_ramdisk.
# They land in /first_stage_ramdisk/system/{bin,lib64}, which is the root
# first-stage init chroots into (SwitchRoot), so they are the only dynamically
# linked binaries that can run after the switch. The plain virtual_ab_ota.mk
# installs the same tools into the boot ramdisk instead, where first-stage init
# never looks for them.
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# The stock vendor.prop enables Virtual A/B compression, and the tree ships
# snapuserd.vendor_ramdisk, so advertise it in the OTA metadata as well. Without
# this, misc_info.txt says virtual_ab_compression=false while the device expects
# compressed COW ops for the next OTA.
PRODUCT_VIRTUAL_AB_COMPRESSION := true

# Userspace snapshots
#
# The stock vendor.prop sets ro.virtual_ab.compression.enabled=true and
# ro.virtual_ab.userspace.snapshots.enabled=true (and io_uring off, which is why
# virtual_ab_ota/compression.mk is not inherited: it would turn io_uring on).
# With userspace snapshots the first boot after an OTA maps the dynamic
# partitions through dm-user, and first-stage init execs snapuserd from the
# ramdisk to serve those devices. virtual_ab_ota/compression.mk is what
# installs that binary into the vendor ramdisk (snapuserd.vendor_ramdisk);
# without it first-stage init cannot mount /system on the freshly updated slot.
PRODUCT_PACKAGES += \
    snapuserd.vendor_ramdisk

# The stock vendor.sprd.hardware.boot@1.2-service also registers the standard
# android.hardware.boot@1.2::IBootControl/default instance, so the AOSP boot
# HAL (whose VINTF fragment duplicates the stock device manifest entry) is not
# built.
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script

# API levels
PRODUCT_SHIPPING_API_LEVEL := 33

# fastbootd
PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

# Health
# The stock vendor android.hardware.health AIDL service
# (android.hardware.health-service.example) is the device health HAL; the AOSP
# HIDL 2.1 reference service is not installed.

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

# Partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Product characteristics
PRODUCT_CHARACTERISTICS := default

# Rootdir
PRODUCT_PACKAGES += \
    log_to_csv.sh \
    loading.sh \
    para.sh \
    total.sh \
    create_splloader_dual_slot_byname_path.sh \
    idlefast.sh \
    init.insmod.sh \
    zramwb.sh

PRODUCT_PACKAGES += \
    init.X6525.rc \
    init.X6525.usb.rc \
    init.ram.rc \
    init.ram.gms.rc \
    init.ram.native.rc \
    init.storage.rc \
    init.cali.rc \
    init.zramwb.rc

# Every board/project name the stock vendor_boot ramdisk ships an
# fstab/ueventd/init script for. The bootloader picks one of them at runtime as
# ro.boot.hardware and neither that value nor the bootloader's own logic can be
# read back from the images, so every first-stage file is installed under all of
# them, exactly like the stock vendor ramdisk does.
#
# This is what makes first-stage init find a fstab at all: fs_mgr resolves it as
# /fstab.${ro.boot.hardware} (or ${androidboot.fstab_suffix}), and if no file
# matches, first-stage mount fails and init panics before the boot animation.
# The path is captured with := because the prepare recipe below is expanded at
# execution time, when LOCAL_PATH points at whatever makefile was parsed last.
RECOVERY_USB_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
RECOVERY_INIT_RC_NAMES := \
    X6525 X6528 X6528B \
    A666L A666LN \
    BG6 BG6h BG6i BG6n BG6s \
    P663L P663LN P683L \
    S662LT S662LTGO S681LN \
    ums9230 ums9230_1h10 ums9230_1h10_go \
    ums9230_4h10 ums9230_4h10_go \
    ums9230_6h10 ums9230_7h10 ums9230_haps ums9230_zebu \
    qogirl6 unknown

# Destinations are relative to $(PRODUCT_OUT), so use the TARGET_COPY_OUT_*
# names rather than the absolute TARGET_*_OUT staging directories: absolute
# destinations get mangled by append-path() and are silently never built.
PRODUCT_COPY_FILES += $(foreach name,$(RECOVERY_INIT_RC_NAMES), \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.$(name))
PRODUCT_COPY_FILES += $(foreach name,$(RECOVERY_INIT_RC_NAMES), \
    $(LOCAL_PATH)/rootdir/etc/ueventd.X6525.rc:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/ueventd.$(name).rc)

# The recovery fragment boots on its own, so it needs the same first-stage
# fstab and the full module load list at the paths recovery's init reads:
# /first_stage_ramdisk/fstab.${ro.hardware} for fs_mgr and /lib/modules for the
# storage drivers that BOARD_RECOVERY_KERNEL_MODULES installs.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/prebuilts/modules/vendor_ramdisk/modules.load:$(TARGET_COPY_OUT_RECOVERY)/root/lib/modules/modules.load

# Recovery init script: switches recovery to the configfs USB gadget, see the
# file for why. It has to live at the root of the recovery ramdisk, where
# bootable/recovery's init.rc imports it through
# "import /init.recovery.${ro.hardware}.rc".
#
# build/make/core/Makefile copies $(TARGET_ROOT_OUT)/init.recovery.*.rc into the
# recovery ramdisk root, so the ramdisk root (TARGET_COPY_OUT_ROOT) is the
# install location. ro.hardware is supplied by the bootloader and cannot be read
# back on this device without a working USB connection, so the script is
# installed under every board/project name the stock firmware ships an
# init/ueventd script for (X6525 or one of the Unisoc ums9230 board names);
# recovery only imports the matching one.
$(foreach name,$(RECOVERY_INIT_RC_NAMES), \
    $(eval PRODUCT_COPY_FILES += $(LOCAL_PATH)/rootdir/etc/init.recovery.X6525.rc:$(TARGET_COPY_OUT_ROOT)/init.recovery.$(name).rc))

# PRODUCT_COPY_FILES targets are not part of ALL_DEFAULT_INSTALLED_MODULES, so
# INTERNAL_ROOT_FILES does not list them and the recovery ramdisk recipe (which
# rsyncs $(TARGET_ROOT_OUT) and then globs $(TARGET_ROOT_OUT)/init.recovery.*.rc)
# has no dependency on them: ninja may run the copy before or after that recipe.
# Install the USB init scripts and the diagnostics script a second time, as the
# last step of the recovery image recipe. The vendor ramdisk build depends on
# that recipe, so the files are guaranteed to be in $(TARGET_RECOVERY_ROOT_OUT)
# before mkbootfs runs.
BOARD_RECOVERY_IMAGE_PREPARE = \
    mkdir -p $(TARGET_RECOVERY_ROOT_OUT)/system/etc; \
    $(foreach name,$(RECOVERY_INIT_RC_NAMES),cp -f $(RECOVERY_USB_DIR)/rootdir/etc/init.recovery.X6525.rc $(TARGET_RECOVERY_ROOT_OUT)/init.recovery.$(name).rc;) \
    cp -f $(RECOVERY_USB_DIR)/rootdir/etc/usbdebug.sh $(TARGET_RECOVERY_ROOT_OUT)/system/etc/usbdebug.sh; \
    chmod 0755 $(TARGET_RECOVERY_ROOT_OUT)/system/etc/usbdebug.sh

# Kernel module helpers read by init.insmod.sh from /vendor/lib/modules
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilts/modules/vendor_dlkm/init.insmod.cfg:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/init.insmod.cfg \
    $(LOCAL_PATH)/prebuilts/modules/vendor_dlkm/modules.load.cali:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/modules.load.cali \
    $(LOCAL_PATH)/prebuilts/modules/vendor_dlkm/modules.load.charger:$(TARGET_COPY_OUT_VENDOR_DLKM)/lib/modules/modules.load.charger

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Proprietary files
$(call inherit-product, vendor/infinix/X6525/X6525-vendor.mk)
