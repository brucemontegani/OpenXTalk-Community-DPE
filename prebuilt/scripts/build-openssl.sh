#!/usr/bin/env bash
# build-openssl.sh
# Builds OpenSSL from a tarball (offline-friendly) and stages artifacts into prebuilt/ paths
# expected by prebuilt/libopenssl.gyp.

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "${BASEDIR}/scripts/platform.inc"
source "${BASEDIR}/scripts/lib_versions.inc"
source "${BASEDIR}/scripts/util.inc"

# --------------------------------------------------------------------------------------
# Source acquisition (tarball -> extracted dir)
# --------------------------------------------------------------------------------------

OPENSSL_TGZ="openssl-${OpenSSL_VERSION}.tar.gz"
OPENSSL_SRC="openssl-${OpenSSL_VERSION}"

ROOTDIR="$(cd "${BASEDIR}/.." && pwd)"

# Repo cache for offline/deterministic builds:
#   <repo>/sources/openssl-<ver>.tar.gz
CACHE_DIR="${ROOTDIR}/sources"
VENDORED_OPENSSL_TGZ="${CACHE_DIR}/${OPENSSL_TGZ}"

# Build working directory (expects BUILDDIR from platform.inc; fallback if missing)
BUILDDIR="${BUILDDIR:-${BASEDIR}/build}"
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

ensure_openssl_source() {
  mkdir -p "${CACHE_DIR}"

  if [ -d "${OPENSSL_SRC}" ]; then
    # Already extracted
    return 0
  fi

  # 1) Prefer repo cache -> copy to build dir
  if [ ! -f "${OPENSSL_TGZ}" ] && [ -f "${VENDORED_OPENSSL_TGZ}" ]; then
    echo "Using cached OpenSSL tarball: ${VENDORED_OPENSSL_TGZ}"
    cp -f "${VENDORED_OPENSSL_TGZ}" "${OPENSSL_TGZ}"
  fi

  # 2) If still missing, download unless OFFLINE=1
  if [ ! -f "${OPENSSL_TGZ}" ]; then
    if [ "${OFFLINE:-0}" = "1" ]; then
      echo "OFFLINE=1 and OpenSSL tarball missing." >&2
      echo "Expected either:" >&2
      echo "  - ${VENDORED_OPENSSL_TGZ}" >&2
      echo "  - ${BUILDDIR}/${OPENSSL_TGZ}" >&2
      exit 2
    fi

    echo "Fetching OpenSSL source tarball: ${OPENSSL_TGZ}"
    fetchUrl "https://www.openssl.org/source/openssl-${OpenSSL_VERSION}.tar.gz" "${OPENSSL_TGZ}" || {
      echo "Fetch failed; removing partial tarball." >&2
      rm -f "${OPENSSL_TGZ}" || true
      exit 1
    }
  fi

  # 3) Populate repo cache if it isn't already present
  if [ -f "${OPENSSL_TGZ}" ] && [ ! -f "${VENDORED_OPENSSL_TGZ}" ]; then
    echo "Populating cache: ${VENDORED_OPENSSL_TGZ}"
    cp -f "${OPENSSL_TGZ}" "${VENDORED_OPENSSL_TGZ}"
  fi

  # 4) Extract into build dir
  echo "Unpacking OpenSSL source: ${OPENSSL_TGZ}"
  tar -xf "${OPENSSL_TGZ}"
  if [ ! -d "${OPENSSL_SRC}" ]; then
    echo "Expected extracted directory '${OPENSSL_SRC}' not found after unpack." >&2
    exit 1
  fi
}

ensure_openssl_source

# --------------------------------------------------------------------------------------
# Build function
# --------------------------------------------------------------------------------------

# Accumulators used for universal (mac/ios) lipo builds
CRYPTO_LIBS="${CRYPTO_LIBS:-}"
SSL_LIBS="${SSL_LIBS:-}"

