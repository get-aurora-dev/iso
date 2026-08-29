#!/usr/bin/env bash
set -eoux pipefail

# add installer to kickoff
sed -i '2s/$/;liveinst.desktop/' /usr/share/kde-settings/kde-profile/default/xdg/kicker-extra-favoritesrc

tee -a /etc/xdg/kwalletrc <<EOF
[Wallet]
Enabled=false
EOF

git clone https://github.com/get-aurora-dev/branding /tmp/branding
cp -r /tmp/branding/iso_files/usr/* /usr/
rm -rf /tmp/branding
