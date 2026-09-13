#!/usr/bin/env bash
#
# set-clang24-toolchain.sh
#
# Register a custom LLVM/Clang 24 toolchain in /home/lulle/clang
# as the system-wide default using update-alternatives.
#
# This script:
#   - Registers clang, clang++, cpp, cc, c++ and the full llvm-* toolset
#   - Uses a very high priority so it dominates over distro packages
#   - Optionally removes existing clang/llvm alternatives first
#
# Usage:
#   sudo bash set-clang24-toolchain.sh
#
# Adjust CLANG_ROOT if your toolchain lives elsewhere.

set -euo pipefail

CLANG_ROOT="/home/lulle/clang"
CLANG_BIN="${CLANG_ROOT}/bin"
PRIORITY=1000   # High priority to override system toolchains

# Verify toolchain exists
if [[ ! -d "${CLANG_BIN}" ]]; then
    echo "ERROR: Clang toolchain not found at ${CLANG_BIN}"
    exit 1
fi

# Basic compiler checks
for prog in clang clang++; do
    if [[ ! -x "${CLANG_BIN}/${prog}" ]]; then
        echo "ERROR: ${prog} not found in ${CLANG_BIN}"
        exit 1
    fi
done

echo "Using Clang toolchain from: ${CLANG_BIN}"
echo "Priority: ${PRIORITY}"
echo ""

# Optional: remove existing clang/llvm alternatives to avoid conflicts
read -rp "Remove existing clang/llvm alternatives before registering new ones? [y/N] " -n 1 REPLY
echo ""
if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    echo "Removing existing alternatives..."

    # Remove common clang/llvm groups
    for group in clang clang++ cc c++ \
                 llvm-config llvm-ar llvm-as llvm-bcanalyzer llvm-bitcode-strip \
                 llvm-cxxfilt llvm-dwarfdump llvm-dwp llvm-extract llvm-ifs \
                 llvm-install-name-tool llvm-lib llvm-link llvm-lto llvm-lto2 \
                 llvm-mc llvm-nm llvm-objcopy llvm-objdump llvm-opt-report \
                 llvm-pdbutil llvm-profdata llvm-ranlib llvm-readelf \
                 llvm-readobj llvm-reduce llvm-remarkutil llvm-size \
                 llvm-split llvm-stress llvm-strings llvm-strip llvm-symbolizer \
                 llvm-tblgen llvm-undname opt sancov sanstats scan-build scan-view; do
        update-alternatives --remove-all "${group}" 2>/dev/null || true
    done

    echo "Existing alternatives removed."
fi

echo ""
echo "Registering new alternatives for Clang 24 toolchain..."

#
# Core compilers
#
update-alternatives --install /usr/bin/clang      clang      "${CLANG_BIN}/clang"      "${PRIORITY}"
update-alternatives --install /usr/bin/clang++    clang++    "${CLANG_BIN}/clang++"    "${PRIORITY}"

# cc/c++ as aliases to clang/clang++
update-alternatives --install /usr/bin/cc         cc         "${CLANG_BIN}/clang"      "${PRIORITY}"
update-alternatives --install /usr/bin/c++        c++        "${CLANG_BIN}/clang++"    "${PRIORITY}"

#
# LLVM core tools
#
update-alternatives --install /usr/bin/llvm-config        llvm-config        "${CLANG_BIN}/llvm-config"        "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-ar            llvm-ar            "${CLANG_BIN}/llvm-ar"            "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-as            llvm-as            "${CLANG_BIN}/llvm-as"            "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-bcanalyzer    llvm-bcanalyzer    "${CLANG_BIN}/llvm-bcanalyzer"    "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-bitcode-strip llvm-bitcode-strip "${CLANG_BIN}/llvm-bitcode-strip" "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-cxxfilt       llvm-cxxfilt       "${CLANG_BIN}/llvm-cxxfilt"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-dwarfdump     llvm-dwarfdump     "${CLANG_BIN}/llvm-dwarfdump"     "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-dwp           llvm-dwp           "${CLANG_BIN}/llvm-dwp"           "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-extract       llvm-extract       "${CLANG_BIN}/llvm-extract"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-ifs           llvm-ifs           "${CLANG_BIN}/llvm-ifs"           "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-install-name-tool llvm-install-name-tool "${CLANG_BIN}/llvm-install-name-tool" "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-lib           llvm-lib           "${CLANG_BIN}/llvm-lib"           "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-link          llvm-link          "${CLANG_BIN}/llvm-link"          "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-lto           llvm-lto           "${CLANG_BIN}/llvm-lto"           "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-lto2          llvm-lto2          "${CLANG_BIN}/llvm-lto2"          "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-mc            llvm-mc            "${CLANG_BIN}/llvm-mc"            "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-nm            llvm-nm            "${CLANG_BIN}/llvm-nm"            "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-objcopy       llvm-objcopy       "${CLANG_BIN}/llvm-objcopy"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-objdump       llvm-objdump       "${CLANG_BIN}/llvm-objdump"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-opt-report    llvm-opt-report    "${CLANG_BIN}/llvm-opt-report"    "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-pdbutil       llvm-pdbutil       "${CLANG_BIN}/llvm-pdbutil"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-profdata      llvm-profdata      "${CLANG_BIN}/llvm-profdata"      "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-ranlib        llvm-ranlib        "${CLANG_BIN}/llvm-ranlib"        "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-readelf       llvm-readelf       "${CLANG_BIN}/llvm-readelf"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-readobj       llvm-readobj       "${CLANG_BIN}/llvm-readobj"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-reduce        llvm-reduce        "${CLANG_BIN}/llvm-reduce"        "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-remarkutil    llvm-remarkutil    "${CLANG_BIN}/llvm-remarkutil"    "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-size          llvm-size          "${CLANG_BIN}/llvm-size"          "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-split         llvm-split         "${CLANG_BIN}/llvm-split"         "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-stress        llvm-stress        "${CLANG_BIN}/llvm-stress"        "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-strings       llvm-strings       "${CLANG_BIN}/llvm-strings"       "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-strip         llvm-strip         "${CLANG_BIN}/llvm-strip"         "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-symbolizer    llvm-symbolizer    "${CLANG_BIN}/llvm-symbolizer"    "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-tblgen        llvm-tblgen        "${CLANG_BIN}/llvm-tblgen"        "${PRIORITY}"
update-alternatives --install /usr/bin/llvm-undname       llvm-undname       "${CLANG_BIN}/llvm-undname"       "${PRIORITY}"