buildOpenSSL() {
  local PLATFORM="$1"
  local ARCH="$2"
  local SUBPLATFORM="${3:-}"

  local CONFIGURE_CC_FOR_TARGET=1
  local SPEC=""
  local EXTRA_OPTIONS=""
  local NAME=""
  local PLATFORM_NAME=""

  case "${PLATFORM}" in
    mac)
      if [ "${ARCH}" = "x86_64" ] || [ "${ARCH}" = "ppc64" ]; then
        SPEC="darwin64-${ARCH}-cc"
      else
        SPEC="darwin-${ARCH}-cc"
      fi
      ;;
    linux)
      if [ "${ARCH}" = "x86_64" ]; then
        SPEC="linux-x86_64"
      elif [[ "${ARCH}" =~ (x|i[3-6])86 ]]; then
        SPEC="linux-x86"
      elif [ "${ARCH}" = "arm64" ]; then
        SPEC="linux-aarch64"
      elif [[ "${ARCH}" =~ .*64 ]]; then
        SPEC="linux-generic64"
      else
        SPEC="linux-generic32"
      fi
      ;;
    android)
      configureAndroidToolchain "${ARCH}"
      export ANDROID_NDK_HOME="${ANDROID_TOOLCHAIN_BASE}"
      export PATH="${ANDROID_NDK_HOME}/bin:${PATH}"
      CONFIGURE_CC_FOR_TARGET=0

      if [ "${ARCH}" = "x86_64" ]; then
        SPEC="android-x86_64"
      elif [[ "${ARCH}" =~ (x|i[3-6])86 ]]; then
        # Work around linker crash (historical)
        export CFLAGS="${CFLAGS:-} -fuse-ld=bfd"
        SPEC="android-x86"
      elif [ "${ARCH}" = "arm64" ]; then
        export CFLAGS="${CFLAGS:-} -fno-integrated-as"
        SPEC="android-arm64"
      elif [[ "${ARCH}" =~ armv(6|7) ]]; then
        export CFLAGS="${CFLAGS:-} -fno-integrated-as"
        EXTRA_OPTIONS="-latomic"
        SPEC="android-arm"
      elif [[ "${ARCH}" =~ .*64 ]]; then
        SPEC="android64"
      else
        SPEC="android"
      fi
      ;;
    ios)
      if [ "${ARCH}" = "x86_64" ]; then
        SPEC="darwin64-x86_64-cc"
      else
        SPEC="iphoneos-cross"
      fi
      ;;
    *)
      echo "Unsupported PLATFORM='${PLATFORM}'" >&2
      exit 1
      ;;
  esac

  if [ -n "${SUBPLATFORM}" ]; then
    NAME="${PLATFORM}/${ARCH}/${SUBPLATFORM}"
    PLATFORM_NAME="${SUBPLATFORM}"
  else
    NAME="${PLATFORM}/${ARCH}"
    PLATFORM_NAME="${PLATFORM}"
  fi

  # Custom OpenSSL spec name to inherit + tweak
  local CUSTOM_SPEC="livecode_${SPEC}"

  # Per-target duplicated source tree (avoid cross-arch collisions)
  local OPENSSL_ARCH_SRC="${OPENSSL_SRC}-${PLATFORM_NAME}-${ARCH}"

  # Install prefix for this build
  local PREFIX="${INSTALL_DIR}/${NAME}"

  local OPENSSL_ARCH_CONFIG="no-rc5 no-hw no-threads shared -DOPENSSL_NO_ASYNC=1 --prefix=${PREFIX} ${CUSTOM_SPEC} ${EXTRA_OPTIONS}"

  if [ ! -d "${OPENSSL_ARCH_SRC}" ]; then
    echo "Duplicating OpenSSL source directory for ${NAME}"
    cp -R "${OPENSSL_SRC}" "${OPENSSL_ARCH_SRC}"
  fi

  local OPENSSL_ARCH_CURRENT_CONFIG=""
  if [ -f "${OPENSSL_ARCH_SRC}/config.cmd" ]; then
    OPENSSL_ARCH_CURRENT_CONFIG="$(cat "${OPENSSL_ARCH_SRC}/config.cmd")"
  fi

  if [ "${OPENSSL_ARCH_CONFIG}" != "${OPENSSL_ARCH_CURRENT_CONFIG}" ]; then
    cd "${OPENSSL_ARCH_SRC}"

    mkdir -p Configurations

    # Define a custom target that inherits from the selected SPEC but adds EXPORT_VAR_AS_FN
    cat > Configurations/99-livecode.conf <<EOF
my %targets = (
"${CUSTOM_SPEC}" => {
  inherit_from => [ "${SPEC}" ],
  bn_ops => add("EXPORT_VAR_AS_FN"),
},
);
EOF

    if [ "${CONFIGURE_CC_FOR_TARGET}" -ne 0 ]; then
      setCCForTarget "${PLATFORM}" "${ARCH}" "${SUBPLATFORM}"
    fi

    echo "Configuring OpenSSL for ${NAME}"
    ./Configure ${OPENSSL_ARCH_CONFIG}

    # iOS device build tweak (fixes original typo: "i386 " -> "i386")
    if [ "${PLATFORM}" = "ios" ] && [ "${ARCH}" != "i386" ]; then
      sed -i "" -e "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c" || true
    fi

    # iOS SDKs don't work with makedepend
    if [ "${PLATFORM}" = "ios" ]; then
      sed -i "" -e "s/MAKEDEPPROG=makedepend/MAKEDEPPROG=\$\(CC\) -M/" Makefile || true
    fi

    echo "Building OpenSSL for ${NAME}"
    make clean
    make depend
    make ${MAKEFLAGS:-}
    make install_sw

    echo "${OPENSSL_ARCH_CONFIG}" > "config.cmd"

    cd "${BUILDDIR}"
  else
    echo "Found existing OpenSSL build for ${NAME}"
  fi

  # Stage / collect libs
  if [ "${PLATFORM}" = "mac" ] || [ "${PLATFORM}" = "ios" ]; then
    CRYPTO_LIBS+="${PREFIX}/lib/libcrypto.a "
    SSL_LIBS+="${PREFIX}/lib/libssl.a "
  else
    mkdir -p "${OUTPUT_DIR}/lib/${NAME}"
    cp -f "${PREFIX}/lib/libcrypto.a" "${OUTPUT_DIR}/lib/${NAME}/libcustomcrypto.a"
    cp -f "${PREFIX}/lib/libssl.a"    "${OUTPUT_DIR}/lib/${NAME}/libcustomssl.a"
  fi

  # Stage headers into output include
  mkdir -p "${OUTPUT_DIR}/include"
  rm -rf "${OUTPUT_DIR}/include/openssl"
  cp -R "${PREFIX}/include/openssl" "${OUTPUT_DIR}/include/openssl"
}

