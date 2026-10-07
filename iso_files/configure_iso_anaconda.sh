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

# we should mostly use the same values as fedora-kde
[User Interface]
webui_web_engine = slitherer
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
hidden_webui_pages =
    anaconda-screen-date-time
    anaconda-netowrk
    anaconda-screen-accounts
EOF

# Add StartupWMClass so the running anaconda window inherits the icon
desktop-file-edit \
    --set-key=Icon --set-value=/usr/share/icons/hicolor/scalable/apps/dev.getaurora.installer.svg \
    --set-key=StartupWMClass --set-value=slitherer \
    /usr/share/applications/liveinst.desktop

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
bootc --source-imgref=containers-storage:$IMAGE_REF:$IMAGE_TAG --target-imgref=$IMAGE_REF:$IMAGE_TAG
EOF


# temporary to test things
dnf copr -y enable rhcontainerbot/bootc
dnf swap --from-repo=copr:copr.fedorainfracloud.org:rhcontainerbot:bootc bootc bootc
dnf copr -y disable rhcontainerbot/bootc

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/pki/akmods/certs/akmods-ublue.der"

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

# debug
ksflatten -c /usr/share/anaconda/interactive-defaults.ks

ksvalidator /usr/share/anaconda/interactive-defaults.ks
