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
# Version: 2022.07.21.1655
# Description: Setup Mac Environment on my Test System(s)
# 
# Instructions: Download Setup-MacEnvironment.sh
#                chmod +x ./Setup-MacEnvironment.sh
#                ./Setup-MacEnvironment.sh
#	
# Tested with: macOS 12.4 21F2081
# Arguments: None
# Output: Standard Out, Info Log and Error Log files
#
# Notes:  
#   Latest version, which added some error handling, has not been tested on a fresh install.
#    Functionality the same as previous version.
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
            break
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
            break
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
        -*) log -e "log: invalid option '$1'"; return 1;;
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
    echo -e "SH [`date +"%T"`]: $*" >> $logfile
}

function install_xcode () {
    log_and_color -i -f $logfile "Running: xcode-select --install"

    #osascript -e 'tell app "Terminal" to do script "xcode-select --install"'
    xcode-select --install

    log_and_color -i -f $logfile "Waiting for Xcode.app to start"
    wait_app_start "/System/Library/CoreServices/Install\ Command\ Line\ Developer\ Tools.app"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Xcode.app started"
        log_and_color -i -f $logfile "Waiting for Xcode.app to stop"
        wait_app_stop "/System/Library/CoreServices/Install\ Command\ Line\ Developer\ Tools.app"
        if [ $? -eq 0 ]; then
            log_and_color -s -f $logfile "Xcode.app completed"
            log_and_color -w -f $logfile "Reboot required. Rebooting now"
            return 0
        else
            log_and_color -e -f $logfile "ERROR: Xcode.app did not stop in the allotted time period"
            return 1
        fi
    else
        log_and_color -e -f $logfile "ERROR: Xcode.app did not start in the allotted time period"
        return 1
    fi
}

function install_tool () {
    log_and_color -s -f $logfile "Starting install for: $1"
    brew install $1
    #&& log_and_color -s -f $logfile "$1 successfully installed" || log_and_color -e -f $logfile "ERROR: $1 install failed"
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "$1 successfully installed"
    else
        log_and_color -e -f $logfile "ERROR: $1 install failed"
    fi
}

function install_app () {
    log_and_color -s -f $logfile "Starting install for: $1"
    brew install --cask $1
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
        echo "export PATH=\$PATH:\$HOME/homebrew/etc/theharvester" >> .zshrc

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
            brew install --cask wireshark-chmodbpf && log_and_color -s -f $logfile "Wireshark macOS Hotfix was successfully installed" || log_and_color -e -f $logfile "ERROR: Wireshark macOS Hotfix install was unsuccessfull"
        else
            log_and_color -e -f $logfile "ERROR: Wireshark GUI install was unsuccessfull"
        fi
    else
        log_and_color -e -f $logfile "ERROR: Wireshark was not installed. Exiting"
    fi  
}
###End Functions

####Working code

#Set logfile
logfile=~/Documents/Setup-MacEnvironment.log

###Admin Check
if [ `whoami` == root ]; then
    log_and_color -e -f $logfile "ERROR: This script must NOT be run as root or using sudo. Exiting"
    exit
fi
###End Admin Check

###Xcode Install
if ! xcode-select -p > /dev/null ; then
    install_xcode
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Xcode successfully installed"
        shutdown -r now
    else
        log_and_color -e -f $logfile "ERROR: Xcode was not installed. Exiting"
    fi
    exit
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


###VIM Setup
#This should be a file stored in GitHub then pulled down but for now this will do.

if [ ! -f "$HOME/.vimrc" ]; then
    log_and_color -i -f $logfile "Setting VIM Environment"
    echo "set nocompatible" >> $HOME/.vimrc
    echo "filetype on" >> $HOME/.vimrc
    echo "filetype plugin on" >> $HOME/.vimrc
    echo "filetype indent on" >> $HOME/.vimrc
    echo "set term=builtin_ansi" >> $HOME/.vimrc
    echo "syntax on" >> $HOME/.vimrc
    echo "set number" >> $HOME/.vimrc
    echo "set cursorline" >> $HOME/.vimrc
    echo "set shiftwidth=4" >> $HOME/.vimrc
    echo "set tabstop=4" >> $HOME/.vimrc
    echo "set expandtab" >> $HOME/.vimrc
    echo "set scrolloff=10" >> $HOME/.vimrc
    echo "set incsearch" >> $HOME/.vimrc
    echo "set ignorecase" >> $HOME/.vimrc
    echo "set smartcase" >> $HOME/.vimrc
    echo "set showcmd" >> $HOME/.vimrc
    echo "set showmode" >> $HOME/.vimrc
    echo "set showmatch" >> $HOME/.vimrc
    echo "set hlsearch" >> $HOME/.vimrc
    echo "set wildmenu" >> $HOME/.vimrc
    echo "set wildmode=list:longest" >> $HOME/.vimrc
    echo "set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx" >> $HOME/.vimrc
    log_and_color -g -f $logfile "VIM Environment Setup complete"
