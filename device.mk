#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota.mk)

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

# Destinations are relative to $(PRODUCT_OUT), so use the TARGET_COPY_OUT_*
# names rather than the absolute TARGET_*_OUT staging directories: absolute
# destinations get mangled by append-path() and are silently never built.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/ueventd.X6525.rc:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/ueventd.X6525.rc

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
RECOVERY_INIT_RC_NAMES := \
    X6525 \
    ums9230 ums9230_1h10 ums9230_1h10_go \
    ums9230_4h10 ums9230_4h10_go \
    ums9230_6h10 ums9230_7h10 ums9230_haps ums9230_zebu \
    qogirl6 unknown
$(foreach name,$(RECOVERY_INIT_RC_NAMES), \
    $(eval PRODUCT_COPY_FILES += $(LOCAL_PATH)/rootdir/etc/init.recovery.X6525.rc:$(TARGET_COPY_OUT_ROOT)/init.recovery.$(name).rc))

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
