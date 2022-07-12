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
# Name: Setup-MacEnvironment.ps1
# Version: 2022.07.11.1335
# Description: Setup Mac Environment on my Test System(s)
# 
# Instructions: xxxxxx
#	
# Tested with: xxxxx
# Arguments: xxxxxx
# Output: Standard Out
#
# Notes:  
# --------------------------------------------------------------------------------------------

###Functions
function wait_app_start () {
    appName=$1
    checkMax=120

    appCheck=true
    checkCount=1

    if pgrep -f /Applications/$appName > /dev/null ; then 
        appCheck=false
    fi

    while [ "$appCheck" = true ] ; do

        sleep 1.0
        if pgrep -f /Applications/$appName > /dev/null ; then
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
    appName=$1
    checkMax=7200

    appCheck=true
    checkCount=1

    if ! pgrep -f /Applications/$appName > /dev/null ; then 
        appCheck=false
    fi

    while [ "$appCheck" = true ] ; do
        sleep 1.0
        if ! pgrep -f /Applications/$appName > /dev/null ; then
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

    osascript -e 'tell app "Terminal" to do script "xcode-select --install"'

    log_and_color -i -f $logfile "Waiting for Xcode.app to start"
    wait_app_start Xcode.app
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Xcode.app started"
        log_and_color -i -f $logfile "Waiting for Xcode.app to stop"
        wait_app_stop Xcode.app
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
    brew install $1 && log_and_color -s -f $logfile "$1 successfully installed" || log_and_color -e -f $logfile "ERROR: $1 install failed"
}