fi
#End VIM Setup

###Homebrew Setup (non-admin post install version)
if [ ! -d $HOME/homebrew ]; then
    log_and_color -i -f $logfile "Starting Homebrew Setup"
    cd $HOME
    mkdir homebrew
    curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
    eval "$(homebrew/bin/brew shellenv)"
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"
    export PATH=$PATH:$HOME/homebrew/bin
    echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc
    log_and_color -g -f $logfile "Homebrew Setup Complete"
fi
###End Homebrew Setup (non-admin post install version)


###Shell Setup
if [ ! -d $HOME/.oh-my-zsh ]; then
    echo
	echo "$(tput setaf 5)ATTENTION: The oh-my-zsh installation will require a restart of this setup script"
    echo "$(tput setaf 6)Press any key to continue"
    read any
    unset any
	
	log_and_color -w -f $logfile "oh-my-zsh setup stops this setup script during install. To complete setup, restart the script"
	log_and_color -i -f $logfile "Starting oh-my-zsh Setup"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
	if tail -n 1 $logfile | grep -q "Starting oh-my-zsh Setup"; then
		log_and_color -g -f $logfile "oh my zsh Setup Complete"		
		if [[ ! ":$PATH:" == *"$HOME/homebrew/bin"* ]]; then export PATH=$PATH:$HOME/homebrew/bin; fi

        if ! tail -n 5 $HOME/.zshrc | grep -q "HOME/homebrew/bin"; then
    		echo "" >> $HOME/.zshrc
    		echo "# Added by $USER" >> $HOME/.zshrc
    		echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> $HOME/.zshrc
        fi
	fi
fi

if [ ! -f $HOME/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    	install_tool zsh-syntax-highlighting
	if [ -f $HOME/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
		 echo "source \$HOME/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> $HOME/.zshrc
	fi
fi	
###End Shell Setup

###Double Check homebrew is in PATH
if [[ ! ":$PATH:" == *"$HOME/homebrew/bin"* ]]; then export PATH=$PATH:$HOME/homebrew/bin; fi

###Homebrew Inventory
brewApps=( $(brew list --version | awk '{ print $1 }') )

###Standard App Installs
STDAPPS=( "Slack:slack"
        "Google Chrome:google-chrome"
        #"Zoom:zoom"
        "Visual Studio Code:visual-studio-code"
        "VLC Media Player:vlc" 
        "GitHub Desktop:github" 
        "Keka Archiver:keka"
        "AppCleaner:appcleaner"
        "Signal:signal"
    )

for stdapp in "${STDAPPS[@]}" ; do
    KEY="${stdapp%%:*}"
    VALUE="${stdapp##*:}"

    if [[ ! " ${brewApps[@]} " =~ " ${VALUE} " ]]; then
	echo "$(tput setaf 2)NOTE: You can safely ignore any missing formula error above"
	echo 
        while true; do
            read -p "$(tput setaf 3)Do you wish to install standard app $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_app $VALUE; break;;
                [Nn]* ) break; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
    echo
done
###End Standards App Installs


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
	echo "$(tput setaf 2)NOTE: You can safely ignore any missing formula error above"
	echo 
        while true; do
            read -p "$(tput setaf 3)Do you wish to install Microsoft $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_app $VALUE; break;;
                [Nn]* ) break; exit;;
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
	echo "$(tput setaf 2)NOTE: You can safely ignore any missing formula error above"
	echo 
        while true; do
            read -p "$(tput setaf 3)Do you wish to install Security tool $KEY? (y or n): " yn
            case $yn in
                [Yy]* ) install_tool $VALUE; break;;
                [Nn]* ) break; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
    echo
done
###End Security Tools Installs

###TheHarvester Install
if [[ ! " ${brewApps[@]} " =~ " theharvester " ]]; then
	echo "$(tput setaf 2)NOTE: You can safely ignore any missing formula error above"
	echo 
    while true; do
        read -p "$(tput setaf 3)Do you wish to install Security tool TheHarvester? (y or n): " yn
        case $yn in
            [Yy]* ) install_theharvester; break;;
            [Nn]* ) break; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo
fi
###End TheHarvester Install

###Wireshark Install
if [[ ! " ${brewApps[@]} " =~ " wireshark " ]]; then
    while true; do
        read -p "$(tput setaf 3)Do you wish to install Security app Wireshark? (y or n): " yn
        case $yn in
            [Yy]* ) install_wireshark; break;;
            [Nn]* ) break; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    echo
fi
###End Wireshark Install


