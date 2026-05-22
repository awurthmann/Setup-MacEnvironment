#!/bin/bash

# Written by: Aaron Wurthmann
#
# You the executor, runner, user accept all liability.
# This code comes with ABSOLUTELY NO WARRANTY.
# This is free and unencumbered software released into the public domain.
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# --------------------------------------------------------------------------------------------
# Name: Setup-MacEnvironment.sh
# Version: 2026.05.20.1200
# Description: Setup Mac Environment on my Test System(s)
#
# Instructions: Download Setup-MacEnvironment.sh
#                chmod +x ./Setup-MacEnvironment.sh
#                ./Setup-MacEnvironment.sh
#           OR
#               Copy/Paste the line below into shell (running WITH root/sudo privileges)
#               bash -c "$(curl -fsSL https://raw.githubusercontent.com/awurthmann/Setup-MacEnvironment/main/Setup-MacEnvironment.sh)"
#
# Tested with: macOS 15.5 (24F74)
#  system_profiler SPSoftwareDataType | awk -F 'System Version: ' '/System Version:/ {print $2}'
# Arguments: None
# Output: Standard Out, Info Log and Error Log files
#
# Notes:
#   I am considering adding https://github.com/clintmod/macprefs to save and reload prefferences.
# --------------------------------------------------------------------------------------------

###Functions
function wait_app_start () {
    appPath=$1
    checkMax=120

    appCheck=true
    checkCount=1

    if pgrep -f "$appPath" > /dev/null ; then
        appCheck=false
    fi

    while [ "$appCheck" = true ] ; do

        sleep 1.0
        if pgrep -f "$appPath" > /dev/null ; then
            appCheck=false
            break
        fi

        ((checkCount=checkCount+1))

        if [ $checkCount -ge $checkMax ] ; then
            appCheck=false
            return 1
        fi
    done
}

function wait_app_stop () {
    appPath=$1
    checkMax=7200

    appCheck=true
    checkCount=1

    if ! pgrep -f "$appPath" > /dev/null ; then
        appCheck=false
    fi

    while [ "$appCheck" = true ] ; do
        sleep 1.0
        if ! pgrep -f "$appPath" > /dev/null ; then
            appCheck=false
            break
        fi

        ((checkCount=checkCount+1))

        if [ $checkCount -ge $checkMax ] ; then
            appCheck=false
            return 1
        fi
    done
}

function log_and_color () {
    local files=()
    local color="COLOR_OFF"

    # Reset
    local COLOR_OFF='\033[0m'       # Text Reset

    # Regular Colors
    local BLACK='\033[0;30m'        # Black
    local RED='\033[0;31m'          # Red
    local GREEN='\033[0;32m'        # Green
    local YELLOW='\033[0;33m'       # Yellow
    local BLUE='\033[0;34m'         # Blue
    local PURPLE='\033[0;35m'       # Purple
    local CYAN='\033[0;36m'         # Cyan
    local WHITE='\033[0;37m'        # White

    while ! ${1+false}
    do case "$1" in
        -e|--error) color="red";;
        -i|--info) color="white";;
        -w|--warn) color="yellow";;
        -s|--success) color="green";;
        -c|--color) shift; color=$1 ;;
        -f|--file) shift; files+=("${1-}") ;;
        --) shift; break ;; # end of arguments
        -*) echo -e "log_and_color: invalid option '$1'"; return 1;;
        *) break ;; # start of message
        esac
        shift
    done

    #standard out in color
    case $color in
        BLACK|black ) echo -e "${BLACK}$*${COLOR_OFF}";;
        RED|red ) echo -e "${RED}$*${COLOR_OFF}";;
        GREEN|green ) echo -e "${GREEN}$*${COLOR_OFF}";;
        YELLOW|yellow ) echo -e "${YELLOW}$*${COLOR_OFF}";;
        BLUE|blue ) echo -e "${BLUE}$*${COLOR_OFF}";;
        PURPLE|purple ) echo -e "${PURPLE}$*${COLOR_OFF}";;
        CYAN|cyan ) echo -e "${CYAN}$*${COLOR_OFF}";;
        WHITE|white ) echo -e "${WHITE}$*${COLOR_OFF}";;
        * ) echo -e "${COLOR_OFF}$*${COLOR_OFF}";;
    esac
    #end standard out in color

    #append log file with time stamp
    echo -e "SH [$(date +"%T")]: $*" >> $logfile
}

function install_xcode () {
    echo
    echo "$(tput setaf 3)Ignore any errors above related to xcode-select"
    log_and_color -i -f $logfile "Running: xcode-select --install"

    xcode-select --install

    echo
    echo "$(tput setaf 3)NOTE:"
    echo "$(tput setaf 3)Install may take some time to download and complete"
    echo "$(tput setaf 3)This script will auto-exit, and will require restart, after 120 minutes"
    echo
    log_and_color -i -f $logfile "Waiting for Command Line Developer Tools install to start"
    wait_app_start "/System/Library/CoreServices/Install Command Line Developer Tools.app"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Command Line Developer Tools install started"
        log_and_color -i -f $logfile "Waiting for Command Line Developer Tools install to complete"
        wait_app_stop "/System/Library/CoreServices/Install Command Line Developer Tools.app"
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Command Line Developer Tools install completed"
            return 0
        else
            log_and_color -e -f $logfile "ERROR: Command Line Developer Tools install did not complete in the allotted time period"
            return 1
        fi
    else
        log_and_color -e -f $logfile "ERROR: Command Line Developer Tools install did not start in the allotted time period"
        return 1
    fi
}

function install_tool () {
    log_and_color -s -f $logfile "Starting install for: $1"
    brew install "$1"
    #&& log_and_color -s -f $logfile "$1 successfully installed" || log_and_color -e -f $logfile "ERROR: $1 install failed"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "$1 successfully installed"
    else
        log_and_color -e -f $logfile "ERROR: $1 install failed"
    fi
}

