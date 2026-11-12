#!/vendor/bin/sh
# SPDX-FileCopyrightText: 2016-2023 Unisoc (Shanghai) Technologies Co., Ltd
# SPDX-License-Identifier: LicenseRef-Unisoc-General-1.0

while :
do
        time=`uptime | awk '{print $3}'`
        if [ $time -lt 4 ]; then
                sleep 10
        else
                setprop vendor.zram.limit yes
                sleep 2
                setprop vendor.zram.writeback idle
                sleep 2
                setprop vendor.zram.writeback idle_fast
                break
        fi
done
