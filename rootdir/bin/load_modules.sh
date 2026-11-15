#!/system/bin/sh
# Ensure touch/gesture modules are loaded and wait for async touch input
# registration (e.g. TD4160 zeroflash firmware download) before recovery UI
# enumerates /dev/input/event* once at startup.

load_if_missing()
{
    modname="$1"
    modpath="$2"
    if [ ! -d "/sys/module/$modname" ] && [ -r "$modpath" ]; then
        insmod "$modpath" 2>/dev/null || true
    fi
}

load_panel()
{
    load_if_missing gpio /vendor/lib/modules/gpio.ko
    load_if_missing adaptive_ts /vendor/lib/modules/adaptive-ts.ko
    load_if_missing focaltech_ft8722 /vendor/lib/modules/focaltech_ft8722.ko
    load_if_missing omnivision_td4160 /vendor/lib/modules/omnivision_td4160.ko
    load_if_missing focaltech_ft8756_spi_ts /vendor/lib/modules/focaltech_ft8756_spi_ts.ko
    load_if_missing nvt_nt36xxx_spi_ts /vendor/lib/modules/nvt_nt36xxx_spi_ts.ko
    load_if_missing tran_gesture /vendor/lib/modules/tran_gesture.ko
}

has_touch_input()
{
    for ev in /sys/class/input/event*; do
        [ -r "$ev/device/capabilities/abs" ] || continue
        read -r abs < "$ev/device/capabilities/abs" 2>/dev/null || continue
        case "$abs" in
            *[1-9a-fA-F]*)
                devnode="/dev/input/${ev##*/}"
                if [ -c "$devnode" ]; then
                    return 0
                fi
                ;;
        esac
    done
    return 1
}

load_panel

i=0
while [ "$i" -lt 50 ]; do
    if has_touch_input; then
        break
    fi
    /system/bin/usleep 100000 2>/dev/null || sleep 1
    i=$((i + 1))
done

setprop modules.loaded 1
exit 0