function install_app () {
    log_and_color -s -f $logfile "Starting install for: $1"
    brew install --cask "$1"
    #&& log_and_color -s -f $logfile "$1 successfully installed" || log_and_color -e -f $logfile "ERROR: $1 install failed"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "$1 successfully installed"
    else
        log_and_color -e -f $logfile "ERROR: $1 install failed"
    fi
}

function install_theharvester () {
    log_and_color -s -f $logfile "Starting install for TheHarvester"

    brew install theharvester
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "TheHarvester successfully installed"
        echo "export PATH=\$PATH:${HOMEBREW_PREFIX}/etc/theharvester" >> "$HOME/.zshrc"

        log_and_color -i -f $logfile "Starting Python PIP Upgrade"
        /Library/Developer/CommandLineTools/usr/bin/python3 -m pip install --upgrade pip
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "PIP Upgraded successfully"
        else
            log_and_color -e -f $logfile "ERROR: PIP Upgrade was unsuccessfull"
        fi
    else
        log_and_color -e -f $logfile "ERROR: TheHarvester was not installed. Exiting"
    fi
}

function install_wireshark () {
    log_and_color -s -f $logfile "Starting install for Wireshark"
    brew install wireshark
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Wireshark CLI was successfully installed"
        log_and_color -i -f $logfile "Starting Wireshark GUI Install"
        brew install --cask wireshark
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Wireshark GUI was successfully installed"
            log_and_color -i -f $logfile "Starting Wireshark macOS Hotfix Install"
            if brew install --cask wireshark-chmodbpf; then
                log_and_color -s -f $logfile "Wireshark macOS Hotfix was successfully installed"
            else
                log_and_color -e -f $logfile "ERROR: Wireshark macOS Hotfix install was unsuccessfull"
            fi
        else
            log_and_color -e -f $logfile "ERROR: Wireshark GUI install was unsuccessfull"
        fi
    else
        log_and_color -e -f $logfile "ERROR: Wireshark was not installed. Exiting"
    fi
}
###End Functions

#Set logfile
logfile=~/Documents/Setup-MacEnvironment.log
if [ ! -f "$logfile" ]; then touch $logfile; fi

##Start Message
echo;echo
echo "$(tput setaf 13)IMPORTANT NOTE:"
echo "$(tput setaf 12)This script may require several restarts of the script"
echo "$(tput setaf 12)or system reboots to fully complete. A log file is "
echo "$(tput setaf 12)located at: $logfile"
echo "$(tput setaf 12)Once the script has completed a message on the screen"
echo "$(tput setaf 12)and in the log will read: 'Setup script complete.'"
echo
##End Start Message

###Admin Check
if [ "$(whoami)" = "root" ]; then
    log_and_color -e -f $logfile "ERROR: This script must NOT be run as root or using sudo. Exiting"
    exit
fi
###End Admin Check

###Xcode Install
if ! xcode-select -p > /dev/null ; then
    echo
    install_xcode
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Command Line Developer Tools were successfully installed"
    else
        log_and_color -e -f $logfile "ERROR: Command Line Developer Tools are not installed. Exiting"
        exit
    fi
fi
###End Xcode Install

###Install Updates/OS Patches
if ! grep "Software update successfully completed" $logfile > /dev/null; then
	log_and_color -i -f $logfile "Running: softwareupdate --all --install --force"
	sudo softwareupdate --all --install --force
    #&& log_and_color -s -f $logfile "Software update successfully completed" || log_and_color -e -f $logfile "ERROR: Software update failed"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Software update successfully completed"
    else
        log_and_color -e -f $logfile "ERROR: Software update failed"
        exit
    fi
fi
###EndInstall Updates/OS Patches


### VIM Setup
# Download a canonical .vimrc from GitHub if one doesn't already exist
if [ ! -f "$HOME/.vimrc" ]; then
    log_and_color -i -f $logfile "Downloading .vimrc from GitHub"
    curl -fsSL https://raw.githubusercontent.com/awurthmann/Setup-MacEnvironment/refs/heads/main/.vimrc \
      -o "$HOME/.vimrc"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile ".vimrc downloaded successfully"
    else
        log_and_color -e -f $logfile "ERROR: Failed to download .vimrc"
    fi
fi
### End VIM Setup

