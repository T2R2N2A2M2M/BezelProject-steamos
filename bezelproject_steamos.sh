#!/usr/bin/env bash

# Define global env
DEFAULT_RETROARCH_DIR="${HOME}/.var/app/org.libretro.RetroArch/config/retroarch"

###############################################################################
# MAIN MENU
function main_menu() {
  echo "Welcome to The Bezel Project Bezel Utility for SteamOS."
  echo "This utility will provide a downloader for RetroArch system bezel packs."
  echo "These bezel packs rely on ROMs named according to No-Intro or similar sets."
  echo ""

  echo "Note that the bezel only fits properly with 16:9 aspect ratio resolution."
  echo "For Steam Deck users, In Gamemode, you can force your RetroArch or whatever frontend you use to force the game to lauch at 720p or 1080p resolution in the game property (e.g., this is where the steam lauch option located.) You also need to enable [Set resolution for the internal dand external display]."
  echo ""

  # Setting RetroArch config directory
  read -rp "Is your RetroArch configuration directory at [${DEFAULT_RETROARCH_DIR}]? (y/n): " user_choice

  case "$user_choice" in
  [Yy])
    # If user says "y" or "Y", use the default directory
    RETROARCH_CONFIG_DIR="$DEFAULT_RETROARCH_DIR"
    echo "Using default directory: $RETROARCH_CONFIG_DIR"
    ;;
  [Nn])
    # If user says "n" or "N", pull up a GUI to choose a folder
    chosen_dir="$(zenity --file-selection --directory --title="Select RetroArch config directory" --filename="$HOME/.var/")"

    # If the user cancels or closes the dialog, zenity returns a non-zero exit code
    if [[ $? -ne 0 ]]; then
      echo "Directory selection canceled. Exiting..."
      exit 1
    fi

    # Remove any trailing slash (so we don't end up with /path/to/dir/)
    chosen_dir="${chosen_dir%/}"
    RETROARCH_CONFIG_DIR="$chosen_dir"
    echo "Selected directory: $RETROARCH_CONFIG_DIR"
    ;;
  *)
    # If user enters anything other than y/n
    echo "Invalid input: $user_choice"
    exit 1
    ;;
  esac

  # Setting RetroArch overlays folder
  OVERLAY_DIR="${RETROARCH_CONFIG_DIR}/overlays"

  echo ""
  echo "Choose your option (1, or 2)"
  echo ""
  options=("Install Theme Style Bezel" "Cancel")

  select choice in "${options[@]}"; do
    case $choice in
    "Install Theme Style Bezel")
      clear
      download_bezel
      break
      ;;
    "Cancel")
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid option. Try again."
      ;;
    esac
  done

}

###############################################################################
# INSTALL / UNINSTALL HELPER FUNCTIONS

function install_bezel_pack() {
  local theme="$1"
  local repo="$2"
  [ -z "$repo" ] && repo="thebezelproject"
  echo "[INFO] Processing ${theme}..."

  # Clone the pack
  git clone --depth 1 "https://github.com/${repo}/bezelproject-${theme}.git" "/tmp/${theme}" 2>&1
  if [ "$?" != "0" ]; then
    echo "Error cloning the ${theme} pack. Check space or network."
    rm -rf "/tmp/${theme}"
    return
  fi

  # Modify .cfg references from RetroPie path to our $OVERLAY_DIR
  echo "[INFO] Generating config files for ${theme} games..."
  find "/tmp/${theme}/retroarch/config/" -type f -name "*.cfg" -print0 | while IFS= read -r -d '' file; do
    # Original scripts used /opt/retropie/configs/all/retroarch/overlay
    sed -i "s+/opt/retropie/configs/all/retroarch/overlay+${OVERLAY_DIR}+g" "$file"

    # other configs
    echo 'video_fullscreen = "true"' >> "$file"
    echo 'input_overlay_behind_menu = "true"' >> "$file"
    echo 'input_overlay_enable = "true"' >> "$file"
    echo 'input_overlay_hide_in_menu = "false"' >> "$file"
    echo 'input_overlay_opacity = "1.000000"' >> "$file"

  done

  echo "[INFO] Done generating config files for ${theme} games."

  # Backing up pre bezel installation retroarch.cfg
  RETROARCH_CONFIG="${RETROARCH_CONFIG_DIR}/retroarch.cfg"

  echo "[INFO] Backing up retroarch.cfg..."
  if [ ! -f "${RETROARCH_CONFIG}.prebezelproj.bak" ]; then
    cp "$RETROARCH_CONFIG" "${RETROARCH_CONFIG}.prebezelproj.bak"
  else
    echo "[INFO] Backup already exists"
  fi

  # Set the global retroarch.cfg overlay directory
  echo "[INFO] Set overlay directory to ${OVERLAY_DIR} in ${RETROARCH_CONFIG}"
  sed -i "/overlay_directory \=/c\overlay_directory \= \"${OVERLAY_DIR}\"" "${RETROARCH_CONFIG}"

  # Copy Overlays + Config
  echo "[INFO] Copying ${theme} overlays to ${OVERLAY_DIR}..."
  cp -r "/tmp/${theme}/retroarch/overlay/"* "${OVERLAY_DIR}/" 2>&1 |
    stdbuf -oL sed -E 's/\.\.+/---/g'
  echo "[INFO] Overlay copy complete."

  echo "[INFO] Copying ${theme} configs to ${RETROARCH_CONFIG_DIR}/config..."
  cp -r "/tmp/${theme}/retroarch/config/" "${RETROARCH_CONFIG_DIR}/" 2>&1 |
    stdbuf -oL sed -E 's/\.\.+/---/g'
  echo "[INFO] Config copy complete."

  # Cleanup temporary files
  echo "[INFO] Cleaning up temporary files..."
  rm -rf "/tmp/${theme}"
  echo "[INFO] Cleanup complete."

}

