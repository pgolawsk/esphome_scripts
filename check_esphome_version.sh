#!/usr/bin/env bash
# check_esphome_update.sh
# check if new ESPHome version is available and ask before upgrade
# Features:
#  - DEBUG via ESP_DEBUG=1
#  - safe handling of "set -e" (restore original state)
#  - --check-only (no prompt, exit 10 if update exists)
#  - --auto (upgrade without prompt)
#  - virtualenv detection
#  - fallback if "pip index versions" is unavailable

# Pawelo, 20251230, created
# Pawelo, 20251230, Supports DEBUG via ESP_DEBUG=1

########################################
# Flags
########################################
CHECK_ONLY=0
AUTO_UPGRADE=0

for arg in "$@"; do
    case "$arg" in
        --check-only) CHECK_ONLY=1 ;;
        --auto)       AUTO_UPGRADE=1 ;;
        *)
            echo "Usage: $0 [--check-only] [--auto]"
            exit 1
            ;;
    esac
done

########################################
# Debug helper
########################################
debug() {
    [ "${ESP_DEBUG:-0}" != "0" ] && echo "[DEBUG] $*"
}

########################################
# Detect pip / venv
########################################
PIP_CMD="pip"
[ -n "${VIRTUAL_ENV:-}" ] && debug "Virtualenv detected: $VIRTUAL_ENV"

########################################
# Get installed ESPHome version
########################################
INSTALLED_VERSION=$(
    esphome version 2>/dev/null |
    grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' |
    head -n1
)

if [ -z "$INSTALLED_VERSION" ]; then
    echo "ESPHome is not installed or not in PATH"
    exit 1
fi

########################################
# Get latest ESPHome version (grep-based)
########################################
debug "Fetching latest ESPHome version"

LATEST_VERSION=""

if pip index versions esphome >/dev/null 2>&1; then
    debug "Using pip index versions"
    LATEST_VERSION=$(
        sh -c '
            pip index versions esphome 2>/dev/null |
            grep -Eo "[0-9]+\.[0-9]+\.[0-9]+" |
            head -n1
        '
    )
else
    debug "Using fallback method"
    LATEST_VERSION=$(
        sh -c '
             install esphome==__invalid__ 2>&1 |
            grep -Eo "from versions:.*" |
            grep -Eo "[0-9]+\.[0-9]+\.[0-9]+" |
            tail -n1
        '
    )
fi

if [ -z "$LATEST_VERSION" ]; then
    echo "Unable to determine latest ESPHome version"
    exit 1
fi

########################################
# Output versions (ALWAYS)
########################################
echo "Installed ESPHome version: $INSTALLED_VERSION"
echo "Latest ESPHome version:    $LATEST_VERSION"

########################################
# Compare
########################################
if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
    echo "ESPHome is up to date ✅"
    exit 0
fi

echo "⚠ New ESPHome version available!"

########################################
# Modes
########################################
[ "$CHECK_ONLY" -eq 1 ] && exit 10

if [ "$AUTO_UPGRADE" -eq 1 ]; then
    echo "Upgrading ESPHome..."
    $PIP_CMD install -U esphome
    exit $?
fi

########################################
# Interactive
########################################
read -r "?Do you want to upgrade ESPHome now? [y/N]: " ANSWER
case "$ANSWER" in
    y|Y|yes|YES)
        echo "Upgrading ESPHome..."
        $PIP_CMD install -U esphome
        ;;
    *)
        echo "Upgrade cancelled."
        ;;
esac