# Detect Architecture and set Homebrew Prefix
if [[ "$(uname -m)" == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

### Homebrew Setup (Official Installer, Apple Silicon & Intel aware)
if ! command -v brew &> /dev/null; then
    log_and_color -i -f $logfile "Starting Homebrew Setup"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$("$HOMEBREW_PREFIX/bin/brew" shellenv)"
    brew update --force --quiet

    if ! grep -q "$HOMEBREW_PREFIX/bin" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> $HOME/.zshrc
        echo "# Added by $USER" >> $HOME/.zshrc
        echo "export PATH=\$PATH:${HOMEBREW_PREFIX}/bin" >> "$HOME/.zshrc"
    fi

    if ! command -v brew &> /dev/null; then
        log_and_color -e -f $logfile "ERROR: Homebrew was not installed. Exiting"
        exit
    fi
    log_and_color -s -f $logfile "Homebrew Setup Complete"
fi


###Homebrew Setup (non-admin post setupt script version)
# if [ ! -d $HOME/homebrew ]; then
#     log_and_color -i -f $logfile "Starting Homebrew Setup"
#     cd $HOME
#     mkdir homebrew
#     curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
#     eval "$(homebrew/bin/brew shellenv)"
#     brew update --force --quiet
#     chmod -R go-w "$(brew --prefix)/share/zsh"
#     export PATH=$PATH:$HOME/homebrew/bin
#     echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc
#     log_and_color -g -f $logfile "Homebrew Setup Complete"
# fi
###End Homebrew Setup (non-admin post install version)


###Shell Setup
if [ ! -d $HOME/.oh-my-zsh ]; then
    echo
	echo "$(tput setaf 5)ATTENTION: The oh-my-zsh installation will require a restart of this setup script"
    echo "$(tput setaf 6)Press any key to continue"
    read -r _

	log_and_color -w -f $logfile "oh-my-zsh setup stops this setup script during install. To complete setup, restart the script"
	log_and_color -i -f $logfile "Starting oh-my-zsh Setup"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
	if grep -q "Starting oh-my-zsh Setup" $logfile && ! grep -q "oh my zsh Setup Complete" $logfile; then
		log_and_color -s -f $logfile "oh my zsh Setup Complete"
		if [[ ! ":$PATH:" == *"$HOMEBREW_PREFIX/bin"* ]]; then export PATH=$PATH:$HOMEBREW_PREFIX/bin; fi

        if ! grep -q "$HOMEBREW_PREFIX/bin" "$HOME/.zshrc" 2>/dev/null; then
    		echo "" >> $HOME/.zshrc
    		echo "# Added by $USER" >> $HOME/.zshrc
            echo "export PATH=\$PATH:${HOMEBREW_PREFIX}/bin" >> "$HOME/.zshrc"
        fi
	fi
fi

if [ ! -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    	install_tool zsh-syntax-highlighting
	if [ -f $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
        echo "" >> $HOME/.zshrc
        echo "# Added by $USER" >> $HOME/.zshrc
		echo "source ${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> "$HOME/.zshrc"
	fi
fi
###End Shell Setup

###Double Check homebrew is in PATH
if [[ ! ":$PATH:" == *"$HOMEBREW_PREFIX/bin"* ]]; then export PATH=$PATH:$HOMEBREW_PREFIX/bin; fi

###Homebrew Inventory
mapfile -t brewApps < <(brew list --version | awk '{ print $1 }')

###Standard App Installs
STDAPPS=( "Slack:slack"
        "Google Chrome:google-chrome"
        "Mozilla Firefox:firefox"
        "DuckDuckGo Browser:duckduckgo"
        "Warp Terminal:warp"
        #"Zoom:zoom"
        "Jabra Direct:jabra-direct"
        "Visual Studio Code:visual-studio-code"
        "PyCharm Community Edition:pycharm-ce"
        "VLC Media Player:vlc"
        "GitHub Desktop:github"
        "Keka Archiver:keka"
        "AppCleaner:appcleaner"
        "Signal:signal"
        "OnlySwitch:only-switch"
        "Maccy Clipboard Manager:maccy"
        "ProNotes:pronotes" #ProNotes is a paid app — purchase required separately
        "Cyberduck:cyberduck"
    )

for stdapp in "${STDAPPS[@]}" ; do
    KEY="${stdapp%%:*}"
    VALUE="${stdapp##*:}"

    if [[ ! " ${brewApps[@]} " =~ " ${VALUE} " ]]; then
        while true; do
            read -r -p "$(tput setaf 3)Do you wish to install $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_app $VALUE; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
    echo
done
###End Standards App Installs

###VS Code Alias
if [[ -d "/Applications/Visual Studio Code.app" ]] || [[ " ${brewApps[@]} " =~ " visual-studio-code " ]]; then
    if ! grep -q "alias code=" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Added by $USER" >> "$HOME/.zshrc"
        echo "alias code=\"open -a 'Visual Studio Code'\"" >> "$HOME/.zshrc"
        log_and_color -s -f $logfile "VS Code alias added to .zshrc"
    else
        log_and_color -i -f $logfile "VS Code alias already exists in .zshrc"
    fi
fi
###End VS Code Alias

###PyCharm Alias
if [[ -d "/Applications/PyCharm CE.app" ]] || [[ " ${brewApps[@]} " =~ " pycharm-ce " ]]; then
    if ! grep -q "alias pycharm=" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "# Added by $USER" >> "$HOME/.zshrc"
        echo "alias pycharm=\"open -a 'PyCharm CE'\"" >> "$HOME/.zshrc"
        log_and_color -s -f $logfile "PyCharm alias added to .zshrc"
    else
        log_and_color -i -f $logfile "PyCharm alias already exists in .zshrc"
    fi
fi
###End PyCharm Alias

###Microsoft App Installs
MSAPPS=( #"Intune:intune-company-portal"
        #"Teams:microsoft-teams"
        #"Edge:microsoft-edge"
        "Remote Desktop:microsoft-remote-desktop"
        "PowerShell:powershell"
    )

for msapp in "${MSAPPS[@]}" ; do
    KEY="${msapp%%:*}"
    VALUE="${msapp##*:}"

    if [[ ! " ${brewApps[@]} " =~ " ${VALUE} " ]]; then
        while true; do
            read -r -p "$(tput setaf 3)Do you wish to install Microsoft $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_app $VALUE; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
    echo
done
###End Microsoft App Installs

###Security Tools Installs
SECTOOLS=( "Network Mapper (nmap):nmap"
        "Test SSL/TLS:testssl"
        "HashCat:hashcat"
    )

for sectool in "${SECTOOLS[@]}" ; do
    KEY="${sectool%%:*}"
    VALUE="${sectool##*:}"

    if [[ ! " ${brewApps[@]} " =~ " ${VALUE} " ]]; then
        while true; do
            read -r -p "$(tput setaf 3)Do you wish to install Security tool $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_tool $VALUE; break;;
                [Nn]* ) break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
    echo
done
###End Security Tools Installs

###TheHarvester Install
if [[ ! " ${brewApps[@]} " =~ " theharvester " ]]; then
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to install Security tool TheHarvester? (y or n): " yn
        case $yn in
            [Yy]* ) install_theharvester; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo
fi
###End TheHarvester Install

###Wireshark Install
if [[ ! " ${brewApps[@]} " =~ " wireshark " ]]; then
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to install Security app Wireshark? (y or n): " yn
        case $yn in
            [Yy]* ) install_wireshark; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo
fi
###End Wireshark Install


###Rename Computer
if ! grep "Renaming computer to" $logfile > /dev/null; then
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to rename computer? (y or n): " yn
        case $yn in
            [Yy]* ) read -r -p "$(tput setaf 3)Enter new computer name: " NEW_HOST_NAME; break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ ! -z "$NEW_HOST_NAME" ]; then

        read -r -p "$(tput setaf 3)Enter new domain name (default is local): " NEW_DOMAIN_NAME
        if [ -z "$NEW_DOMAIN_NAME" ]; then NEW_DOMAIN_NAME="local"; fi

        while true; do
            read -r -p "$(tput setaf 3)Rename computer to $NEW_HOST_NAME.$NEW_DOMAIN_NAME (y or n): " yn
            case $yn in
                [Yy]* ) rename=true; break;;
                [Nn]* ) break;;
                * ) echo "Please answer Y for yes or N for no.";;
            esac
        done

        if [ "$rename" = "true" ]; then
            log_and_color -i -f $logfile "Renaming computer to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"

            sudo scutil --set HostName "$NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -f $logfile "HostName set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            else
                log_and_color -e -f $logfile "ERROR: HostName was not set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            fi

            sudo scutil --set LocalHostName "$NEW_HOST_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -f $logfile "LocalHostName set to $NEW_HOST_NAME"
            else
                log_and_color -e -f $logfile "ERROR: LocalHostName was not set to $NEW_HOST_NAME"
            fi

            sudo scutil --set ComputerName "$NEW_HOST_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -f $logfile "ComputerName set to $NEW_HOST_NAME"
            else
                log_and_color -e -f $logfile "ERROR: ComputerName was not set to $NEW_HOST_NAME"
            fi

            sudo dscacheutil -flushcache

        else
            log_and_color -w -f $logfile "WARN: Computer was not renamed."
        fi
        unset rename



    fi
