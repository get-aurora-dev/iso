#!/usr/bin/bash

set -exo pipefail

{ export PS4='+( ${BASH_SOURCE}:${LINENO} ): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'; } 2>/dev/null

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create the directory that /root is symlinked to
mkdir -p "$(realpath /root)"

# bwrap tries to write /proc/sys/user/max_user_namespaces which is mounted as ro
# so we need to remount it as rw
mount -o remount,rw /proc/sys

# Install flatpaks if list exists
if [[ -f "$SCRIPT_DIR/flatpaks.list" ]]; then
    echo "Installing flatpaks..."
    curl --retry 3 -Lo /etc/flatpak/remotes.d/flathub.flatpakrepo https://dl.flathub.org/repo/flathub.flatpakrepo
    xargs -r flatpak install -y --noninteractive < "$SCRIPT_DIR/flatpaks.list" || true
    # cleanup our leftovers
    rm -rf /flatpak-list
fi

# Configure podman temporarily to write to /usr/lib/containers/storage
# This avoids storing the huge base image in /var/lib/containers/storage
# (which is empty/tmpfs in the booted live environment and would exhaust RAM)
mkdir -p /etc/containers
cat >/etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/usr/lib/containers/storage"
EOF

# Pull the container image to be installed
if [[ -n "${BASE_IMAGE:-}" ]]; then
    podman pull "${BASE_IMAGE}"
else
    # Fallback to reading image-info.json if BASE_IMAGE not set
    IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
    IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
    IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
    IMAGE_REF="${IMAGE_REF##*://}"
    podman pull "${IMAGE_REF}:${IMAGE_TAG}"
fi

# Clean up the temporary storage configuration so that runtime podman uses the default
rm -f /etc/containers/storage.conf

# Install required packages
dnf install -y \
    dracut-live \
    livesys-scripts \
    git \
    jq \
    rsync \
    desktop-file-utils \
    anaconda-live \
    anaconda-webui \
    libblockdev-btrfs \
    libblockdev-lvm \
    libblockdev-dm

kernel=$(find /usr/lib/modules -maxdepth 1 -type d -printf '%P\n' | grep . | head -1)
DRACUT_NO_XATTR=1 dracut -v --force --zstd --reproducible --no-hostonly \
    --add "dmsquash-live dmsquash-live-autooverlay" \
    "/usr/lib/modules/${kernel}/initramfs.img" "${kernel}"

# Configure livesys-scripts
sed -i "s/^livesys_session=.*/livesys_session=kde/" /etc/sysconfig/livesys
systemctl enable livesys.service livesys-late.service

# Run the configure/postrootfs hook
# We pass BASE_IMAGE so it can be used inside the script
export BASE_IMAGE="${BASE_IMAGE:-}"
bash \
  "$SCRIPT_DIR/undo-image.sh" \
  "$SCRIPT_DIR/flatpak-mount-workaround.sh" \
  "$SCRIPT_DIR/plasma-tweaks.sh" \
  "$SCRIPT_DIR/workarounds.sh" \
  "$SCRIPT_DIR/configure_iso_anaconda.sh"

# image-builder needs gcdx64.efi / grub modules
_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
    dnf install -y grub2-efi-x64-cdboot
elif [[ $_arch == "aarch64" ]]; then
    dnf install -y grub2-efi-aa64-modules
fi

# image-builder expects the EFI directory to be in /boot/efi
mkdir -p /boot/efi
cp -av /usr/lib/efi/*/*/EFI /boot/efi/

# Remove fallback efi
_arch=$(uname -m)
if [[ $_arch == "x86_64" ]]; then
    cp -v /boot/efi/EFI/fedora/grubx64.efi /boot/efi/EFI/BOOT/fbx64.efi
elif [[ $_arch == "aarch64" ]]; then
    cp -v /boot/efi/EFI/fedora/grubaa64.efi /boot/efi/EFI/BOOT/fbaa64.efi
fi

# Set the timezone to UTC
rm -f /etc/localtime
systemd-firstboot --timezone UTC

# Mount a larger tmpfs to /var/tmp at boot time to avoid disk space issues
mkdir -p /var/tmp
cat >/etc/systemd/system/var-tmp.mount <<'EOF'
[Unit]
Description=Larger tmpfs for /var/tmp on live system

[Mount]
What=tmpfs
Where=/var/tmp
Type=tmpfs
Options=size=50%,nr_inodes=1m,x-systemd.graceful-option=usrquota

[Install]
WantedBy=local-fs.target
EOF
systemctl enable var-tmp.mount

# Copy in the iso config for image-builder
mkdir -p /usr/lib/bootc-image-builder
cp "$SCRIPT_DIR/iso.yaml" /usr/lib/bootc-image-builder/iso.yaml

# Clean up dnf cache to save space
dnf clean all
