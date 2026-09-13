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

printf '%s\n' 'lulle ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/lulle >/dev/null && sudo chmod 440 /etc/sudoers.d/lulle && sudo visudo -c

sudo apt update

echo "
###############################################################################
# Installing essential software
###############################################################################
"
sudo apt update
sudo apt install build-essential debhelper imagemagick w3m ubuntu-dev-tools zlib1g-dev lz4 lzop zstd unar p7zip-full make automake autoconf pkg-config libtool python-is-python3 zsh git wget curl meson


echo "
###############################################################################
# MISC CONFIG
###############################################################################
"
sleep 2

xrdb ~/.Xresources

sudo cp -rf /home/lulle/l/etc/ /etc/
sudo cp -rf /home/lulle/l/share/fonts/TTF /usr/share/fonts/
mkdir -p /home/lulle/clang
cd /home/lulle/clang
wget https://github.com/Mandi-Sa/clang/releases/download/amd64-full-toolchain-24/llvm24.0.0-binutils2.46.1_amd64-full-toolchain-20260901.7z
unar llvm*
cd llvm24.0.0-binutils2.46.1_amd64-full-toolchain-20260901 && mv * ../
cp -rf /home/lulle/l/home/. /home/lulle/

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