###############################################################################
# MENU FUNCTIONS - THEME STYLE (bezelproject-xxx) & SYSTEM STYLE (bezelprojectsa-xxx)

function download_bezel() {
  local themes=(
    'thebezelproject Amiga'
    'thebezelproject AmstradCPC'
    'thebezelproject Atari2600'
    'thebezelproject Atari5200'
    'thebezelproject Atari7800'
    'thebezelproject Atari800'
    'thebezelproject AtariJaguar'
    'thebezelproject AtariLynx'
    'thebezelproject AtariST'
    'thebezelproject Atomiswave'
    'thebezelproject C64'
    'thebezelproject CD32'
    'thebezelproject CDTV'
    'thebezelproject ColecoVision'
    'thebezelproject Dreamcast'
    'thebezelproject FDS'
    'thebezelproject Famicom'
    'thebezelproject GB'
    'thebezelproject GBA'
    'thebezelproject GBC'
    'thebezelproject GCEVectrex'
    'thebezelproject GameGear'
    'thebezelproject Intellivision'
    'thebezelproject MAME'
    'thebezelproject MSX'
    'thebezelproject MSX2'
    'thebezelproject MasterSystem'
    'thebezelproject MegaDrive'
    'thebezelproject N64'
    'thebezelproject NDS'
    'thebezelproject NES'
    'thebezelproject NGP'
    'thebezelproject NGPC'
    'thebezelproject Naomi'
    'thebezelproject PCE-CD'
    'thebezelproject PCEngine'
    'thebezelproject PSX'
    'thebezelproject SFC'
    'thebezelproject SG-1000'
    'thebezelproject SNES'
    'thebezelproject Saturn'
    'thebezelproject Sega32X'
    'thebezelproject SegaCD'
    'thebezelproject SuperGrafx'
    'thebezelproject TG-CD'
    'thebezelproject TG16'
    'thebezelproject Videopac'
    'thebezelproject Virtualboy'
    'thebezelproject X68000'
    'thebezelproject ZX81'
    'thebezelproject ZXSpectrum'
  )

  # Build Zenity's system checklist.
  local zenity_list_args=()
  for entry in "${themes[@]}"; do
    local systemName="${entry##* }"
    # uncheck all system initially
    zenity_list_args+=(FALSE "${systemName}")
  done

  local chosen_systems
  chosen_systems=$(zenity --list \
    --title="Select Theme-Style Bezel Packs" \
    --text="Select one or more systems to download or update." \
    --checklist \
    --column="Install?" \
    --column="System" \
    --separator="|" \
    --width=600 \
    --height=700 \
    "${zenity_list_args[@]}")

  # No selection
  if [ -z "$chosen_systems" ]; then
    return
  fi

  # Split the pipe-separated string into an array
  IFS="|" read -r -a selected_array <<<"$chosen_systems"

  # Install the bezel for selected systems
  for systemName in "${selected_array[@]}"; do
    install_bezel_pack "${systemName}" "thebezelproject"
    echo ""
  done


}

###############################################################################
# Main

clear
main_menu
echo "Exited The Bezel Project script."
