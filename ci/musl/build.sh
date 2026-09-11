#!/bin/sh
set -eu
cd /work
mkdir -p logs prefix dist wheelhouse
exec > logs/build.log 2>&1
apk add --no-cache build-base cmake meson ninja git curl linux-headers pkgconf llvm21-dev clang21-dev libclc-dev spirv-llvm-translator-dev spirv-tools-dev libdrm-dev expat-dev zlib-dev zstd-dev elfutils-dev bison flex binutils
python -m pip install mako==1.3.10 pyyaml==6.0.3 packaging==25.0
apk info -v > logs/apk-packages.txt
meson setup build /src --prefix=/work/prefix --libdir=lib --buildtype=release \
  -Dplatforms=[] -Dgallium-drivers=llvmpipe,iris,crocus,radeonsi,nouveau \
  -Dvulkan-drivers=[] -Dllvm=enabled -Dshared-llvm=enabled -Dglx=disabled \
  -Degl=enabled -Dgbm=enabled -Dgles1=disabled -Dgles2=enabled -Dbuild-tests=true \
  > logs/configure.log 2>&1
meson compile -C build -j 2 > logs/compile.log 2>&1
meson test -C build --print-errorlogs --num-processes 2 --timeout-multiplier 3 > logs/tests.log 2>&1
meson install -C build > logs/install.log 2>&1
mkdir -p prefix/share/insightos-mesa
cp /src/ci/musl/launch.py /src/ci/musl/probe.py prefix/share/insightos-mesa/
printf '%s\n' llvmpipe,iris,crocus,radeonsi,nouveau > prefix/drivers.txt
python /src/ci/musl/package.py
python /src/ci/musl/fetch-test-wheel.py
python -m pip download --only-binary=:all: --dest wheelhouse numpy==2.3.5 absl-py 'etils[epath]' glfw PyOpenGL