###Rename Computer
if ! grep "Renaming computer to" $logfile > /dev/null; then 
    while true; do
        read -p "$(tput setaf 3)Do you wish to rename computer? (y or n): " yn
        case $yn in
            [Yy]* ) read -p "$(tput setaf 3)Enter new computer name: " NEW_HOST_NAME; break;;
            [Nn]* ) break; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    if [ ! -z "$NEW_HOST_NAME" ]; then 
        
        read -p "$(tput setaf 3)Enter new domain name (default is local): " NEW_DOMAIN_NAME
        if [ -z "$NEW_DOMAIN_NAME" ]; then NEW_DOMAIN_NAME="local"; fi

        while true; do
            read -p "$(tput setaf 3)Rename computer to $NEW_HOST_NAME.$NEW_DOMAIN_NAME: " yn
            case $yn in
                [Yy]* ) rename=true; break;;
                [Nn]* ) break; exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done

        if "$rename" eq "true"; then
            log_and_color -i -f $logfile "Renaming computer to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"

            sudo scutil --set HostName "$NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -g $logfile "HostName set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            else
                log_and_color -i -g $logfile "ERROR: HostName was not set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
            fi

            sudo scutil --set LocalHostName "$NEW_HOST_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -g $logfile "LocalHostName set to $NEW_HOST_NAME"
            else
                log_and_color -i -g $logfile "ERROR: LocalHostName was not set to $NEW_HOST_NAME"
            fi

            sudo scutil --set ComputerName "$NEW_HOST_NAME"
            if [ $? -eq 0 ]; then
                log_and_color -i -g $logfile "ComputerName set to $NEW_HOST_NAME"
            else
                log_and_color -i -g $logfile "ERROR: ComputerName was not set to $NEW_HOST_NAME"
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
echo "Enter full name of new admin user, default is Crash Override:"
read LOCAL_ADMIN_FULLNAME

if [ ! $LOCAL_ADMIN_FULLNAME ]; then LOCAL_ADMIN_FULLNAME="Crash Override"; fi
log_and_color -i -f $logfile "Local admin user full name set to: $LOCAL_ADMIN_FULLNAME"

if [ "$LOCAL_ADMIN_FULLNAME" = "Crash Override" ] || [ "$LOCAL_ADMIN_FULLNAME" = "crash" ]; then 
    LOCAL_ADMIN_SHORTNAME="crash"
else
    echo "Enter username for $LOCAL_ADMIN_FULLNAME:"
    if [ ! $LOCAL_ADMIN_SHORTNAME ]; then 
        log_and_color -e -f $logfile "ERROR: No username was entered for user: $LOCAL_ADMIN_FULLNAME"
        exit
    fi
fi
log_and_color -i -f $logfile "Local admin, $LOCAL_ADMIN_FULLNAME, username set to: $LOCAL_ADMIN_SHORTNAME"
sudo sysadminctl -addUser "$LOCAL_ADMIN_SHORTNAME" -fullName "$LOCAL_ADMIN_FULLNAME" -admin -home /var/$LOCAL_ADMIN_SHORTNAME #-password "$LOCAL_ADMIN_PASSWORD"
if [ $? -eq 0 ]; then
    log_and_color -s -f $logfile "Successfully created $LOCAL_ADMIN_FULLNAME with home director at /var/$LOCAL_ADMIN_SHORTNAME"
else
    log_and_color -e -f $logfile "ERROR: Unable to create $LOCAL_ADMIN_FULLNAME"
    exit
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
###End Hidden Admin Account Creation

###Misc. Output and reminders to screen
echo
echo
echo "$(tput setaf 5)==Miscellaneous Steps and Optional Steps=="
echo "$(tput setaf 4)· If Microsoft Intune/Company Portal is installed, start it"
echo "$(tput setaf 4)· If Microsoft Word is installed, start it"
echo "$(tput setaf 4)· If Microsoft Excel is installed, start it"
echo "$(tput setaf 4)· If Microsoft PowerPoint is installed, start it"
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
echo "$(tput setaf 4)· Change prompt in .zshrc to, for example, apple"
echo "$(tput setaf 4)· Remove unwanted apps from the menu and task bars"
echo "$(tput setaf 4)· Adjust Finder prefferences"
echo "$(tput setaf 4)· Install any required hardware/dock drivers (may require temp admin perms)"
echo "$(tput setaf 4)· Change Screen Shot location"
echo "$(tput setaf 6)   mkdir ~/Documents/Screen\ Shots"
echo "$(tput setaf 6)   defaults write com.apple.screencapture location '~/Documents/Screen Shots'"
echo "$(tput setaf 4)· Enable Apple Account"
echo "$(tput setaf 6)  · Sync only Contacts, Find my Mac"
###End Misc. Output and reminders to screen




###Finale
while true; do
    echo
    echo "$(tput setaf 3)A final reboot is required "
    read -p "$(tput setaf 3)Reboot computer? (y or n): " yn
    case $yn in
        [Yy]* ) log_and_color -s -f $logfile "Setup complete, rebooting";shutdown -r now; break;;
        [Nn]* ) log_and_color -w -f $logfile "Setup complete, reboot recommended";break; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
###End Finale