fi
###End Rename Computer

###Hidden Admin Account Creation
if ! grep "Hidden Admin Account Creation complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Create a hidden local admin account? (y or n): " yn
        case $yn in
            [Yy]* ) create_hidden_admin=true; break;;
            [Nn]* ) create_hidden_admin=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$create_hidden_admin" = true ]; then
        echo
        echo "Enter full name of new admin user, default is Crash Override:"
        read -r LOCAL_ADMIN_FULLNAME

        if [ -z "$LOCAL_ADMIN_FULLNAME" ]; then LOCAL_ADMIN_FULLNAME="Crash Override"; fi
        log_and_color -i -f $logfile "Local admin user full name set to: $LOCAL_ADMIN_FULLNAME"

        if [ "$LOCAL_ADMIN_FULLNAME" = "Crash Override" ] || [ "$LOCAL_ADMIN_FULLNAME" = "crash" ]; then
            LOCAL_ADMIN_SHORTNAME="crash"
        else
            echo "Enter username for $LOCAL_ADMIN_FULLNAME:"
            read -r LOCAL_ADMIN_SHORTNAME
            if [ -z "$LOCAL_ADMIN_SHORTNAME" ]; then
                log_and_color -e -f $logfile "ERROR: No username was entered for user: $LOCAL_ADMIN_FULLNAME"
                exit
            fi
        fi
        log_and_color -i -f $logfile "Local admin, $LOCAL_ADMIN_FULLNAME, username set to: $LOCAL_ADMIN_SHORTNAME"
        log_and_color -w -f $logfile "Prompting for sudo password"
        if id "$LOCAL_ADMIN_SHORTNAME" &>/dev/null; then
            log_and_color -i -f $logfile "$LOCAL_ADMIN_SHORTNAME already exists — skipping user creation"
        else
            sudo sysadminctl -addUser "$LOCAL_ADMIN_SHORTNAME" -fullName "$LOCAL_ADMIN_FULLNAME" -admin -home /var/$LOCAL_ADMIN_SHORTNAME #-password "$LOCAL_ADMIN_PASSWORD"
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Successfully created $LOCAL_ADMIN_FULLNAME with home director at /var/$LOCAL_ADMIN_SHORTNAME"
            else
                log_and_color -e -f $logfile "ERROR: Unable to create $LOCAL_ADMIN_FULLNAME"
                exit
            fi
        fi

        sudo dscl . create /Users/$LOCAL_ADMIN_SHORTNAME IsHidden 1
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Successfully hid $LOCAL_ADMIN_FULLNAME"
        else
            log_and_color -e -f $logfile "ERROR: Unable to hide $LOCAL_ADMIN_FULLNAME"
            exit
        fi

        sudo dscl . -delete "/SharePoints/$LOCAL_ADMIN_FULLNAME's Public Folder" # Removes the public folder sharepoint for the local admin if it was created
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Successfully deleted $LOCAL_ADMIN_FULLNAME's Public Folder'"
        else
            log_and_color -w -f $logfile "WARN: Unable to delete $LOCAL_ADMIN_FULLNAME's Public Folder. Folder may not exist"
        fi

        echo
        echo "$(tput setaf 3)Enter password for $LOCAL_ADMIN_FULLNAME"
        sudo dscl . -passwd /Users/$LOCAL_ADMIN_SHORTNAME
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Successfully created password for $LOCAL_ADMIN_FULLNAME"
        else
            log_and_color -e -f $logfile "ERROR: Unable to create password for $LOCAL_ADMIN_FULLNAME"
            exit
        fi

        log_and_color -i -f $logfile "Creating re-admin ease-of-use scripts in $HOME/Public"
        echo "sudo dseditgroup -o edit -a $USER -t user admin" > $HOME/Public/add-admin.sh
        sudo chmod +x $HOME/Public/add-admin.sh
        echo "sudo dseditgroup -o edit -d $USER -t user admin" > $HOME/Public/remove-admin.sh
        sudo chmod +x $HOME/Public/remove-admin.sh

        if dscacheutil -q group -a name admin | grep -q $LOCAL_ADMIN_SHORTNAME; then
            log_and_color -i -f $logfile "Removing $USER's admin privileges"
            sudo dseditgroup -o edit -d $USER -t user admin
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "$USER's admin privileges were revoked"
            else
                log_and_color -e -f $logfile "ERROR: Unable to revoke $USER's admin privileges"
                exit
            fi
        else
            log_and_color -e -f $logfile "ERROR: Admin, $LOCAL_ADMIN_SHORTNAME, was not found in admin group"
        fi
        log_and_color -s -f $logfile "Hidden Admin Account Creation complete"
    else
        log_and_color -w -f $logfile "Hidden Admin Account Creation skipped"
    fi
    unset create_hidden_admin
