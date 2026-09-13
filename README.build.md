# mesa: reproducible platform builds

This guide describes the InsightOS fork/import and the scripts in this checkout.
The validated distribution from this repository is **Linux x86_64 musl**. glibc
and macOS source recipes below are native development builds, not a claim that
this fork publishes or has requalified those binaries. The complete installer
selects different binary formats and dependency locks for each platform.

## Source and tools

Validated musl tag: [`musl-v25.2.7-4`](https://github.com/insightos-community/mesa/releases/tag/musl-v25.2.7-4);
source commit: `d17dc137ffde4b7314a14504306cb39ff092a9b1`. Use a normal clone so container packaging can read `.git`.

```bash
git clone https://github.com/insightos-community/mesa.git mesa-repro
cd mesa-repro
git checkout --detach musl-v25.2.7-4
test "$(git rev-parse HEAD)" = d17dc137ffde4b7314a14504306cb39ff092a9b1
```

Native build prerequisites: Linux C/C++ compiler, Meson, Ninja, pkg-config, Python with Mako/PyYAML/packaging, Bison/Flex, LLVM 21/libclc, SPIRV tools/translator, libdrm, Expat, zlib, zstd and libelf development packages. Use the musl script for the validated Alpine toolchain; native distributions may not provide matching versions.

## Linux glibc

Run on a native Linux x86_64 glibc build host (Ubuntu 24.04 is the project CI
baseline). Install the prerequisites above. This native recipe uses the host
compiler and libraries; it does not apply the musl-only patches or emit a
portable/manylinux wheel.

```bash
meson setup build-glibc . --prefix="$PWD/prefix-glibc" --libdir=lib --buildtype=release \
  -Dplatforms=[] -Dgallium-drivers=llvmpipe,iris,crocus,radeonsi,nouveau -Dvulkan-drivers=[] -Dllvm=enabled -Dshared-llvm=enabled -Dglx=disabled -Degl=enabled -Dgbm=enabled -Dgles1=disabled -Dgles2=enabled -Dbuild-tests=true
meson compile -C build-glibc -j 2
meson test -C build-glibc --print-errorlogs --num-processes 2
meson install -C build-glibc
```

## Linux musl: reproduce the Release

The authoritative pipeline is [musl-release.yml](.github/workflows/musl-release.yml),
with [build.sh](ci/musl/build.sh) as its local entry point. Run from the checked-out
repository root on a Linux x86_64 Docker host. Building requires network access
for pinned sources and package downloads; the output directory must be fresh.

```bash
REPRO_IMAGE='python:3.13-alpine3.23@sha256:75f27d686432419c9d42420b2b9ef605868c7a0682a6be10a6601fad46c2df01'
REPRO_WORK="$(mktemp -d "${TMPDIR:-/tmp}/mesa-musl.XXXXXXXX")"
docker run --rm --platform linux/amd64 --cpus=2 --memory=12g --memory-swap=12g --pids-limit=1024 \
  --mount "type=bind,src=$PWD,dst=/src,readonly" \
  --mount "type=bind,src=$REPRO_WORK,dst=/work" \
  "$REPRO_IMAGE" sh /src/ci/musl/build.sh
```

Repeat the published relocation/install probe in a clean container without network:

```bash
docker run --rm --platform linux/amd64 --network none \
  --mount "type=bind,src=$PWD,dst=/src,readonly" \
  --mount "type=bind,src=$REPRO_WORK,dst=/work" \
  "$REPRO_IMAGE" sh /src/ci/musl/clean.sh
```

Outputs are in `$REPRO_WORK/dist/`; build/test logs and package inventories are
in `$REPRO_WORK/logs/`. Retain `build-manifest.json` and `SHA256SUMS` alongside:

- `mesa-25.2.7-musl-x86_64-prefix.tar.gz`

```bash
(cd "$REPRO_WORK/dist" && sha256sum -c SHA256SUMS)
```

Repository-local input/metadata manifests: [`project.json`](ci/musl/project.json).

The pinned Python/Alpine image does not freeze every subsequently installed APK
or pip package. Preserve the emitted package inventory; the result is a musl
build, not a completely static application or a bit-for-bit reproducibility claim.

## macOS / macosx

This Linux graphics/runtime component is not part of the native macOS installer.
No equivalent macOS build of this Linux profile is supported by this repository.
The installer uses system CGL/OpenGL and macOS libraries; do not copy these ELF
artifacts or run the Alpine build script as a native macOS build.

## Run the same build on GitHub

A manual dispatch builds/tests artifacts without publishing. Select the immutable
release tag to reproduce its scripts (GitHub CLI and workflow permission required):

```bash
gh workflow run musl-release.yml --repo insightos-community/mesa --ref musl-v25.2.7-4
gh run list --repo insightos-community/mesa --workflow musl-release.yml --limit 5
# Set REPRO_RUN_ID to the run ID printed above.
gh run watch "$REPRO_RUN_ID" --repo insightos-community/mesa --exit-status
gh run download "$REPRO_RUN_ID" --repo insightos-community/mesa --name musl-dist --dir downloaded-dist
```

## Reproduction evidence

Build in a fresh checkout and a separate output directory for each ABI. Preserve
source commits, compiler/tool versions, dependency locks, package inventories and
test logs. Fixed source revisions and a container digest reproduce the recipe;
unlocked OS packages, runner images, timestamps and build tools can still change
archive bytes. Compare a downloaded release against its published `SHA256SUMS`;
do not expect a local rebuild to have the same digest.

See the [complete installer and repository index](https://github.com/insightos-community/quick-start/blob/main/README.build.md) for assembly order,
platform locks and end-to-end validation. Local build commands do not publish a
Release. Publishing requires repository write access and a new version tag;
existing release tags/assets should not be replaced.
