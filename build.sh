#!/usr/bin/env bash

PKGS=(
'thunar'
'geany'
'geany-plugins'

)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    asp export "$PKG"
done

################################################
################################################
###   AUR ##########
################################################

PKGS=(
'rxvt-unicode-truecolor-wide-glyphs'
'picom-ibhagwan-git'


)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    paru -G "$PKG"
done

######################################################


files=$(find . -name "PKGBUILD")

for f in $files
do
        d=$(dirname $f)
        echo "makepkg -scf --skipinteg --noconfirm $f"
        cd $d
        makepkg -scf --skipinteg --noconfirm $d/PKGBUILD
        cd ..
done
