#!/usr/bin/env bash
set -eoux pipefail

# Things we always have to undo

systemctl disable tailscaled.service
systemctl disable brew-upgrade.timer
systemctl disable brew-update.timer
systemctl disable brew-setup.service
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl disable flatpak-preinstall.service
systemctl --global disable podman-auto-update.timer
systemctl --global disable ublue-user-setup.service

rm /usr/share/applications/dev.getaurora.system-update.desktop
