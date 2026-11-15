#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# GSI AVB keys: the stock vendor_boot ramdisk carries
# /avb/{q,r,s}-gsi.avbpubkey, so as long as you keep the stock vendor_boot
# (bring-up path A in docs/BRINGUP.md) nothing needs to be installed here.
# There is no gsi_keys.mk in lineage-20.0; the closest thing is
# $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk, which installs the
# *developer* GSI keys under different file names. Only inherit it if you
# actually intend to boot a developer GSI with verified boot.

# Inherit from the Infinix X6525 device tree.
$(call inherit-product, device/infinix/X6525/device.mk)

# Temporary bring-up debug: disable ADB RSA auth so early ADB works unattended.
WITH_ADB_INSECURE := true

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_DEVICE := X6525
PRODUCT_NAME := lineage_X6525
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6525
PRODUCT_MANUFACTURER := Infinix

PRODUCT_GMS_CLIENTID_BASE := android-transsion

# Keep the stock build fingerprint so Play/device certification sees the
# device it expects. Replace both values with the ones your dump reports:
#
#     python3 tools/collect-props.py <dump> | grep -E 'ro.build.(fingerprint|description)'
#
# The values below are from the port ROM used as a reference.
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="X6525-user 13 TP1A.220624.014 250909V212 release-keys" \
    BUILD_FINGERPRINT="Infinix/X6525-OPPJ/Infinix-X6525:13/TP1A.220624.014/250909V212:user/release-keys"
