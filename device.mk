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

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_VENDOR_RAMDISK_OUT)/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/ueventd.X6525.rc:$(TARGET_VENDOR_RAMDISK_OUT)/ueventd.X6525.rc

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
