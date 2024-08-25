#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------


echo "
###############################################################################
# Configuring Best Mirrors & Setting up repos
###############################################################################
"
sudo apt update

echo "
###############################################################################
# Installing essential software
###############################################################################
"
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -vo /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
sudo apt update


PKGS=(
'imagemagick'
'w3m'
'build-essential'
'debhelper'
'ubuntu-dev-tools'
'zlib1g-dev'
'git-lfs'
'make'
'automake'
'make'
'automake'
'pkg-config'
'ibtool'
'linux-xanmod-edge-x64v3'

)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo apt install -y
done


echo "
###############################################################################
# MISC CONFIG
###############################################################################
"
sleep 2

xrdb ~/.Xresources


sudo ln -sf /etc/fonts/conf.avail/10-sub-pixel-rgb.conf /etc/fonts/conf.d
sudo ln -sf /etc/fonts/conf.avail/70-no-bitmaps.conf /etc/fonts/conf.d
sudo ln -sf /etc/fonts/conf.avail/10-hinting-full.conf /etc/fonts/conf.d
sudo sed "s,\#export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",export FREETYPE_PROPERTIES=\"truetype\:interpreter-version=40\",g" -i /etc/profile.d/freetype2.sh

sudo grub-mkconfig -o /boot/grub/grub.cfg


echo "
###############################################################################
# Done
###############################################################################
"
sleep 3