fi
###End Hidden Admin Account Creation

###Hardening Disable NetBIOS
if ! grep "Hardening Disable NetBIOS complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to disable NetBIOS (hardening)? (y or n): " yn
        case $yn in
            [Yy]* ) harden_netbios=true; break;;
            [Nn]* ) harden_netbios=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$harden_netbios" = true ]; then
        NETBIOS_LABEL="com.apple.netbiosd"
        NETBIOS_PLIST="/System/Library/LaunchDaemons/${NETBIOS_LABEL}.plist"
        NSMB_CONF="/etc/nsmb.conf"

        if [ ! -f "$NETBIOS_PLIST" ]; then
            log_and_color -w -f $logfile "WARN: $NETBIOS_PLIST not found — skipping NetBIOS hardening"
        else
            log_and_color -i -f $logfile "Disabling $NETBIOS_LABEL launchd job"
            sudo launchctl disable "system/${NETBIOS_LABEL}"
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "$NETBIOS_LABEL disabled successfully"
            else
                log_and_color -e -f $logfile "ERROR: Failed to set disabled override for $NETBIOS_LABEL"
            fi

            log_and_color -i -f $logfile "Attempting to unload $NETBIOS_LABEL if currently loaded"
            sudo launchctl bootout system "$NETBIOS_PLIST" 2>/dev/null
            log_and_color -i -f $logfile "$NETBIOS_LABEL bootout attempted (may already be unloaded — this is normal)"

            log_and_color -i -f $logfile "Writing SMB client hardening settings to $NSMB_CONF"
            printf '[default]\nprotocol_vers_map=6\nport445=no_netbios\n' | sudo tee "$NSMB_CONF" > /dev/null
            if [ $? -eq 0 ]; then
                sudo chmod 0644 "$NSMB_CONF"
                sudo chown root:wheel "$NSMB_CONF"
                log_and_color -s -f $logfile "$NSMB_CONF written and permissions set"
            else
                log_and_color -e -f $logfile "ERROR: Failed to write $NSMB_CONF"
            fi

            disabled_state=$(sudo launchctl print-disabled system 2>/dev/null | awk -v label="$NETBIOS_LABEL" '$0 ~ label {print $3}' | tr -d ';')
            if [ "$disabled_state" = "true" ]; then
                log_and_color -s -f $logfile "Verified: $NETBIOS_LABEL disabled override is true"
            else
                log_and_color -w -f $logfile "WARN: $NETBIOS_LABEL disabled state reported as: ${disabled_state:-not found}"
            fi

            if pgrep -i netbiosd > /dev/null 2>&1; then
                log_and_color -w -f $logfile "WARN: $NETBIOS_LABEL still appears to be running (will not restart after reboot)"
            else
                log_and_color -s -f $logfile "Verified: $NETBIOS_LABEL is not running"
            fi

            log_and_color -i -f $logfile "To re-enable: sudo launchctl enable system/$NETBIOS_LABEL && sudo launchctl bootstrap system $NETBIOS_PLIST && sudo rm $NSMB_CONF"
            log_and_color -s -f $logfile "Hardening Disable NetBIOS complete"
        fi
    else
        log_and_color -w -f $logfile "Hardening Disable NetBIOS skipped"
    fi
    unset harden_netbios
fi
###End Hardening Disable NetBIOS

