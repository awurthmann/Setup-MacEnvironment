#!/bin/bash
#my-environment-setup.sh
#System: C02H35QLQ05G
#Company: Cision
#Date: May 11, 2022

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
echo "export PATH=$PATH:$HOME/homebrew/bin" >> .zshrc


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
#brew install theharvester
#brew install nmap
#brew install testssl
#brew install hashcat
#brew install wireshark


##Install applications
#Standard apps
brew install --cask vlc
brew install --cask visual-studio-code
brew install --cask slack
brew install --cask google-chrome
brew install --cask github
brew install --cask keka
brew install --cask appcleaner
#Frequent apps
#brew install --cask powershell
#brew install --cask zoom
#brew install --cask microsoft-teams
#brew install --cask microsoft-edge
#Security apps
#brew install --cask wireshark
#brew install --cask wireshark-chmodbpf


##Create hidden admin account
LOCAL_ADMIN_FULLNAME="crash"     # The local admin user's full name
LOCAL_ADMIN_SHORTNAME="crash"     # The local admin user's shortname
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