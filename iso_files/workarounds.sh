#!/usr/bin/env bash
set -eoux pipefail

# just to be sure, we already remove this in the image
rm -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service

. /etc/os-release
echo "Aurora release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

cat > /usr/bin/plasma-welcome <<'EOF'
#!/usr/bin/env bash

# https://github.com/ublue-os/aurora/issues/2624
# https://bugs.kde.org/show_bug.cgi?id=523540
# real nasty, this is the same ordering as without --pages and with --live-environment
exec /usr/bin/plasma-welcome-original --pages Live,Welcome,SimpleByDefault,PowerfulWhenNeeded,Enjoy "$@"
EOF

# https://github.com/ublue-os/aurora/issues/2624
# https://github.com/get-aurora-dev/common/pull/249
# https://bugs.kde.org/show_bug.cgi?id=523540
# so plasma-welcome doesn't crash with `--live-environment`
rm /usr/share/plasma/plasma-welcome/intro-customization.desktop
