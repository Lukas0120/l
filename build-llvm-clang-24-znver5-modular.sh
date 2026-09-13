#!/usr/bin/env bash
set -euo pipefail

########################################
# Config
########################################

LLVM_TAG="llvmorg-24-init"
TOPLEV="$HOME/llvm-24-znver5"
INSTALL_PREFIX="/opt/llvm/clang-24-znver5"
N_CORES="$(nproc)"

COMMON_FLAGS="-O3 -pipe -march=native -mtune=znver5"
export CFLAGS="${COMMON_FLAGS}"
export CXXFLAGS="${COMMON_FLAGS}"
export LDFLAGS="-Wl,-q"

KERNEL_SRC="/home/lulle/linux-kernel"
KERNEL_BUILD="${TOPLEV}/kernel-build-pgo"

########################################
# Step 0 – Common setup and deps
########################################

mkdir -p "${TOPLEV}"
cd "${TOPLEV}"

sudo apt update
sudo apt install -y \
  build-essential git cmake ninja-build \
  python3 python3-dev python3-distutils \
  binutils binutils-dev lld \
  libtinfo-dev libedit-dev libzstd-dev \
  libxml2-dev libsqlite3-dev \
  libbz2-dev liblzma-dev libffi-dev \
  zlib1g-dev libssl-dev \
  linux-tools-common linux-tools-generic

if [ ! -d llvm-project ]; then
  git clone https://github.com/llvm/llvm-project.git
fi

cd llvm-project
git fetch --tags
git checkout "${LLVM_TAG}"
cd "${TOPLEV}"

########################################
# Step 1 – Stage 1 bootstrap compiler
########################################

STAGE1_BUILD="${TOPLEV}/stage1-build"
STAGE1_INSTALL="${TOPLEV}/stage1-install"

mkdir -p "${STAGE1_BUILD}"
cd "${STAGE1_BUILD}"

cmake -G Ninja \
  "${TOPLEV}/llvm-project/llvm" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;lldb;bolt" \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt;openmp" \
  -DLLVM_USE_LINKER=lld \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_INSTALL_PREFIX="${STAGE1_INSTALL}"

ninja -j"${N_CORES}" clang lld bolt
ninja -j"${N_CORES}" install

########################################
# Step 2 – Stage 2 instrumented compiler
########################################

STAGE2_PROFGEN_BUILD="${TOPLEV}/stage2-prof-gen-build"
STAGE2_PROFGEN_INSTALL="${TOPLEV}/stage2-prof-gen-install"

CPATH="${STAGE1_INSTALL}/bin"

mkdir -p "${STAGE2_PROFGEN_BUILD}"
cd "${STAGE2_PROFGEN_BUILD}"

cmake -G Ninja \
  "${TOPLEV}/llvm-project/llvm" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="${CPATH}/clang" \
  -DCMAKE_CXX_COMPILER="${CPATH}/clang++" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_BUILD_INSTRUMENTED=ON \
  -DCMAKE_INSTALL_PREFIX="${STAGE2_PROFGEN_INSTALL}" \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}"

ninja -j"${N_CORES}" install

########################################
# Step 3 – PGO training (LLVM + kernel)
########################################

STAGE3_TRAIN_BUILD="${TOPLEV}/stage3-train-build"
KERNEL_BUILD="${TOPLEV}/kernel-build-pgo"

CPATH="${STAGE2_PROFGEN_INSTALL}/bin"

mkdir -p "${STAGE3_TRAIN_BUILD}"
cd "${STAGE3_TRAIN_BUILD}"

cmake -G Ninja \
  "${TOPLEV}/llvm-project/llvm" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="${CPATH}/clang" \
  -DCMAKE_CXX_COMPILER="${CPATH}/clang++" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_USE_LINKER=lld \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}"

# Build LLVM/Clang as PGO training
ninja -j"${N_CORES}" clang lld llvm-ar llvm-as llvm-objdump llvm-objcopy

