#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/infinix/X6525

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    system \
    system_ext \
    vbmeta \
    vendor \
    vendor_boot \
    vendor_dlkm

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a75

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := cortex-a55

# Assert
TARGET_OTA_ASSERT_DEVICE := X6525,Infinix-X6525

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := ums9230
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 320
TARGET_SCREEN_HEIGHT := 1612
TARGET_SCREEN_WIDTH := 720

# Kernel
# Stock Infinix 5.4.210 kernel, kept as a prebuilt (no GPL source drop available).
# boot.img is a GKI style v4 image: the kernel lives in boot, the ramdisk and
# the DTB live in vendor_boot.
BOARD_BOOT_HEADER_VERSION := 4
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x05400000
BOARD_TAGS_OFFSET := 0x00000100
BOARD_DTB_OFFSET := 0x01f00000
BOARD_KERNEL_CMDLINE := console=ttyS1,115200n8
BOARD_KERNEL_IMAGE_NAME := Image

TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilts/kernel
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilts/dtb
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilts/dtbo.img

BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

# Kernel modules (prebuilt, must match the prebuilt kernel vermagic)
# The kernel is a prebuilt, so LineageOS' kernel build cannot compile or install
# modules. The stock modules are shipped as prebuilts instead.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(DEVICE_PATH)/prebuilts/modules/vendor_ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(shell cat $(DEVICE_PATH)/prebuilts/modules/vendor_ramdisk/modules.load)
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(shell cat $(DEVICE_PATH)/prebuilts/modules/vendor_ramdisk/modules.load.recovery)

# Modules installed in the vendor_dlkm partition by the build system
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(DEVICE_PATH)/prebuilts/modules/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(shell cat $(DEVICE_PATH)/prebuilts/modules/vendor_dlkm/modules.load)

# Keep the stock modules untouched
BOARD_DO_NOT_STRIP_VENDOR_MODULES := true
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true

# Recovery
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
BOARD_RAMDISK_USE_LZ4 := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.X6525
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 104857600

BOARD_SUPER_PARTITION_SIZE := 5242880000
BOARD_SUPER_PARTITION_GROUPS := group_unisoc
BOARD_GROUP_UNISOC_PARTITION_LIST := \
    odm \
    product \
    system \
    system_ext \
    vendor \
    vendor_dlkm
BOARD_GROUP_UNISOC_SIZE := 5238685696

BOARD_USES_METADATA_PARTITION := true

# File systems
# Stock ships all read-only partitions as EROFS; keep it so the images fit
# inside the 5.2 GB super partition.
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Platform
TARGET_BOARD_PLATFORM := ums9230

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_SYSTEM_DLKM_PROP += $(DEVICE_PATH)/system_dlkm.prop
TARGET_ODM_PROP += $(DEVICE_PATH)/odm.prop
TARGET_ODM_DLKM_PROP += $(DEVICE_PATH)/odm_dlkm.prop
TARGET_VENDOR_DLKM_PROP += $(DEVICE_PATH)/vendor_dlkm.prop

# Security patch level
VENDOR_SECURITY_PATCH := 2024-05-05

# Verified Boot
# The stock vbmeta images have verification disabled; do the same so the
# bootloader does not reject the self signed LineageOS images.
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_VENDOR_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_VENDOR_BOOT_ALGORITHM := SHA256_RSA4096
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX := 1
BOARD_AVB_VENDOR_BOOT_ROLLBACK_INDEX_LOCATION := 1

# VINTF
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Proprietary files
include vendor/infinix/X6525/BoardConfigVendor.mk