#
# Optimizer and related tools
#
update-alternatives --install /usr/bin/opt      opt      "${CLANG_BIN}/opt"      "${PRIORITY}"
update-alternatives --install /usr/bin/sancov   sancov   "${CLANG_BIN}/sancov"   "${PRIORITY}"
update-alternatives --install /usr/bin/sanstats sanstats "${CLANG_BIN}/sanstats" "${PRIORITY}"

#
# Static analyzer / scan-build suite
#
if [[ -x "${CLANG_BIN}/scan-build" ]]; then
    update-alternatives --install /usr/bin/scan-build scan-build "${CLANG_BIN}/scan-build" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/scan-view" ]]; then
    update-alternatives --install /usr/bin/scan-view scan-view "${CLANG_BIN}/scan-view" "${PRIORITY}"
fi

#
# Linker and archiver (often used directly by build systems)
#
if [[ -x "${CLANG_BIN}/ld.lld" ]]; then
    update-alternatives --install /usr/bin/ld      ld      "${CLANG_BIN}/ld.lld"   "${PRIORITY}"
    update-alternatives --install /usr/bin/ld.bfd  ld.bfd  "${CLANG_BIN}/ld.lld"   "${PRIORITY}"
    update-alternatives --install /usr/bin/ld.lld  ld.lld  "${CLANG_BIN}/ld.lld"   "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-ar" ]]; then
    update-alternatives --install /usr/bin/ar  ar  "${CLANG_BIN}/llvm-ar" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-ranlib" ]]; then
    update-alternatives --install /usr/bin/ranlib  ranlib  "${CLANG_BIN}/llvm-ranlib" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-strip" ]]; then
    update-alternatives --install /usr/bin/strip  strip  "${CLANG_BIN}/llvm-strip" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-objcopy" ]]; then
    update-alternatives --install /usr/bin/objcopy  objcopy  "${CLANG_BIN}/llvm-objcopy" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-nm" ]]; then
    update-alternatives --install /usr/bin/nm  nm  "${CLANG_BIN}/llvm-nm" "${PRIORITY}"
fi

if [[ -x "${CLANG_BIN}/llvm-size" ]]; then
    update-alternatives --install /usr/bin/size  size  "${CLANG_BIN}/llvm-size" "${PRIORITY}"
fi

#
# Optional: clang-format, clang-tidy, clangd, etc. if present
#
for tool in clang-format clang-tidy clangd clang-apply-replacements clang-query clang-rename; do
    if [[ -x "${CLANG_BIN}/${tool}" ]]; then
        update-alternatives --install "/usr/bin/${tool}" "${tool}" "${CLANG_BIN}/${tool}" "${PRIORITY}"
    fi
done

echo ""
echo "Alternatives registration complete."
echo ""
echo "Verifying active toolchain:"
echo ""

# Show current alternatives
echo "clang:"
update-alternatives --display clang | grep -E "link|currently"
echo ""
echo "clang++:"
update-alternatives --display clang++ | grep -E "link|currently"
echo ""
echo "cc:"
update-alternatives --display cc | grep -E "link|currently"
echo ""
echo "c++:"
update-alternatives --display c++ | grep -E "link|currently"
echo ""
echo "ld:"
update-alternatives --display ld 2>/dev/null | grep -E "link|currently" || echo "(ld alternatives not configured)"
echo ""

echo "Active compiler versions:"
clang --version | head -n1
clang++ --version | head -n1
cc --version | head -n1
c++ --version | head -n1
ld.lld --version 2>/dev/null | head -n1 || echo "(ld.lld not found)"

echo ""
echo "Done. Your custom Clang 24 toolchain in ${CLANG_BIN} is now the system default."
echo ""
echo "To switch later:"
echo "  sudo update-alternatives --config clang"
echo "  sudo update-alternatives --config clang++"
echo "  sudo update-alternatives --config cc"
echo "  sudo update-alternatives --config c++"
echo "  sudo update-alternatives --config ld"