function install_app () {
    log_and_color -s -f $logfile "Starting install for: $1"
    brew install --cask $1 && log_and_color -s -f $logfile "$1 successfully installed" || log_and_color -e -f $logfile "ERROR: $1 install failed"   
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
if [ `whoami` != root ]; then
    log_and_color -e -f $logfile "ERROR: This script must be run as root or using sudo. Exiting"
    exit
fi
###End Admin Check

###Xcode Install
if ! xcode-select -p > /dev/null ; then
    log_and_color -i -f $logfile "Running: xcode-select --install"
    xcode-select --install
    #install_xcode
    if [ $? -eq 0 ]; then
        log_and_color -s -f $logfile "Xcode successfully installed"
        log_and_color -w -f $logfile "Reboot required. Reboot and restart setup script"
        #shutdown -r now
    else
        log_and_color -e -f $logfile "ERROR: Xcode was not installed. Exiting"
    fi
    exit
fi
###End Xcode Install

####Working code ends here
log_and_color -w -f $logfile "Reached end of tested code, exiting"
exit

###Install Updates/OS Patches
log_and_color -i -f $logfile "Running: softwareupdate --all --install --force"
softwareupdate --all --install --force && log_and_color -s -f $logfile "Software update successfully completed" || log_and_color -e -f $logfile "ERROR: Software update failed"
###EndInstall Updates/OS Patches

###VIM Setup
#This should be a file stored in GitHub then pulled down but for now this will do.
log_and_color -i -f $logfile "Setting VIM Enviroment"
if [ ! -f "$HOME/.vimrc" ]; then
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
fi
#End VIM Setup

###Homebrew Setup (non-admin post install version)
if [ ! -d $HOME/homebrew ]; then
    cd $HOME
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
    eval "$(homebrew/bin/brew shellenv)"
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"
    export PATH=$PATH:$HOME/homebrew/bin
    echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc
fi
###End Homebrew Setup (non-admin post install version)

###Shell Setup
if [ ! -d $HOME/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    #Readd PATH settings to .zshrc
    echo "" >> .zshrc
    echo "# Added by $USER" >> .zshrc
    echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc
    #Add zsh syntax highlighting
    install_tool zsh-syntax-highlighting && echo "source \$HOME/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> .zshrc
fi
###End Shell Setup

###Standard App Installs
STDAPPS=( "Slack:slack"
        "Google Chrome:google-chrome"
        "Zoom:zoom"
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

    if ! brew list "$VALUE"; then
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

    if ! brew list "$VALUE"; then
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

    if ! brew list "$VALUE"; then
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
if ! brew list theharvester; then
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
if ! brew list wireshark; then
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
    if [ ! -z "$NEW_DOMAIN_NAME" ]; then NEW_DOMAIN_NAME="local"; fi
    log_and_color -i -f $logfile "Renaming computer to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
    scutil --set HostName "$NEW_HOST_NAME.$NEW_DOMAIN_NAME" && log_and_color -i -g $logfile "HostName set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME" || log_and_color -i -g $logfile "ERROR: HostName was not set to $NEW_HOST_NAME.$NEW_DOMAIN_NAME"
    scutil --set LocalHostName "$NEW_HOST_NAME" && log_and_color -i -g $logfile "LocalHostName set to $NEW_HOST_NAME" || log_and_color -i -g $logfile "ERROR: LocalHostName was not set to $NEW_HOST_NAME"
    scutil --set ComputerName "$NEW_HOST_NAME" && log_and_color -i -g $logfile "ComputerName set to $NEW_HOST_NAME" || log_and_color -i -g $logfile "ERROR: ComputerName was not set to $NEW_HOST_NAME"
    dscacheutil -flushcache

    while true; do
        echo
        echo "$(tput setaf 3)A final reboot is required "
        read -p "$(tput setaf 3)Reboot computer? (y or n): " yn
        case $yn in
            [Yy]* ) log_and_color -i -f $logfile "Setup complete, rebooting";shutdown -r now; break;;
            [Nn]* ) break; exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done

fi
###End Rename Computer

###Misc. Output and reminders to screen
#
#Zoom for OWA
#Zoom for Outlook
#Outlook Calendar for Slack
#Edge Security Settings
#zsh prompt
#apple id
#icon clean up
#if intune/ms company portal, log in
#terminal prefferences
#finder prefferences
#rename computer (before removing admin rights)
###

#Warning - Not A Script
echo "This 'script' is not a script. It is a history of the commands I type to setup my environment. Copy paste to victory."
exit


##Homebrew Prerequisites
xcode-select --install


##Homebrew Setup (non-admin version)
cd $HOME
mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
eval "$(homebrew/bin/brew shellenv)"
brew update --force --quiet
chmod -R go-w "$(brew --prefix)/share/zsh"
export PATH=$PATH:$HOME/homebrew/bin
echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc


##Minimal VIM Setup
echo "filetype plugin indent on" >> $HOME/.vimrc
echo "set term=builtin_ansi" >> $HOME/.vimrc
echo "syntax on" >> $HOME/.vimrc


##Install Updates/OS Patches
softwareupdate --all --install --force


##Shell Setup
#brew install zsh #Install latest zsh, commented out, requires additional non-document steps
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
#Readd PATH settings to .zshrc
echo "" >> .zshrc
echo "# Added by $USER" >> .zshrc
echo "export PATH=\$PATH:\$HOME/homebrew/bin" >> .zshrc
#Add zsh syntax highlighting
brew install zsh-syntax-highlighting
echo "source \$HOME/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> .zshrc


##Install command line tools
#Security tools
#brew install nmap
#brew install testssl
#brew install hashcat
#brew install theharvester
###echo "export PATH=\$PATH:\$HOME/homebrew/etc/theharvester" >> .zshrc
####/Library/Developer/CommandLineTools/usr/bin/python3 -m pip install --upgrade pip
#brew install wireshark
#Security apps
#brew install --cask wireshark
#brew install --cask wireshark-chmodbpf


##Install applications
#Standard apps
brew install --cask vlc
brew install --cask visual-studio-code
brew install --cask slack
brew install --cask google-chrome
brew install --cask github
brew install --cask keka
brew install --cask appcleaner
brew install --cask signal

#Frequent apps
#brew install --cask powershell
#brew install --cask zoom
#brew install --cask microsoft-teams
#brew install --cask microsoft-edge



##To be scripted app installs and add-ons
#Zoom for OWA
#Zoom for Outlook
#Outlook Calendar for Slack


##Create hidden admin account
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
log_and_color -i -f $logfile "Local admin username set to: $LOCAL_ADMIN_SHORTNAME"

#LOCAL_ADMIN_FULLNAME="crash"     # The local admin user's full name
#LOCAL_ADMIN_SHORTNAME="crash"     # The local admin user's shortname
sudo sysadminctl -addUser $LOCAL_ADMIN_SHORTNAME -fullName "$LOCAL_ADMIN_FULLNAME" -admin -home /var/$LOCAL_ADMIN_SHORTNAME #-password "$LOCAL_ADMIN_PASSWORD"
sudo dscl . create /Users/$LOCAL_ADMIN_SHORTNAME IsHidden 1
sudo dscl . -delete "/SharePoints/$LOCAL_ADMIN_FULLNAME's Public Folder" # Removes the public folder sharepoint for the local admin if it was created
sudo dscl . -passwd /Users/$LOCAL_ADMIN_SHORTNAME

##Remove admin permissions for standard account and create scripts to re-add with hidden admin account
echo "sudo dseditgroup -o edit -a $USER -t user admin" > $HOME/Public/add-admin.sh
sudo chmod +x $HOME/Public/add-admin.sh
echo "sudo dseditgroup -o edit -d $USER -t user admin" > $HOME/Public/remove-admin.sh
sudo chmod +x $HOME/Public/remove-admin.sh
sudo dseditgroup -o edit -d $USER -t user admin
