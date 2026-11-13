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

# The stock vendor image already provides the HAL services below, so never
# build the AOSP counterparts: their init scripts or VINTF fragments would
# either duplicate a stock service name or declare the same HAL twice (which
# libvintf rejects with "HAL ... has a conflict").
#
#  - android.hardware.biometrics.face-service.example: the stock
#    vendor.sprd.hardware.biometrics.face-service provides IFace/default.
#  - android.hardware.cas@1.2-service: stock android.hardware.cas@1.2-service-lazy
#  - android.hardware.media.omx@1.0-service: stock media.omx service
#  - rild: stock Unisoc vendor.ril-daemon (urild)
#  - boringssl_self_test(_vendor): stock vendor self-test binaries and script
PRODUCT_PACKAGES := $(filter-out \
    android.hardware.biometrics.face-service.example \
    android.hardware.cas@1.2-service \
    android.hardware.media.omx@1.0-service \
    boringssl_self_test \
    boringssl_self_test_vendor \
    rild, \
    $(PRODUCT_PACKAGES))


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
