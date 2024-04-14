#!/usr/bin/bash

xrandr --output "HDMI-1-0" --off
xrandr --output "HDMI-1-0" --auto
xrandr --output "HDMI-1-0" --right-of "eDP-1"
