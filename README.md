# Setup-MacEnvironment

Script used to re-setup my test system(s) after being reset to "Factory Defaults". Installs Homebrew, configures the shell environment, installs applications and security tools, applies system hardening, and sets up a location-aware firewall.

Tested with macOS 26.5.x (Tahoe).

## Legal

You the executor, runner, user accept all liability.
This code comes with ABSOLUTELY NO WARRANTY.
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

## Instructions

Run directly from GitHub:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/awurthmann/Setup-MacEnvironment/main/Setup-MacEnvironment.sh)"
```

Or download and run manually:

```bash
chmod +x ./Setup-MacEnvironment.sh
./Setup-MacEnvironment.sh
```

> The script may require multiple restarts and/or system reboots to fully complete. A log is written to `~/Documents/Setup-MacEnvironment.log`. The script is safe to restart — completed sections are skipped automatically.

---

## What It Does

### System Setup
- Installs Xcode Command Line Tools
- Applies macOS software updates
- Downloads `.vimrc` configuration
- Installs and configures Homebrew (Apple Silicon and Intel aware)
- Installs oh-my-zsh with zsh-syntax-highlighting
- Renames the computer (optional)

### Applications
Each application is prompted individually (y/n).

**Standard**
Slack, Google Chrome, Mozilla Firefox, DuckDuckGo Browser, Warp Terminal, Jabra Direct, Visual Studio Code, PyCharm CE, VLC Media Player, GitHub Desktop, Keka, AppCleaner, Signal, OnlySwitch, Maccy, ProNotes, Cyberduck

**Microsoft**
Remote Desktop, PowerShell

**Security Tools**
nmap, testssl, hashcat, TheHarvester, Wireshark

CLI aliases for `code` and `pycharm` are added to `.zshrc` automatically if the respective apps are installed.

### Hardening
Each hardening step is prompted individually (y/n) and only runs once — completed steps are skipped on restart.

| Step | What it does |
|------|-------------|
| Disable NetBIOS | Disables `com.apple.netbiosd` and writes `/etc/nsmb.conf` to suppress NetBIOS over SMB |
| Disable Sharing Services | Disables AFP, SMB, Screen Sharing, Printer Sharing, Remote Login (SSH), Remote Management (ARD) |
| Enable Firewall | Enables the Application Firewall with block-all incoming connections and stealth mode |
| Secure Keyboard Entry | Enables Secure Keyboard Entry for Terminal.app |

> AirPlay Receiver and Media Sharing cannot be disabled via script — reminders are shown at the end.

### Location-Aware Firewall

Installs `firewall-location-aware.sh` as a root LaunchDaemon that enforces firewall profiles based on network location.

| Network | Firewall profile |
|---------|-----------------|
| Home (subnet + gateway MAC match) | On · Stealth ON · Block-all **OFF** |
| Away / unknown | On · Stealth ON · Block-all **ON** |

- Triggers immediately on network configuration changes (`WatchPaths`)
- Polls every 60 seconds as a fallback
- Configured interactively at install time — prompts for home subnet prefix, gateway IP, and gateway MAC address
- Gateway MAC verification prevents subnet spoofing

### PARA File System
Creates a PARA-method folder structure (`_PROJECTS`, `_AREAS`, `_ARCHIVE`, `_RESOURCES`) under a configurable base directory and optionally sets the macOS screenshot save location to `_RESOURCES/Screen Shots`.

### Hidden Admin Account
Creates a hidden local admin account for privilege recovery without relying on the primary user account. Optional — prompted at runtime.

---

## Files

| File | Description |
|------|-------------|
| `Setup-MacEnvironment.sh` | Main setup script |
| `firewall-location-aware.sh` | Location-aware firewall script — installed to `/usr/local/bin/` with network values substituted at setup time |
| `com.user.firewall-location-aware.plist` | LaunchDaemon — installed to `/Library/LaunchDaemons/` |
| `.vimrc` | Vim configuration — downloaded to `~/.vimrc` if not already present |
