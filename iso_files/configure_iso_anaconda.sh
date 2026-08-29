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

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true

# Anaconda Profile Detection
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

# Add StartupWMClass so the running anaconda window inherits the icon
desktop-file-edit \
    --set-key=Icon --set-value=/usr/share/icons/hicolor/scalable/apps/dev.getaurora.installer.svg \
    --set-key=StartupWMClass --set-value=slitherer \
    /usr/share/applications/liveinst.desktop

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
systemctl stop var-lib-flatpak.mount
rsync -aAXUHKP /var/lib/flatpak "$target"
sync
%end
EOF

# Fetch the Secureboot Public Key
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'
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