###Hardening Disable Sharing Services
if ! grep "Hardening Disable Sharing Services complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to disable sharing services (AFP, SMB, Screen Sharing, Printer Sharing, Remote Login, Remote Management)? (y or n): " yn
        case $yn in
            [Yy]* ) harden_sharing=true; break;;
            [Nn]* ) harden_sharing=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$harden_sharing" = true ]; then

        # AFP File Sharing
        if launchctl list com.apple.AppleFileServer &>/dev/null; then
            log_and_color -i -f $logfile "Disabling AFP File Sharing"
            sudo launchctl disable system/com.apple.AppleFileServer
            sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null
            log_and_color -s -f $logfile "AFP File Sharing disabled"
        else
            log_and_color -i -f $logfile "AFP File Sharing already disabled"
        fi

        # SMB File Sharing
        if launchctl list com.apple.smbd &>/dev/null; then
            log_and_color -i -f $logfile "Disabling SMB File Sharing"
            sudo launchctl disable system/com.apple.smbd
            sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null
            log_and_color -s -f $logfile "SMB File Sharing disabled"
        else
            log_and_color -i -f $logfile "SMB File Sharing already disabled"
        fi

        # Screen Sharing
        if launchctl list com.apple.screensharing &>/dev/null; then
            log_and_color -i -f $logfile "Disabling Screen Sharing"
            sudo launchctl disable system/com.apple.screensharing
            sudo launchctl bootout system /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null
            log_and_color -s -f $logfile "Screen Sharing disabled"
        else
            log_and_color -i -f $logfile "Screen Sharing already disabled"
        fi

        # Printer Sharing
        if cupsctl | grep -q 'SharePrinters=1'; then
            log_and_color -i -f $logfile "Disabling Printer Sharing"
            sudo cupsctl --no-share-printers
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Printer Sharing disabled"
            else
                log_and_color -e -f $logfile "ERROR: Failed to disable Printer Sharing"
            fi
        else
            log_and_color -i -f $logfile "Printer Sharing already disabled"
        fi

        # Remote Login (SSH)
        if launchctl list com.openssh.sshd &>/dev/null; then
            log_and_color -i -f $logfile "Disabling Remote Login (SSH)"
            sudo launchctl disable system/com.openssh.sshd
            sudo launchctl bootout system /System/Library/LaunchDaemons/ssh.plist 2>/dev/null
            log_and_color -s -f $logfile "Remote Login (SSH) disabled"
        else
            log_and_color -i -f $logfile "Remote Login (SSH) already disabled"
        fi

        # Remote Management (ARD)
        if pgrep -x ARDAgent > /dev/null 2>&1; then
            log_and_color -i -f $logfile "Disabling Remote Management (ARD)"
            sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Remote Management (ARD) disabled"
            else
                log_and_color -e -f $logfile "ERROR: Failed to disable Remote Management (ARD)"
            fi
        else
            log_and_color -i -f $logfile "Remote Management (ARD) already disabled"
        fi

        log_and_color -s -f $logfile "Hardening Disable Sharing Services complete"
    else
        log_and_color -w -f $logfile "Hardening Disable Sharing Services skipped"
    fi
    unset harden_sharing
fi
###End Hardening Disable Sharing Services

###Hardening Enable Firewall
if ! grep "Hardening Enable Firewall complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to enable the firewall with stealth mode and block all incoming connections? (y or n): " yn
        case $yn in
            [Yy]* ) harden_firewall=true; break;;
            [Nn]* ) harden_firewall=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$harden_firewall" = true ]; then
        FW="/usr/libexec/ApplicationFirewall/socketfilterfw"

        if $FW --getglobalstate 2>&1 | grep -qiE 'enabled|on'; then
            log_and_color -i -f $logfile "Firewall already enabled"
        else
            log_and_color -i -f $logfile "Enabling firewall"
            sudo $FW --setglobalstate on
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Firewall enabled"
            else
                log_and_color -e -f $logfile "ERROR: Failed to enable firewall"
            fi
        fi

        if $FW --getblockall 2>&1 | grep -qiE 'enabled|on'; then
            log_and_color -i -f $logfile "Block all incoming connections already enabled"
        else
            log_and_color -i -f $logfile "Enabling block all incoming connections"
            sudo $FW --setblockall on
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Block all incoming connections enabled"
            else
                log_and_color -e -f $logfile "ERROR: Failed to enable block all incoming connections"
            fi
        fi

        if $FW --getstealthmode 2>&1 | grep -qiE 'enabled|on'; then
            log_and_color -i -f $logfile "Stealth mode already enabled"
        else
            log_and_color -i -f $logfile "Enabling stealth mode"
            sudo $FW --setstealthmode on
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Stealth mode enabled"
            else
                log_and_color -e -f $logfile "ERROR: Failed to enable stealth mode"
            fi
        fi

        log_and_color -s -f $logfile "Hardening Enable Firewall complete"
    else
        log_and_color -w -f $logfile "Hardening Enable Firewall skipped"
    fi
    unset harden_firewall
fi
###End Hardening Enable Firewall

###Hardening Enable Secure Keyboard Entry
if ! grep "Hardening Enable Secure Keyboard Entry complete" $logfile > /dev/null; then
    echo
    log_and_color -w -f $logfile "NOTE: Secure Keyboard Entry applies to Terminal.app only. It may prevent text expanders, autocomplete tools, and password managers that monitor keyboard input from working."
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to enable Secure Keyboard Entry for Terminal? (y or n): " yn
        case $yn in
            [Yy]* ) harden_ske=true; break;;
            [Nn]* ) harden_ske=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$harden_ske" = true ]; then
        current_ske=$(defaults read com.apple.Terminal SecureKeyboardEntry 2>/dev/null)
        if [ "$current_ske" = "1" ]; then
            log_and_color -i -f $logfile "Secure Keyboard Entry already enabled"
        else
            defaults write com.apple.Terminal SecureKeyboardEntry -bool true
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Secure Keyboard Entry enabled for Terminal"
            else
                log_and_color -e -f $logfile "ERROR: Failed to enable Secure Keyboard Entry"
            fi
        fi
        log_and_color -s -f $logfile "Hardening Enable Secure Keyboard Entry complete"
    else
        log_and_color -w -f $logfile "Hardening Enable Secure Keyboard Entry skipped"
    fi
    unset harden_ske current_ske
fi
###End Hardening Enable Secure Keyboard Entry

