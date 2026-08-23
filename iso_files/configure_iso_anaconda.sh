#!/usr/bin/env bash

set -eoux pipefail

if [[ -n "${BASE_IMAGE:-}" ]]; then
    IMAGE_REF="${BASE_IMAGE%%:*}"
    IMAGE_TAG="${BASE_IMAGE##*:}"
else
    IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
    IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
    IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
    IMAGE_REF="${IMAGE_REF##*://}"
fi
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

# Configure Live Environment
glib-compile-schemas /usr/share/glib-2.0/schemas

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

# https://github.com/ublue-os/aurora/issues/2624
# https://github.com/get-aurora-dev/common/pull/249
# https://bugs.kde.org/show_bug.cgi?id=523540
# so plasma-welcome doesn't crash with `--live-environment`
rm /usr/share/plasma/plasma-welcome/intro-customization.desktop

systemctl --global disable bazaar.service

# Anaconda Profile Detection

# Aurora
mkdir -p /etc/anaconda/profile.d
tee /etc/anaconda/profile.d/aurora.conf <<'EOF'
# Anaconda configuration file for Aurora

[Profile]
# Define the profile.
profile_id = aurora

[Profile Detection]
# Match os-release values
os_id = aurora

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
webui_web_engine = slitherer
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
hidden_webui_pages =
    root-password
    network
    anaconda-screen-accounts
EOF

# add installer to kickoff
sed -i '2s/$/;liveinst.desktop/' /usr/share/kde-settings/kde-profile/default/xdg/kicker-extra-favoritesrc

# Configure
. /etc/os-release
echo "Aurora release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true

# Add StartupWMClass so the running window inherits the icon
desktop-file-edit \
    --set-key=Icon --set-value=/usr/share/icons/hicolor/scalable/apps/dev.getaurora.installer.svg \
    --set-key=StartupWMClass --set-value=slitherer \
    /usr/share/applications/liveinst.desktop

git clone https://github.com/get-aurora-dev/branding /tmp/branding
cp -r /tmp/branding/iso_files/usr/* /usr/
rm -rf /tmp/branding

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

tee -a /etc/xdg/kwalletrc <<EOF
[Wallet]
Enabled=false
EOF

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
umount -l /var/lib/flatpak
rsync -aAXUHKP /var/lib/flatpak "$target"
sync
%end
EOF

# cleanup our leftovers
rm -rf /flatpak-list

# Fetch the Secureboot Public Key
curl --retry 15 -Lo /etc/sb_pubkey.der "$sbkey"

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
    echo "Steam Deck hardware detected. Skipping key enrollment."
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF
