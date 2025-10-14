#!/usr/bin/env bash
###
# File: eduroam-ncmli.sh
# Author: Leopold Meinel (leo@meinel.dev)
# -----
# Copyright (c) 2025 Leopold Meinel & contributors
# SPDX ID: GPL-3.0-or-later
# URL: https://www.gnu.org/licenses/gpl-3.0-standalone.html
# -----
###

# This script is heavily inspired by: https://git.uni-greifswald.de/URZ-Public/easyroam/src/branch/main/configure-eduroam-with-easyroam

# Fail on error
set -e

# Define functions
log_err() {
    /usr/bin/logger -s -p local0.err <<<"$(basename "${0}"): ${*}"
}
log_warning() {
    /usr/bin/logger -s -p local0.warning <<<"$(basename "${0}"): ${*}"
}
cert_bundle_err_exit() {
    log_err "Certificate bundle '${1}' is invalid or openssl exited unexpectedly."
    exit 1
}
print_help() {
    echo "Usage: $(basename "${0}") [pkcs12 certificate bundle]"
    echo ""
    echo "Configure eduroam with nmcli and a pkcs12 certificate bundle"
    echo ""
    echo "Parameters:"
    echo "    [pkcs12 certificate bundle]  Path to certificate bundle, fex. '~/Downloads/example.p12'"
}

# Check ${EUID} and parameter
if [[ "${EUID}" -ne 0 ]]; then
    log_err "You can only run this script as root."
    exit 1
fi
if [[ -f "${1}" ]]; then
    log_err "Please specify a valid pkcs12 certificate bundle."
    print_help
    exit 1
fi

# Check if network configuration is valid
if [[ -z "$(iw dev)" ]]; then
    log_err "No WiFi device detected."
    exit 1
fi
if [[ -z "$(which nmcli)" ]]; then
    log_err "No 'nmcli' command found."
    exit 1
fi

# Check if we are using openssl >=3
OPENSSL_OPTIONS=""
[[ "$(openssl -v | awk '{print $2}' | cut -d '.' -f1)" -ge 3 ]] &&
    OPENSSL_OPTIONS="-legacy"

# Generate certificates
## Create ${CERT_DIR}
CERT_DIR=/etc/eduroam-certs
mkdir -p "${CERT_DIR}"
## Generate client_certs and ca_certs
CERT_BUNDLE="${1}"
openssl pkcs12 -in "${CERT_BUNDLE}" ${OPENSSL_OPTIONS} -passin pass: -nokeys -clcerts -out "${CERT_DIR}"/client_certs.pem ||
    cert_bundle_err_exit "${CERT_BUNDLE}"
openssl pkcs12 -in "${CERT_BUNDLE}" ${OPENSSL_OPTIONS} -passin pass: -nokeys -cacerts -out "${CERT_DIR}"/ca_certs.pem ||
    cert_bundle_err_exit "${CERT_BUNDLE}"
## Generate client_key encrypted with ${PASSPHRASE}
PASSPHRASE="$(head -c 1280 /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 128)"
openssl pkcs12 -in "${CERT_BUNDLE}" ${OPENSSL_OPTIONS} -passin pass: -passout pass:"${PASSPHRASE}" -nocerts -out "${CERT_DIR}"/client_key.pem ||
    cert_bundle_err_exit "${CERT_BUNDLE}"

# Add nmcli connection for ${WIFI_NAME}
WIFI_NAME="eduroam"
IDENTITY="$(openssl x509 -noout -in "${CERT_DIR}"/client_certs.pem -subject | awk '{print $1}' | sed 's/.*=//' | sed 's/,//' | tr -d "[:space:]")"
nmcli connection add type wifi con-name "${WIFI_NAME}" ssid "${WIFI_NAME}" -- wifi-sec.key-mgmt wpa-eap 802-1x.eap tls 802-1x.identity "${IDENTITY}" 802-1x.ca-cert "${CERT_DIR}"/ca_certs.pem 802-1x.client-cert "${CERT_DIR}"/client_certs.pem 802-1x.private-key-password "${PASSPHRASE}" 802-1x.private-key "${CERT_DIR}"/client_key.pem

# Notify user if script has finished successfully
echo "'$(basename "${0}")' has finished successfully."
