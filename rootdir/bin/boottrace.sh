#!/vendor/bin/sh
# Temporary bring-up diagnostic tracer for Infinix X6525.
# Polls until /cache is mounted (or fallback-mounts /cache after 20s if mount_all stalled),
# then periodically flushes props, mounts, modules, ps, dmesg, and logcat to /cache.

PATH=/vendor/bin:/system/bin

echo "<0>X6525_TRACE: started" > /dev/kmsg

i=0
fallback_tried=0
while [ "$i" -lt 150 ]; do
    if [ $((i % 5)) -eq 0 ]; then
        echo "<0>X6525_TRACE: iter=$i" > /dev/kmsg
    fi

    if ! grep -q " /cache " /proc/mounts 2>/dev/null; then
        # Give init's on fs mount_all --early 20s before attempting fallback mount.
        if [ "$i" -ge 10 ] && [ "$fallback_tried" -eq 0 ] && [ -e /dev/block/by-name/cache ]; then
            fallback_tried=1
            err=$(mount -t f2fs -o discard /dev/block/by-name/cache /cache 2>&1)
            rc=$?
            echo "<0>X6525_TRACE: fallback_mount_cache rc=$rc $err" > /dev/kmsg
        fi
    fi

    if grep -q " /cache " /proc/mounts 2>/dev/null; then
        {
            echo "=== X6525 BOOTTRACE iter=$i uptime=$(cat /proc/uptime 2>/dev/null) ==="
            echo "--- PROPS (key) ---"
            getprop | grep -E "boot|usb|adb|selinux|modules|init\.svc\.|vold|apex|fs\.|crypto|slot"
            echo "--- MOUNTS ---"
            cat /proc/mounts 2>/dev/null
            echo "--- DEV WATCHDOG / UDC / USB GADGET ---"
            ls -la /dev/watchdog* /sys/class/udc /config/usb_gadget/g1 /config/usb_gadget/g1/functions /dev/usb-ffs/adb 2>&1
            echo "UDC_VAL=$(cat /config/usb_gadget/g1/UDC 2>&1)"
            echo "SELINUX=$(cat /sys/fs/selinux/enforce 2>&1)"
            echo "BY_NAME_COUNT=$(ls /dev/block/by-name 2>/dev/null | wc -l)"
            echo "--- LSMOD ---"
            lsmod 2>&1
            echo "--- PS ---"
            ps -A 2>&1
        } > /cache/boottrace.tmp 2>&1 && mv /cache/boottrace.tmp /cache/boottrace.txt

        dmesg > /cache/boot_dmesg.tmp 2>&1 && mv /cache/boot_dmesg.tmp /cache/boot_dmesg.txt
        if [ -S /dev/socket/logdr ] && [ -x /system/bin/logcat ]; then
            timeout 2 /system/bin/logcat -d -v threadtime > /cache/boot_logcat.tmp 2>&1 && mv /cache/boot_logcat.tmp /cache/boot_logcat.txt
        fi
        sync
    fi

    sleep 2
    i=$((i + 1))
done
