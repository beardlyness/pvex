#!/usr/bin/env bash
#===============================================================================================================================================
#
# Licensed under the GNU GENERAL PUBLIC LICENSE, Version 3.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.gnu.org/licenses/gpl-3.0.en.html
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#===============================================================================================================================================
# title            :PVEX.sh
# description      :This script will make it super easy to setup a Proxmox HyperVisor Server with selected Addons.
# contributors     :beard
# date             :10-20-2021
# version          :0.0.1 Alpha
# os               :Debian (Bullseye - 11)
# usage            :bash pvex.sh
# notes            :If you have any questions email the maintainer: projects [AT] hacked [DOT] is
#===============================================================================================================================================

# Force check for root access
  if ! [[ "$(id -u)" = 0 ]]; then
    echo "You need to be root to run this script.."
    exit 1
  fi

  # Colors for tput
    red=$(tput setaf 1)
    green=$(tput setaf 2)
    yellow=$(tput setaf 3)
    blue=$(tput setaf 4)
    magenta=$(tput setaf 5)
    cyan=$(tput setaf 6)
    white=$(tput setaf 7)

  # Functions for tput
    reset=$(tput sgr0)
    blink=$(tput blink)
    bold=$(tput bold)
    reverse=$(tput rev)
    underline=$(tput smul)


# Grabing info on machine
  flavor=$(lsb_release -cs)
  system=$(lsb_release -i | grep "Distributor ID:" | sed 's/Distributor ID://g' | awk '{print tolower($1)}')


# Path Mapping in Script
  # Main Download URL
  PVE_URL="deb http://download.proxmox.com/debian/pve $flavor pve-no-subscription"

  # URL for the Debian 11\Bullseye Key for Proxmox
  PVE_KEY="https://enterprise.proxmox.com/debian/proxmox-release-bullseye.gpg"
  
  # Where Trusted Keys are stored
  KEYS_DIR="/etc/apt/trusted.gpg.d"
  
  # Debian 11\Bullseye Key for Proxmox
  KEY_VER="proxmox-release-bullseye.gpg"

  # Where added Sources are kept
  SOURCES_DIR="/etc/apt/sources.list.d"


# Function's for the Script
  # Keeps the System up to date
    function upkeep() {
        echo """${cyan}""""${bold}""Performing upkeep of system..""${reset}"""
        apt-get update -y
        apt-get full-upgrade -y
        apt-get dist-upgrade -y
        apt-get clean -y
    }

  # Grabs Machines IP Address
    function getIP() {
        hostname --ip-address
    }

  # Function for Proxmox Setup
    function pve_setup() {
        echo """$PVE_URL""" > "$SOURCES_DIR"/pve-install-repo.list
        wget "$PVE_KEY" -O "$KEYS_DIR"/"$KEY_VER"
        chmod +r "$KEYS_DIR"/"$KEY_VER"
    }

  # Function for Proxmox Install
    function pve_install() {
        apt-get purge exim* postfix*
        apt-get install proxmox-ve postfix open-iscsi -y
    }

  # Function for after install clean-up of PVE 
    function pve_cleanup() {
        apt remove os-prober
        rm /etc/apt/sources.list.d/pve-enterprise.list
        apt remove linux-image-amd64 'linux-image-5.10*'
        update-grub
    }

  # Function for NetData Setup & Install
    function netdata_setup() {
        bash <(curl -Ss https://my-netdata.io/kickstart.sh)
    }

  # Function for SpeedTest CLI Setup & Install
    function speedtest_setup() {
        bash <(curl -Ss https://install.speedtest.net/app/cli/install.deb.sh)
        apt-get install speedtest -y
    }

  # Installing key software to help
    tools=( lsb-release wget curl apt-transport-https ca-certificates )
      grab_eware=""
        for e in "${tools[@]}"; do
          if command -v "$e" > /dev/null 2>&1; then
            echo """${green}""""${bold}""Dependency $e is installed..""${reset}"""
          else
            echo """${red}""""${bold}""Dependency $e is not installed..""${reset}"""
            upkeep
            grab_eware="$grab_eware $e"
          fi
        done
      apt-get install $grab_eware

# Proxmox Setup
    # CASE Statement for Proxmox Setup and Install
      read -r -p """${cyan}""""${bold}""Do you want to setup the latest Proxmox Version for your "$system" install of "$flavor"? (Y/Yes | N/No) ""${reset}""" REPLY
        case "${REPLY,,}" in
          [yY]|[yY][eE][sS])
                nano /etc/hosts
                getIP
                pve_setup
                upkeep
                pve_install
                pve_cleanup
            ;;
          [nN]|[nN][oO])
              echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
            ;;
          *)
            echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
            ;;
      esac


# NetData Setup
    # CASE Statement for NetData Setup and Install
      read -r -p """${cyan}""""${bold}""Do you want to setup and install NetData to help monitor the system, and its resources? (Y/Yes | N/No) ""${reset}""" REPLY
        case "${REPLY,,}" in
          [yY]|[yY][eE][sS])
                netdata_setup
            ;;
          [nN]|[nN][oO])
              echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
            ;;
          *)
            echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
            ;;
      esac


# SpeedTest Setup
    # CASE Statement for SpeedTest Setup and Install
      read -r -p """${cyan}""""${bold}""Do you want to setup and install SpeedTest to help monitor your Bandwidth? (Y/Yes | N/No) ""${reset}""" REPLY
        case "${REPLY,,}" in
          [yY]|[yY][eE][sS])
                speedtest_setup
            ;;
          [nN]|[nN][oO])
              echo """${red}""""${bold}""You have said no? We cannot work without your permission!""${reset}"""
            ;;
          *)
            echo """${yellow}""""${bold}""Invalid response. You okay?""${reset}"""
            ;;
      esac


# Fast System Shutdown
    echo """${red}""""${bold}""Rebooting now in order for changes to take place. Please standby.....""${blink}""""${reset}"""
        shutdown -r now