###Location-Aware Firewall Setup
if ! grep "Location-Aware Firewall setup complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Do you wish to install the location-aware firewall? (y or n): " yn
        case $yn in
            [Yy]* ) setup_law_firewall=true; break;;
            [Nn]* ) setup_law_firewall=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$setup_law_firewall" = true ]; then
        LAW_SCRIPT="/usr/local/bin/firewall-location-aware.sh"
        LAW_PLIST="/Library/LaunchDaemons/com.user.firewall-location-aware.plist"
        BASE_URL="https://raw.githubusercontent.com/awurthmann/Setup-MacEnvironment/main"

        echo
        read -r -p "$(tput setaf 3)Enter your home subnet prefix (default 192.168.1.): " LAW_SUBNET
        LAW_SUBNET="${LAW_SUBNET:-192.168.1.}"
        [[ "$LAW_SUBNET" != *. ]] && LAW_SUBNET="${LAW_SUBNET}."
        log_and_color -i -f $logfile "Home subnet prefix set to: $LAW_SUBNET"

        read -r -p "$(tput setaf 3)Enter your gateway IP address (default 192.168.1.1): " LAW_GATEWAY_IP
        LAW_GATEWAY_IP="${LAW_GATEWAY_IP:-192.168.1.1}"
        log_and_color -i -f $logfile "Gateway IP set to: $LAW_GATEWAY_IP"

        echo
        echo "$(tput setaf 6)To obtain your gateway MAC address, in another terminal run:"
        echo "$(tput setaf 6)  ping -c 1 $LAW_GATEWAY_IP && arp $LAW_GATEWAY_IP"
        echo
        LAW_GATEWAY_MAC=""
        while [ -z "$LAW_GATEWAY_MAC" ]; do
            read -r -p "$(tput setaf 3)Enter your gateway MAC address: " LAW_GATEWAY_MAC
            if [ -z "$LAW_GATEWAY_MAC" ]; then
                echo "$(tput setaf 1)Gateway MAC address is required."
            fi
        done
        LAW_GATEWAY_MAC=$(echo "$LAW_GATEWAY_MAC" | tr '[:upper:]' '[:lower:]')
        log_and_color -i -f $logfile "Gateway MAC set to: $LAW_GATEWAY_MAC"

        log_and_color -i -f $logfile "Downloading firewall-location-aware.sh"
        sudo curl -fsSL "${BASE_URL}/firewall-location-aware.sh" -o "$LAW_SCRIPT"
        if [ $? -eq 0 ]; then
            log_and_color -i -f $logfile "Configuring network values in firewall-location-aware.sh"
            sudo sed -i '' \
                -e "s|YOUR_HOME_SUBNET_PREFIX\.|${LAW_SUBNET}|g" \
                -e "s|YOUR_GATEWAY_IP|${LAW_GATEWAY_IP}|g" \
                -e "s|YOUR_GATEWAY_MAC|${LAW_GATEWAY_MAC}|g" \
                "$LAW_SCRIPT"
            if [ $? -eq 0 ]; then
                sudo chmod 755 "$LAW_SCRIPT"
                sudo chown root:wheel "$LAW_SCRIPT"
                log_and_color -s -f $logfile "firewall-location-aware.sh configured and installed to $LAW_SCRIPT"
            else
                log_and_color -e -f $logfile "ERROR: Failed to configure firewall-location-aware.sh"
            fi
        else
            log_and_color -e -f $logfile "ERROR: Failed to download firewall-location-aware.sh"
        fi

        log_and_color -i -f $logfile "Downloading com.user.firewall-location-aware.plist"
        sudo curl -fsSL "${BASE_URL}/com.user.firewall-location-aware.plist" -o "$LAW_PLIST"
        if [ $? -eq 0 ]; then
            sudo chmod 644 "$LAW_PLIST"
            sudo chown root:wheel "$LAW_PLIST"
            log_and_color -s -f $logfile "com.user.firewall-location-aware.plist installed to $LAW_PLIST"

            sudo launchctl load -w "$LAW_PLIST"
            if [ $? -eq 0 ]; then
                log_and_color -s -f $logfile "Location-Aware Firewall setup complete"
            else
                log_and_color -e -f $logfile "ERROR: Failed to load com.user.firewall-location-aware.plist"
            fi
        else
            log_and_color -e -f $logfile "ERROR: Failed to download com.user.firewall-location-aware.plist"
        fi
    else
        log_and_color -w -f $logfile "Location-Aware Firewall setup skipped"
    fi
    unset setup_law_firewall LAW_SUBNET LAW_GATEWAY_IP LAW_GATEWAY_MAC
fi
###End Location-Aware Firewall Setup

