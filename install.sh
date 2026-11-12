#!/usr/bin/env bash
# ==============================================================================
# QueryDock macOS One-Line Installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Novus-Lab-Dev/querydock-releases/main/install.sh | bash
# ==============================================================================

set -e

REPO="Novus-Lab-Dev/querydock-releases"
APP_NAME="QueryDock"
INSTALL_DIR="/Applications"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}QueryDock macOS Installer${RESET}"
echo "=================================================="

# Check OS
if [[ "$(uname)" != "Darwin" ]]; then
  echo -e "${RED}Error: This install script is designed for macOS only.${RESET}"
  exit 1
fi

# Detect architecture
ARCH="$(uname -m)"
echo -e "Detected Architecture: ${BOLD}${ARCH}${RESET}"

# Fetch latest release data from GitHub
echo -e "Checking for latest release from ${BOLD}github.com/${REPO}${RESET}..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)

DMG_URL=""
if [[ -n "$RELEASE_JSON" ]]; then
  # Try to find universal dmg first, fallback to arch specific or any dmg
  DMG_URL=$(echo "$RELEASE_JSON" | grep -o 'https://[^"]*universal\.dmg' | head -n 1 || true)
  if [[ -z "$DMG_URL" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
      DMG_URL=$(echo "$RELEASE_JSON" | grep -o 'https://[^"]*aarch64\.dmg' | head -n 1 || true)
    else
      DMG_URL=$(echo "$RELEASE_JSON" | grep -o 'https://[^"]*x64\.dmg' | head -n 1 || true)
    fi
  fi
  if [[ -z "$DMG_URL" ]]; then
    DMG_URL=$(echo "$RELEASE_JSON" | grep -o 'https://[^"]*\.dmg' | head -n 1 || true)
  fi
fi

# Fallback if the API is rate-limited: resolve the latest tag from the
# github.com/<repo>/releases/latest redirect instead of hardcoding a version.
if [[ -z "$DMG_URL" ]]; then
  LATEST_URL=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest" 2>/dev/null || true)
  TAG="${LATEST_URL##*/tag/}"
  if [[ -z "$LATEST_URL" || "$TAG" == "$LATEST_URL" ]]; then
    echo -e "${RED}Error: Could not find a QueryDock release at github.com/${REPO}.${RESET}"
    echo -e "If the repository is private, the installer cannot download it anonymously."
    exit 1
  fi
  VERSION="${TAG#v}"
  DMG_URL="https://github.com/${REPO}/releases/download/${TAG}/QueryDock_${VERSION}_universal.dmg"
fi

TMP_DIR=$(mktemp -d)
DMG_PATH="$TMP_DIR/QueryDock.dmg"

cleanup() {
  if [[ -d "$TMP_DIR" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

echo -e "Downloading QueryDock DMG from:"
echo -e "  ${YELLOW}${DMG_URL}${RESET}"

if ! curl -fL --progress-bar "$DMG_URL" -o "$DMG_PATH"; then
  echo -e "${RED}Failed to download from ${DMG_URL}.${RESET}"
  echo -e "Please ensure a release asset exists for your architecture."
  exit 1
fi

echo -e "Mounting disk image..."
MOUNT_POINT=$(hdiutil attach -nobrowse -noautoopen "$DMG_PATH" | grep -o '/Volumes/.*' | head -n 1)

if [[ -z "$MOUNT_POINT" || ! -d "$MOUNT_POINT" ]]; then
  echo -e "${RED}Error: Failed to mount disk image.${RESET}"
  exit 1
fi

SOURCE_APP=$(find "$MOUNT_POINT" -maxdepth 2 -name "${APP_NAME}.app" | head -n 1)

if [[ -z "$SOURCE_APP" || ! -d "$SOURCE_APP" ]]; then
  echo -e "${RED}Error: Could not find ${APP_NAME}.app inside the DMG.${RESET}"
  hdiutil detach "$MOUNT_POINT" -quiet || true
  exit 1
fi

# Use sudo only when /Applications (or the existing app) isn't writable
SUDO=""
if [[ ! -w "$INSTALL_DIR" ]] || { [[ -e "$TARGET_APP" ]] && [[ ! -w "$TARGET_APP" ]]; }; then
  echo -e "${YELLOW}Administrator access is needed to write to ${INSTALL_DIR}.${RESET}"
  SUDO="sudo"
fi

echo -e "Installing into ${BOLD}${TARGET_APP}${RESET}..."
if [[ -d "$TARGET_APP" ]]; then
  echo -e "Replacing existing ${APP_NAME}.app..."
  $SUDO rm -rf "$TARGET_APP"
fi

$SUDO cp -R "$SOURCE_APP" "$TARGET_APP"

echo -e "Unmounting disk image..."
hdiutil detach "$MOUNT_POINT" -quiet || true

# Strip quarantine attribute to guarantee smooth launching
echo -e "Clearing Gatekeeper quarantine attribute..."
$SUDO xattr -cr "$TARGET_APP" 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}✨ QueryDock installed successfully!${RESET}"
echo -e "You can find it in your ${BOLD}/Applications${RESET} folder or Spotlight."
echo ""

# Optional: ask to launch. Under `curl | bash` stdin is the script itself,
# so read the answer from the terminal; skip the prompt if there is none.
if { exec 3</dev/tty; } 2>/dev/null; then
  read -u 3 -p "Would you like to open QueryDock now? [Y/n] " -n 1 -r || REPLY=""
  exec 3<&-
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    open -a "$TARGET_APP"
  fi
fi