# Build Linux kernel with instrumented clang
mkdir -p "${KERNEL_BUILD}"
cd "${KERNEL_SRC}"

make -j"${N_CORES}" O="${KERNEL_BUILD}" x86_64_defconfig

make -j"${N_CORES}" O="${KERNEL_BUILD}" \
     LLVM=1 \
     CC="${CPATH}/clang" \
     LD=ld.lld

# Merge .profraw into .profdata
PROFDIR="${STAGE2_PROFGEN_BUILD}/profiles"

if [ ! -d "${PROFDIR}" ] || [ -z "$(ls -A "${PROFDIR}"/*.profraw 2>/dev/null || true)" ]; then
  PROFDIR="${STAGE2_PROFGEN_BUILD}"
fi

mkdir -p "${TOPLEV}/profiles"

"${CPATH}/llvm-profdata" merge \
  -output="${TOPLEV}/clang.profdata" \
  "${PROFDIR}"/*.profraw || {
  echo "No .profraw found in ${PROFDIR}; searching whole build tree..."
  mapfile -t RAWFILES < <(find "${STAGE2_PROFGEN_BUILD}" -name '*.profraw' 2>/dev/null || true)
  if [ "${#RAWFILES[@]}" -eq 0 ]; then
    echo "ERROR: No .profraw files found anywhere under ${STAGE2_PROFGEN_BUILD}"
    exit 1
  fi
  "${CPATH}/llvm-profdata" merge \
    -output="${TOPLEV}/clang.profdata" \
    "${RAWFILES[@]}"
}

echo "Merged PGO profile written to: ${TOPLEV}/clang.profdata"
ls -lh "${TOPLEV}/clang.profdata"

########################################
# Step 4 – PGO + LTO final compiler
########################################

STAGE2_PGO_LTO_BUILD="${TOPLEV}/stage2-prof-use-lto-build"
STAGE2_PGO_LTO_INSTALL="${TOPLEV}/stage2-prof-use-lto-install"

CPATH="${STAGE1_INSTALL}/bin"
PROFDATA="${TOPLEV}/clang.profdata"

mkdir -p "${STAGE2_PGO_LTO_BUILD}"
cd "${STAGE2_PGO_LTO_BUILD}"

cmake -G Ninja \
  "${TOPLEV}/llvm-project/llvm" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="${CPATH}/clang" \
  -DCMAKE_CXX_COMPILER="${CPATH}/clang++" \
  -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;lld;bolt" \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt;openmp" \
  -DLLVM_ENABLE_LTO=Thin \
  -DLLVM_PROFDATA_FILE="${PROFDATA}" \
  -DLLVM_USE_LINKER=lld \
  -DCMAKE_INSTALL_PREFIX="${STAGE2_PGO_LTO_INSTALL}" \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}"

ninja -j"${N_CORES}" clang lld bolt
ninja -j"${N_CORES}" install

########################################
# Step 5 – BOLT profile collection
########################################

STAGE3_BOLT_PROFILE_BUILD="${TOPLEV}/stage3-bolt-profile-build"
BOLT_PROFILES="${TOPLEV}/bolt-profiles"
KERNEL_BUILD="${TOPLEV}/kernel-build-bolt"

CPATH="${STAGE2_PGO_LTO_INSTALL}/bin"
CLANG_TO_OPT="${BOLT_PROFILES}/clang-to-optimize"

mkdir -p "${BOLT_PROFILES}"
cp "${STAGE2_PGO_LTO_INSTALL}/bin/clang" "${CLANG_TO_OPT}"
chmod +x "${CLANG_TO_OPT}"

mkdir -p "${STAGE3_BOLT_PROFILE_BUILD}"
cd "${STAGE3_BOLT_PROFILE_BUILD}"

cmake -G Ninja \
  "${TOPLEV}/llvm-project/llvm" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER="${CLANG_TO_OPT}" \
  -DCMAKE_CXX_COMPILER="${CLANG_TO_OPT}" \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_USE_LINKER=lld \
  -DCMAKE_INSTALL_PREFIX="${STAGE3_BOLT_PROFILE_BUILD}/install" \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LDFLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LDFLAGS}"

# LLVM/Clang build profile
cd "${BOLT_PROFILES}"
perf record -e cycles:u -j any,u \
  -o perf-llvm.data \
  -- \
  env CC="${CLANG_TO_OPT}" CXX="${CLANG_TO_OPT}" \
  ninja -j"${N_CORES}" -C "${STAGE3_BOLT_PROFILE_BUILD}" clang lld

# Kernel build profile
mkdir -p "${KERNEL_BUILD}"
cd "${KERNEL_SRC}"

make -j"${N_CORES}" O="${KERNEL_BUILD}" x86_64_defconfig

cd "${KERNEL_SRC}"
perf record -e cycles:u -j any,u \
  -o "${BOLT_PROFILES}/perf-kernel.data" \
  -- \
  make -j"${N_CORES}" O="${KERNEL_BUILD}" \
       LLVM=1 \
       CC="${CLANG_TO_OPT}" \
       LD=ld.lld

########################################
# Step 6 – BOLT optimization
########################################

CLANG_BOLT="${BOLT_PROFILES}/clang-bolt"

cd "${BOLT_PROFILES}"

# Convert each perf.data to fdata
perf2bolt "${CLANG_TO_OPT}" \
  -p perf-llvm.data \
  -o clang-llvm.fdata \
  -w clang-llvm.yaml

perf2bolt "${CLANG_TO_OPT}" \
  -p perf-kernel.data \
  -o clang-kernel.fdata \
  -w clang-kernel.yaml

# Merge fdata profiles
merge-fdata clang-llvm.fdata clang-kernel.fdata > clang-combined.fdata

# Optimize
llvm-bolt "${CLANG_TO_OPT}" \
  -o "${CLANG_BOLT}" \
  -data clang-combined.fdata \
  -reorder-blocks=ext-tsp \
  -reorder-functions=hfsort+ \
  -split-functions=3 \
  -split-all-cold \
  -split-eh \
  -dyno-stats \
  -icf=1 \
  -use-gnu-stack

########################################
# Step 7 – Final install and env
########################################

sudo mkdir -p "${INSTALL_PREFIX}"
sudo rsync -a "${STAGE2_PGO_LTO_INSTALL}/" "${INSTALL_PREFIX}/"

# Replace plain clang with BOLT-optimized one inside the install tree
sudo cp "${CLANG_BOLT}" "${INSTALL_PREFIX}/bin/clang"
sudo cp "${CLANG_BOLT}" "${INSTALL_PREFIX}/bin/clang++" 2>/dev/null || \
  sudo ln -sf clang "${INSTALL_PREFIX}/bin/clang++"

ENV_FILE="/etc/profile.d/llvm-clang-24-znver5.sh"

sudo bash -c "cat > \"${ENV_FILE}\"" <<EOF
export LLVM_ZNVER5_ROOT="${INSTALL_PREFIX}"
export PATH="\${LLVM_ZNVER5_ROOT}/bin:\$PATH"
export LD_LIBRARY_PATH="\${LLVM_ZNVER5_ROOT}/lib:\${LLVM_ZNVER5_ROOT}/lib/x86_64-unknown-linux-gnu:\$LD_LIBRARY_PATH"
export CXXFLAGS="${COMMON_FLAGS} -stdlib=libc++"
export LDFLAGS="-Wl,-q -stdlib=libc++"
EOF

echo
echo "==============================================================="
echo "LLVM/Clang 24 toolchain built and installed at:"
echo "  ${INSTALL_PREFIX}"
echo
echo "Log out and back in (or source ${ENV_FILE}) to use it:"
echo "  source ${ENV_FILE}"
echo
echo "Then compile with, for example:"
echo "  clang++ -O3 -march=native -mtune=znver5 -stdlib=libc++ your.cpp"
echo "==============================================================="