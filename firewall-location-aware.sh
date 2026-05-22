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
# Name: firewall-location-aware.sh
# Version: 2026.05.20.1200
# Description: Location-aware macOS Application Firewall enforcement
#
#   Profiles:
#     Home  — On, stealth mode ON, block-all OFF  (YOUR_HOME_SUBNET_PREFIX.0/24 + verified gateway MAC)
#     Away  — On, stealth mode ON, block-all ON   (all other networks / default)
#
#   Home network criteria (both must match):
#     · Local IP in subnet : YOUR_HOME_SUBNET_PREFIX.0/24
#     · Gateway MAC        : YOUR_GATEWAY_IP == YOUR_GATEWAY_MAC
#
#   Installed to : /usr/local/bin/firewall-location-aware.sh
#   Managed by   : /Library/LaunchDaemons/com.user.firewall-location-aware.plist
#   Log          : /var/log/firewall-location-aware.log
# --------------------------------------------------------------------------------------------

FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"
HOME_SUBNET_PREFIX="YOUR_HOME_SUBNET_PREFIX."
GATEWAY_IP="YOUR_GATEWAY_IP"
HOME_GATEWAY_MAC="YOUR_GATEWAY_MAC"
LOGFILE="/var/log/firewall-location-aware.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> "$LOGFILE"
}

apply_home_profile() {
    log "Applying home profile: on, stealth on, block-all off"
    {
        "$FIREWALL" --setglobalstate on
        "$FIREWALL" --setstealthmode on
        "$FIREWALL" --setblockall off
    } >> "$LOGFILE" 2>&1
}

apply_away_profile() {
    log "Applying away profile: on, stealth on, block-all on"
    {
        "$FIREWALL" --setglobalstate on
        "$FIREWALL" --setstealthmode on
        "$FIREWALL" --setblockall on
    } >> "$LOGFILE" 2>&1
}

# Check if any active interface has an IP in the home subnet
on_home_subnet=false
while IFS= read -r ip; do
    if [[ "$ip" == ${HOME_SUBNET_PREFIX}* ]]; then
        on_home_subnet=true
        break
    fi
done < <(ifconfig 2>/dev/null | awk '/inet / {print $2}')

if [ "$on_home_subnet" = true ]; then
    # Ping gateway to populate the ARP cache, then verify its MAC to prevent subnet spoofing
    ping -c 1 -t 2 "$GATEWAY_IP" > /dev/null 2>&1
    current_mac=$(arp -n "$GATEWAY_IP" 2>/dev/null | awk '{print $4}' | tr '[:upper:]' '[:lower:]')

    if [[ "$current_mac" == "$HOME_GATEWAY_MAC" ]]; then
        log "Home network confirmed (gateway MAC matched: $current_mac)"
        apply_home_profile
    else
        log "Gateway MAC mismatch (expected: $HOME_GATEWAY_MAC, got: ${current_mac:-not found}) — applying away profile"
        apply_away_profile
    fi
else
    log "Not on home subnet — applying away profile"
    apply_away_profile
fi
