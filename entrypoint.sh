#!/bin/sh
set -eu

BIN_DIR="${SNELL_BIN_DIR:-/opt/snell/bin}"
CACHE_DIR="${SNELL_CACHE_DIR:-/opt/snell/cache}"
BIN_PATH="${BIN_DIR}/snell-server"
URL_MARKER="${CACHE_DIR}/download-url"
CONFIG_PATH="${SNELL_CONFIG_PATH:-/etc/snell-server.conf}"
DOWNLOAD_URL="${SNELL_DOWNLOAD_URL:-}"

if [ -z "${DOWNLOAD_URL}" ]; then
  DOWNLOAD_URL="${SNELL_URL:-}"
fi

download_snell() {
  if [ -z "${DOWNLOAD_URL}" ]; then
    echo "SNELL_DOWNLOAD_URL or SNELL_URL is required, for example https://dl.nssurge.com/snell/snell-server-v5.0.1-linux-amd64.zip" >&2
    exit 1
  fi

  mkdir -p "${BIN_DIR}" "${CACHE_DIR}"

  current_url=""
  if [ -f "${URL_MARKER}" ]; then
    current_url="$(cat "${URL_MARKER}")"
  fi

  if [ -x "${BIN_PATH}" ] && [ "${current_url}" = "${DOWNLOAD_URL}" ]; then
    return 0
  fi

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT INT TERM

  curl -fsSL --retry 3 --retry-delay 2 -o "${tmp_dir}/snell.zip" "${DOWNLOAD_URL}"
  unzip -q "${tmp_dir}/snell.zip" -d "${tmp_dir}/unpacked"

  downloaded_bin="$(find "${tmp_dir}/unpacked" -type f \( -name 'snell-server' -o -name 'snell-server-*' \) | head -n 1)"
  if [ -z "${downloaded_bin}" ]; then
    echo "Could not find snell-server binary in downloaded archive." >&2
    exit 1
  fi

  install -m 0755 "${downloaded_bin}" "${BIN_PATH}"
  printf '%s' "${DOWNLOAD_URL}" > "${URL_MARKER}"
  rm -rf "${tmp_dir}"
  trap - EXIT INT TERM
}

check_config() {
  if [ ! -r "${CONFIG_PATH}" ]; then
    echo "Snell config is not readable: ${CONFIG_PATH}" >&2
    echo "Mount your config file, for example ./config/snell.conf:/etc/snell-server.conf:ro" >&2
    exit 1
  fi
}

download_snell
check_config

exec "${BIN_PATH}" -c "${CONFIG_PATH}" "$@"