###PARA File System Setup
if ! grep "PARA File System setup complete" $logfile > /dev/null; then
    echo
    while true; do
        read -r -p "$(tput setaf 3)Do you want to setup the PARA File System? (y/n, default y): " yn
        yn=${yn:-y}
        case $yn in
            [Yy]* ) setup_para=true; break;;
            [Nn]* ) setup_para=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ "$setup_para" = true ]; then
        read -r -p "$(tput setaf 3)Where would you like to setup PARA? (default ~/Documents): " PARA_BASE
        PARA_BASE="${PARA_BASE:-$HOME/Documents}"
        PARA_BASE="${PARA_BASE/#\~/$HOME}"

        log_and_color -i -f $logfile "Setting up PARA File System under $PARA_BASE"
        if mkdir -p "$PARA_BASE/_PROJECTS"; then
            log_and_color -s -f $logfile "Created $PARA_BASE/_PROJECTS"
        else
            log_and_color -e -f $logfile "ERROR: Failed to create $PARA_BASE/_PROJECTS"
        fi
        if mkdir -p "$PARA_BASE/_AREAS"; then
            log_and_color -s -f $logfile "Created $PARA_BASE/_AREAS"
        else
            log_and_color -e -f $logfile "ERROR: Failed to create $PARA_BASE/_AREAS"
        fi
        if mkdir -p "$PARA_BASE/_ARCHIVE"; then
            log_and_color -s -f $logfile "Created $PARA_BASE/_ARCHIVE"
        else
            log_and_color -e -f $logfile "ERROR: Failed to create $PARA_BASE/_ARCHIVE"
        fi
        if mkdir -p "$PARA_BASE/_RESOURCES"; then
            log_and_color -s -f $logfile "Created $PARA_BASE/_RESOURCES"
        else
            log_and_color -e -f $logfile "ERROR: Failed to create $PARA_BASE/_RESOURCES"
        fi
        if mkdir -p "$PARA_BASE/_RESOURCES/Screen Shots"; then
            log_and_color -s -f $logfile "Created $PARA_BASE/_RESOURCES/Screen Shots"
        else
            log_and_color -e -f $logfile "ERROR: Failed to create $PARA_BASE/_RESOURCES/Screen Shots"
        fi

        echo
        while true; do
            read -r -p "$(tput setaf 3)Move Screen Shots folder to $PARA_BASE/_RESOURCES/Screen Shots? (y/n): " yn
            case $yn in
                [Yy]* )
                    defaults write com.apple.screencapture location "$PARA_BASE/_RESOURCES/Screen Shots"
                    if [ $? -eq 0 ]; then
                        killall SystemUIServer 2>/dev/null
                        log_and_color -s -f $logfile "Screen Shots location set to $PARA_BASE/_RESOURCES/Screen Shots"
                    else
                        log_and_color -e -f $logfile "ERROR: Failed to set Screen Shots location"
                    fi
                    break;;
                [Nn]* ) log_and_color -w -f $logfile "Screen Shots location not changed"; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done

    else
        echo
        while true; do
            read -r -p "$(tput setaf 3)Move Screen Shots folder to ~/Documents/Screen Shots? (y/n): " yn
            case $yn in
                [Yy]* )
                    mkdir -p "$HOME/Documents/Screen Shots"
                    if [ $? -eq 0 ]; then
                        defaults write com.apple.screencapture location "$HOME/Documents/Screen Shots"
                        if [ $? -eq 0 ]; then
                            killall SystemUIServer 2>/dev/null
                            log_and_color -s -f $logfile "Screen Shots location set to $HOME/Documents/Screen Shots"
                        else
                            log_and_color -e -f $logfile "ERROR: Failed to set Screen Shots location"
                        fi
                    else
                        log_and_color -e -f $logfile "ERROR: Failed to create $HOME/Documents/Screen Shots"
                    fi
                    break;;
                [Nn]* ) log_and_color -w -f $logfile "Screen Shots location not changed"; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

    log_and_color -s -f $logfile "PARA File System setup complete"
    unset setup_para PARA_BASE
fi
###End PARA File System Setup

###Misc. Output and reminders to screen
##Some of these will be automated at a later date
echo
echo
echo "$(tput setaf 5)Miscellaneous and Optional Steps:"
echo "$(tput setaf 4)· If Microsoft Intune/Company Portal is installed, start it"
echo "$(tput setaf 4)· If Microsoft Word is installed, start it"
echo "$(tput setaf 4)· If Microsoft Excel is installed, start it"
echo "$(tput setaf 4)· If Microsoft PowerPoint is installed, start it"
echo "$(tput setaf 4)· If Microsoft OneDrive is installed, start it"
echo "$(tput setaf 4)· If Microsoft Outlook is installed, start it, and..."
echo "$(tput setaf 6)  · Install Zoom for Outlook"
echo "$(tput setaf 6)    Open Outlook and sign in to your account."
echo "$(tput setaf 6)    Switch to Mail view, click the ellipsis button , and then select Get Add-ins. "
echo "$(tput setaf 6)    Outlook will open a browser to manage your add-ins."
echo "$(tput setaf 6)    Search for Zoom for Outlook, "
echo "$(tput setaf 6)     or switch to the Admin-managed tab to view add-ins made available by your account admins."
echo "$(tput setaf 6)    Click on Zoom for Outlook and then click Add."
echo "$(tput setaf 4)· Sync Google Contacts with Apple Contacts by adding a Gmail account"
echo "$(tput setaf 6)  · May require Chrome to be default browser during setup, can switch after"
echo "$(tput setaf 4)· If Microsoft Edge is installed, start it and double check Security & Privacy prefferences. Make them Strict"
echo "$(tput setaf 4)· Zoom for Outlook Web can be installed at:"
echo "$(tput setaf 6)    https://appsource.microsoft.com/en-us/product/office/WA104381712?tab=Overview"
echo "$(tput setaf 6)    or https://outlook.office.com/mail/options/calendar/eventAndInvitations"
echo "$(tput setaf 4)· Change prompt in .zshrc, example apple"
echo "$(tput setaf 4)· Remove unwanted apps from the menu and task bars"
echo "$(tput setaf 4)· Disable AirPlay Receiver: System Settings → General → AirPlay & Handoff → AirPlay Receiver (Off)"
echo "$(tput setaf 4)· Disable Media Sharing (Home Sharing): Music (or TV) → Settings → Sharing (Off)"
echo "$(tput setaf 4)· Adjust Finder prefferences"
echo "$(tput setaf 4)· Install any required hardware/dock drivers (may require temp admin perms)"
echo "$(tput setaf 4)· Enable Apple Account"
echo "$(tput setaf 6)  · Sync only Contacts, Find my Mac"
echo
echo
###End Misc. Output and reminders to screen




###Finale
while true; do
    echo
    echo "$(tput setaf 5)Setup script complete."
    echo "$(tput setaf 3)A final reboot is required "
    read -r -p "$(tput setaf 3)Reboot computer? (y or n): " yn
    case $yn in
        [Yy]* ) log_and_color -s -f $logfile "Setup script complete, rebooting";sudo shutdown -r now; break;;
        [Nn]* ) log_and_color -w -f $logfile "Setup script complete, reboot recommended"; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
###End Finale
