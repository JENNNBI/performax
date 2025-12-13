#!/bin/bash

# Mirror BoringSSL's private crypto headers into the generated framework so
# clang can resolve the relative includes (e.g. "internal.h") found inside the
# *.c.inc fragments. This runs inside the CocoaPods build and relies on the
# standard environment variables injected by Xcode.

set -euo pipefail

if [[ -z "${PODS_TARGET_SRCROOT:-}" || -z "${CONFIGURATION_BUILD_DIR:-}" ]]; then
  echo "Missing required Xcode environment variables. Skipping."
  exit 0
fi

FRAMEWORK_HEADERS_DIR="${CONFIGURATION_BUILD_DIR}/BoringSSL-GRPC/openssl_grpc.framework/Headers"
SOURCE_CRYPTO_DIR="${PODS_TARGET_SRCROOT}/src/crypto"

if [[ ! -d "${SOURCE_CRYPTO_DIR}" ]]; then
  echo "BoringSSL source directory not found at ${SOURCE_CRYPTO_DIR}"
  exit 0
fi

mkdir -p "${FRAMEWORK_HEADERS_DIR}/crypto"
rsync -a --delete "${SOURCE_CRYPTO_DIR}/" "${FRAMEWORK_HEADERS_DIR}/crypto/"

SOURCE_THIRD_PARTY_DIR="${PODS_TARGET_SRCROOT}/src/third_party"
if [[ -d "${SOURCE_THIRD_PARTY_DIR}" ]]; then
  mkdir -p "${FRAMEWORK_HEADERS_DIR}/third_party"
  rsync -a --delete "${SOURCE_THIRD_PARTY_DIR}/" "${FRAMEWORK_HEADERS_DIR}/third_party/"
fi

