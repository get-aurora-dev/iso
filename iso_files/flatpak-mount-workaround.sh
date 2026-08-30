#!/usr/bin/env bash
set -eoux pipefail

# You will want to unmount /var/lib/flatpak before copying them to the installed system

# https://github.com/get-aurora-dev/iso/issues/72
cat > /usr/lib/systemd/system/var-lib-flatpak.mount <<'EOF'
[Unit]
Description=tmpfs so only aurora flatpaks are transferred to the installed system
Conflicts=umount.target

[Mount]
Type=overlay
What=overlay
Where=/var/lib/flatpak
Options=lowerdir=/var/lib/flatpak,upperdir=/run/overlay/flatpak,workdir=/run/overlay/flatpak.work
[Install]
WantedBy=local-fs.target
EOF

cat > /usr/lib/tmpfiles.d/aurora-iso-flatpak.conf <<'EOF'
d /run/overlay/flatpak 0755 - - -
d /run/overlay/flatpak.work 0755 - - -
EOF

systemctl enable var-lib-flatpak.mount
