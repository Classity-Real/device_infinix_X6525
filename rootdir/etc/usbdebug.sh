#!/system/bin/sh
#
# Recovery USB diagnostics.
#
# Runs as a oneshot service from init.recovery.<name>.rc. It exists because a
# recovery whose adb and fastbootd both stay completely silent gives no way to
# see what init did: there is no console, no network and no USB. The script
# therefore writes a short summary to the kernel log - the ramoops console
# buffer keeps the last ~32 KB of it across a reboot, and TWRP can read it as
# /sys/fs/pstore/console-ramoops-0 - and the full dump to /cache/usbdebug.log.
#
# The script only reads state. It cannot change the USB setup, and every step
# is allowed to fail without aborting the rest.

TAG=usbdebug

kmsg() {
    echo "$TAG: $*" > /dev/kmsg 2>/dev/null
}

dump() {
    echo
    echo "########## $1 ##########"
    date 2>/dev/null

    echo "--- /proc/cmdline"
    cat /proc/cmdline 2>&1
    echo "--- bootconfig"
    cat /proc/bootconfig 2>&1

    echo "--- properties"
    getprop 2>/dev/null | grep -e '^\[ro\.hardware\]' \
        -e '^\[ro\.boot\.' \
        -e '^\[ro\.serialno\]' \
        -e '^\[ro\.product\.' \
        -e '^\[ro\.debuggable\]' \
        -e '^\[ro\.adb\.' \
        -e '^\[ro\.recovery\.' \
        -e '^\[sys\.usb\.' \
        -e '^\[service\.adb\.'

    echo "--- files init imports (ro.hardware selects one)"
    ls -l /init.recovery.*.rc 2>&1

    echo "--- UDC"
    ls -l /sys/class/udc 2>&1
    for f in /sys/class/udc/*/state; do
        [ -e "$f" ] && echo "$f: $(cat "$f" 2>&1)"
    done

    echo "--- configfs mounts"
    grep -e configfs -e functionfs /proc/mounts 2>&1

    echo "--- gadget tree"
    find /config/usb_gadget -maxdepth 4 2>&1

    echo "--- gadget values"
    for f in idVendor idProduct bcdUSB UDC \
             functions/ffs.adb functions/ffs.fastboot \
             configs/b.1/MaxPower configs/b.1/strings/0x409/configuration; do
        printf '/config/usb_gadget/g1/%s: ' "$f"
        cat "/config/usb_gadget/g1/$f" 2>&1
    done

    echo "--- functionfs instances"
    ls -la /dev/usb-ffs /dev/usb-ffs/adb /dev/usb-ffs/fastboot 2>&1

    echo "--- processes"
    ps -A 2>/dev/null || ps 2>&1

    echo "--- kernel USB log (tail)"
    dmesg 2>/dev/null | grep -i -e usb -e musb -e gadget -e 'ffs' -e 'ep0' \
        | tail -n 60
}

boot_summary() {
    kmsg "ro.hardware=$(getprop ro.hardware) ro.boot.hardware=$(getprop ro.boot.hardware)"
    kmsg "sys.usb.configfs=$(getprop sys.usb.configfs) sys.usb.controller=$(getprop sys.usb.controller) sys.usb.state=$(getprop sys.usb.state)"
    kmsg "udc=[$(ls /sys/class/udc 2>/dev/null | tr '\n' ' ')] gadget=[$(ls /config/usb_gadget 2>/dev/null | tr '\n' ' ')] functions=[$(ls /config/usb_gadget/g1/functions 2>/dev/null | tr '\n' ' ')] UDC=[$(cat /config/usb_gadget/g1/UDC 2>/dev/null)]"
    kmsg "adb_ep0=$(ls /dev/usb-ffs/adb/ep0 2>/dev/null) fastboot_ep0=$(ls /dev/usb-ffs/fastboot/ep0 2>/dev/null) adbd=[$(pidof adbd 2>/dev/null)]"
    kmsg "init.recovery.rc=[$(ls /init.recovery.*.rc 2>/dev/null | tr '\n' ' ')]"
}

save_to_cache() {
    # Recovery does not mount /cache unless it needs to, so do it here. Read
    # the log back with: adb shell cat /cache/usbdebug.log   (TWRP)
    if ! grep -q ' /cache ' /proc/mounts 2>/dev/null; then
        mkdir -p /cache 2>/dev/null
        mount -t f2fs -o rw /dev/block/by-name/cache /cache 2>/dev/null \
            || mount -t ext4 -o rw /dev/block/by-name/cache /cache 2>/dev/null
    fi
    if grep -q ' /cache ' /proc/mounts 2>/dev/null; then
        cp -f /tmp/usbdebug.log /cache/usbdebug.log 2>/dev/null && sync
        kmsg "full log written to /cache/usbdebug.log"
    else
        kmsg "/cache could not be mounted, only the summary is in kmsg"
    fi
}

# Wait for the boot to settle: adbd is started by "class_start default" in
# "on boot", and the configfs UDC write happens once adbd has opened ep0.
sleep 15
dump "after 15s" > /tmp/usbdebug.log 2>&1
boot_summary
save_to_cache

# Second look, once the USB enumeration either happened or definitely did not.
sleep 30
dump "after 45s" >> /tmp/usbdebug.log 2>&1
boot_summary
save_to_cache

exit 0
