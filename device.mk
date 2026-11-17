#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_SOONG_NAMESPACES += device/infinix/X6525

$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION := true

PRODUCT_SHIPPING_API_LEVEL := 33

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_BUILD_CACHE_IMAGE := false

PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-impl.recovery

PRODUCT_PACKAGES += \
    checkpoint_gc \
    otapreopt_script \
    snapuserd \
    snapuserd.recovery \
    snapuserd.vendor_ramdisk \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=erofs \
    POSTINSTALL_OPTIONAL_system=true

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_vendor=true \
    POSTINSTALL_PATH_vendor=bin/checkpoint_gc \
    FILESYSTEM_TYPE_vendor=erofs \
    POSTINSTALL_OPTIONAL_vendor=true

PRODUCT_PACKAGES += \
    android.hardware.fastboot@1.1-impl-mock \
    fastbootd

PRODUCT_PACKAGES += \
    android.hardware.thermal@2.0-service.mock

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/fstab.X6525:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.X6525 \
    $(LOCAL_PATH)/rootdir/etc/modules.load:$(TARGET_COPY_OUT_RECOVERY)/root/lib/modules/modules.load \
    $(LOCAL_PATH)/rootdir/etc/init.recovery.X6525.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.X6525.rc \
    $(LOCAL_PATH)/rootdir/etc/ueventd.X6525.rc:$(TARGET_COPY_OUT_RECOVERY)/root/ueventd.X6525.rc \
    $(LOCAL_PATH)/rootdir/etc/ueventd.module.rc:$(TARGET_COPY_OUT_RECOVERY)/root/ueventd.module.rc \
    $(LOCAL_PATH)/rootdir/bin/load_modules.sh:$(TARGET_COPY_OUT_RECOVERY)/root/system/bin/load_modules.sh \
    $(LOCAL_PATH)/rootdir/etc/init.X6525.diag.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.X6525.diag.rc \
    $(LOCAL_PATH)/rootdir/bin/boottrace.sh:$(TARGET_COPY_OUT_VENDOR)/bin/boottrace.sh \
    $(LOCAL_PATH)/prebuilts/avb/q-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/q-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/r-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/r-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/s-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/avb/s-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/q-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/avb/q-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/r-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/avb/r-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/s-gsi.avbpubkey:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/avb/s-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/q-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/avb/q-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/r-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/avb/r-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/s-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/avb/s-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/q-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/avb/q-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/r-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/avb/r-gsi.avbpubkey \
    $(LOCAL_PATH)/prebuilts/avb/s-gsi.avbpubkey:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/avb/s-gsi.avbpubkey

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

PRODUCT_PACKAGES += \
    BluetoothOverlayX6525 \
    TetheringOverlayX6525 \
    WifiOverlayX6525

PRODUCT_PACKAGES += \
    android.hardware.cas@1.2-service-lazy \
    android.hardware.hardware_keystore.xml \
    android.hardware.wifi@1.0-service-lazy \
    libwifi-hal \
    vndservice \
    vndservicemanager

PRODUCT_CHARACTERISTICS := default

PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
PRODUCT_ENFORCE_VINTF_MANIFEST := false

$(call inherit-product, vendor/infinix/X6525/X6525-vendor.mk)

# Drop stock copies that collide with Soong install rules (ckati
# "overriding commands"). Keep Unisoc audio.primary.whale only.
PRODUCT_COPY_FILES := $(filter-out \
    %/dumpsys:% \
    %/android.hardware.audio% \
    %/audio.primary.default.so:% \
    %/audio.r_submix.default.so:% \
    %/audio.usb.default.so:%,$(PRODUCT_COPY_FILES))

PRODUCT_COPY_FILES := $(foreach pair,$(PRODUCT_COPY_FILES),\
    $(if $(findstring /vintf/,$(pair)),,$(pair)))