# --------------------------------------------------------------------------------------
# Entry / orchestration
# --------------------------------------------------------------------------------------

# Expectations:
# - PLATFORM, ARCH, SUBPLATFORM are set by caller (build-thirdparty.sh / build-libraries.sh).
# - OUTPUT_DIR and INSTALL_DIR are set by platform.inc or caller.
PLATFORM="${PLATFORM:-${1:-}}"
ARCH="${ARCH:-${2:-}}"
SUBPLATFORM="${SUBPLATFORM:-${3:-}}"

if [ -z "${PLATFORM}" ] || [ -z "${ARCH}" ]; then
  echo "Usage: build-openssl.sh <platform> <arch|universal> [subplatform]" >&2
  exit 2
fi

# Fallback output/install dirs if not provided by platform.inc
OUTPUT_DIR="${OUTPUT_DIR:-${BASEDIR}}"
INSTALL_DIR="${INSTALL_DIR:-${BUILDDIR}/install}"

mkdir -p "${INSTALL_DIR}"
mkdir -p "${OUTPUT_DIR}"

if [ "${ARCH}" = "universal" ]; then
  # Perform build for each arch then lipo into universal libs
  for UARCH in ${UNIVERSAL_ARCHS}; do
    buildOpenSSL "${PLATFORM}" "${UARCH}" "${SUBPLATFORM}"
  done

  echo "Creating OpenSSL universal libraries for ${PLATFORM}"
  mkdir -p "${OUTPUT_DIR}/lib/${PLATFORM}"

  # prebuilt/libopenssl.gyp expects mac libs at lib/mac/libcustom*.a
  if [ "${PLATFORM}" = "mac" ]; then
    mkdir -p "${OUTPUT_DIR}/lib/mac"
    lipo -create ${CRYPTO_LIBS} -output "${OUTPUT_DIR}/lib/mac/libcustomcrypto.a"
    lipo -create ${SSL_LIBS}    -output "${OUTPUT_DIR}/lib/mac/libcustomssl.a"
  else
    # iOS gyp expects lib/ios/$(SDK_NAME)/libcustom*.a (SUBPLATFORM usually maps to SDK_NAME)
    mkdir -p "${OUTPUT_DIR}/lib/ios/${SUBPLATFORM}"
    lipo -create ${CRYPTO_LIBS} -output "${OUTPUT_DIR}/lib/ios/${SUBPLATFORM}/libcustomcrypto.a"
    lipo -create ${SSL_LIBS}    -output "${OUTPUT_DIR}/lib/ios/${SUBPLATFORM}/libcustomssl.a"
  fi

  CRYPTO_LIBS=""
  SSL_LIBS=""
else
  buildOpenSSL "${PLATFORM}" "${ARCH}" "${SUBPLATFORM}"

  # Stage mac single-arch outputs using canonical names expected by prebuilt/libopenssl.gyp
  if [ "${PLATFORM}" = "mac" ]; then
    local_name="${PLATFORM}/${ARCH}"
    mkdir -p "${OUTPUT_DIR}/lib/mac"
    cp -f "${INSTALL_DIR}/${local_name}/lib/libcrypto.a" "${OUTPUT_DIR}/lib/mac/libcustomcrypto.a"
    cp -f "${INSTALL_DIR}/${local_name}/lib/libssl.a"    "${OUTPUT_DIR}/lib/mac/libcustomssl.a"
  fi
fi

# Always stage headers into prebuilt/include/openssl (canonical consumer path)
STAGE_INC_DIR="${BASEDIR}/include"
mkdir -p "${STAGE_INC_DIR}"

# Source headers come from the install prefix for this PLATFORM/ARCH
# (for universal builds, headers are effectively the same; choose the last built arch)
if [ "${ARCH}" = "universal" ]; then
    # Use the last arch in UNIVERSAL_ARCHS as the source of headers
    LAST_ARCH=""
    for a in ${UNIVERSAL_ARCHS}; do LAST_ARCH="$a"; done
    HDR_NAME="${PLATFORM}/${LAST_ARCH}${SUBPLATFORM:+/${SUBPLATFORM}}"
else
    HDR_NAME="${PLATFORM}/${ARCH}${SUBPLATFORM:+/${SUBPLATFORM}}"
fi

rm -rf "${STAGE_INC_DIR}/openssl"
cp -R "${INSTALL_DIR}/${HDR_NAME}/include/openssl" "${STAGE_INC_DIR}/openssl"

echo "OpenSSL build complete."
