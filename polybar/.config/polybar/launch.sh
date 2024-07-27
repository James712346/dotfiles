#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
polybar-msg cmd quit
killall -q polybar

# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch bar1 and bar2
echo "---" | tee -a /tmp/polybar1.log /tmp/polybar2.log
echo "Starting $1"

# Using autorandr to check for the current monitor setup
# Command to extract the current setup: autorandr --detected
setup=$(autorandr --detected | head -n 1)
echo "Current setup: $setup"
# If the current setup is "homeSetup-usb-1", then use the "superwide" bar
if [ "$setup" = "homeSetup-usb-0" ]; then
    echo "Using superwide bar"
    MONITOR=DP-1-2
    polybar superwide 2>&1 | tee -a /tmp/polybar1.log & disown
elif [ "$setup" = "homeSetup-usb-1" ]; then
    echo "Using superwide bar"
    MONITOR=DP-1-0
    polybar superwide 2>&1 | tee -a /tmp/polybar1.log & disown
elif [ "$setup" = "mobile" ]; then
    echo "Using laptop bar"
    polybar laptop 2>&1 | tee -a /tmp/polybar1.log & disown
elif [ "$setup" = "workSetup" ]; then
    echo "Using WorkSetup"
    MONITORL="DP-1-2.1"
    MONITORR="DP-1-2.2"
    polybar dualmonitorL 2>&1 | tee -a /tmp/polybar1.log & disown
    polybar dualmonitorR 2>&1 | tee -a /tmp/polybar2.log & disown
else
    echo "error finding setup, using laptop bar"
    polybar laptop 2>&1 | tee -a /tmp/polybar1.log & disown
fi

echo "Bars launched..."
