#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from X6525 device
$(call inherit-product, device/infinix/X6525/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# The stock vendor image is the source of truth for the shared HAL services.
# Packages cannot be removed from PRODUCT_PACKAGES here: product inheritance is
# resolved after this file is parsed, so $(filter-out ...) only sees the
# @inherit tags, not the packages added by the inherited makefiles. Instead the
# stock init scripts are shipped at the same paths as the AOSP ones (see
# proprietary-files.txt), so the stock PRODUCT_COPY_FILES rule overrides the
# source-built install rule (BUILD_BROKEN_DUP_RULES). This covers the cas,
# media.omx, rild and boringssl services. The stock cas VINTF fragment is not
# shipped at all: AOSP's identical fragment is the single declaration.



PRODUCT_DEVICE := X6525
PRODUCT_NAME := lineage_X6525
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix X6525
PRODUCT_MANUFACTURER := Infinix

PRODUCT_GMS_CLIENTID_BASE := android-transsion

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="X6525-user 13 TP1A.220624.014 665 release-keys" \
    BuildFingerprint=Infinix/X6525-OP/X6525:13/TP1A.220624.014/250919V1964:user/release-keys

PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
    ro.sf.lcd_density=320
