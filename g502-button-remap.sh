#!/bin/bash

# G502 Button Remapper for Linux
# Fixes Logitech gaming mice with "keyboard mode" buttons
# Created by: patchwork (GitHub: [your-username])
# License: MIT

set -e

echo "=================================================="
echo "  Logitech Gaming Mouse Button Remapper"
echo "  Fixes buttons that send Ctrl/Alt combos"
echo "=================================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Please run as normal user (not sudo)"
    echo "   The script will ask for sudo when needed"
    exit 1
fi

# Check if evsieve is installed
if ! command -v evsieve &> /dev/null; then
    echo "❌ evsieve is not installed!"
    echo ""
    echo "Install it with:"
    echo "  yay -S evsieve    (Arch/Manjaro)"
    echo "  Or from: https://github.com/KarsMulder/evsieve"
    exit 1
fi

echo "✓ evsieve is installed"
echo ""

# Show available input devices
echo "🔍 Detecting your gaming mouse..."
echo ""
echo "Here are your input devices:"
echo ""
xinput list
echo ""

# Look for gaming mice with keyboard components
echo "Looking for gaming mice with keyboard buttons..."
gaming_mice=$(xinput list | grep -iE "(logitech|razer|corsair|steelseries)" | grep -i "keyboard" || true)

if [[ -z "$gaming_mice" ]]; then
    echo ""
    echo "⚠️  No gaming mouse keyboard devices auto-detected."
    echo "    This might be a different brand or model."
    echo ""
else
    echo ""
    echo "Found potential gaming mouse keyboard device(s):"
    echo "$gaming_mice"
    echo ""
fi

# Ask user to identify their device
echo "=================================================="
echo "  DEVICE SELECTION"
echo "=================================================="
echo ""
echo "Look at the list above and find your mouse's"
echo "KEYBOARD device (usually has 'Keyboard' in name)."
echo ""
echo "Example: 'Logitech G502 HERO Gaming Mouse Keyboard  id=14'"
echo ""
read -p "Enter the device ID number: " device_id

if [[ ! "$device_id" =~ ^[0-9]+$ ]]; then
    echo "❌ Invalid ID. Must be a number."
    exit 1
fi

# Get the event number for this device
event_num=$(xinput list-props "$device_id" 2>/dev/null | grep "Device Node" | grep -oP '/dev/input/event\K[0-9]+' || true)

if [[ -z "$event_num" ]]; then
    echo "❌ Could not find event device for ID $device_id"
    echo "   Make sure you entered the correct ID number"
    exit 1
fi

device_name=$(xinput list | grep "id=$device_id" | grep -oP '↳\s+\K[^→]+' | sed 's/\s*id=.*$//' | xargs)

echo ""
echo "✓ Selected: $device_name"
echo "✓ Event device: /dev/input/event$event_num"
echo ""

# Test buttons
echo "=================================================="
echo "  BUTTON DETECTION"
echo "=================================================="
echo ""
echo "Let's test which buttons need remapping."
echo ""
echo "In a moment, evtest will run. You should:"
echo "  1. Press each of your mouse buttons"
echo "  2. Look for buttons that show KEY_LEFTCTRL or KEY_LEFTALT"
echo "  3. Note the KEY_ codes (like KEY_3, KEY_4, etc.)"
echo "  4. Press Ctrl+C when done"
echo ""
read -p "Press Enter to start button detection..."
echo ""

echo "Running evtest... Press your problematic mouse buttons:"
echo "(Press Ctrl+C when finished)"
echo ""

# Run evtest but don't exit script when user presses Ctrl+C
(sudo evtest /dev/input/event$event_num) || true

echo ""
echo "(evtest stopped)"
echo ""
echo "=================================================="
echo "  CONFIGURATION"
echo "=================================================="
echo ""
echo "Choose your configuration:"
echo ""
echo "1. Standard Logitech G502 mapping:"
echo "   Button: Ctrl+Alt+3 → 3"
echo "   Button: Alt+4 → 4"
echo ""
echo "2. Custom mapping (you specify the keys)"
echo ""
read -p "Enter choice [1-2]: " config_choice

hooks=""
blocks=""

if [[ "$config_choice" == "1" ]]; then
    hooks="--hook key:leftctrl key:leftalt key:3 send-key=key:3 --hook key:leftalt key:4 send-key=key:4"
    blocks="--block key:leftctrl key:leftalt"
    
elif [[ "$config_choice" == "2" ]]; then
    echo ""
    echo "=================================================="
    echo "  CUSTOM MAPPING"
    echo "=================================================="
    echo ""
    echo "Based on what you saw in evtest, enter the keys."
    echo "Use lowercase (leftctrl, leftalt, rightctrl, etc.)"
    echo ""
    echo "Example from evtest:"
    echo "  Event: KEY_LEFTCTRL, value 1"
    echo "  Event: KEY_LEFTALT, value 1"
    echo "  Event: KEY_5, value 1"
    echo "  → This button sends: Ctrl+Alt+5"
    echo ""
    
    mappings=()
    modifiers_to_block=()
    
    while true; do
        echo "----------------------------------------"
        read -p "Add a button mapping? [Y/n]: " add_more
        if [[ $add_more =~ ^[Nn] ]]; then
            break
        fi
        
        echo ""
        echo "What does this button currently send?"
        echo "(Enter each key, one per line. Press Enter on empty line when done)"
        echo ""
        
        current_keys=()
        while true; do
            read -p "Key (or press Enter if done): " key
            if [[ -z "$key" ]]; then
                break
            fi
            # Remove KEY_ prefix if user added it
            key=$(echo "$key" | sed 's/^KEY_//i' | tr '[:upper:]' '[:lower:]')
            current_keys+=("$key")
        done
        
        if [[ ${#current_keys[@]} -eq 0 ]]; then
            echo "No keys entered, skipping..."
            continue
        fi
        
        echo ""
        echo "Current keys: ${current_keys[*]}"
        echo ""
        read -p "What should this button send instead? (single key): " target_key
        target_key=$(echo "$target_key" | sed 's/^KEY_//i' | tr '[:upper:]' '[:lower:]')
        
        # Build hook command
        hook_keys=$(printf "key:%s " "${current_keys[@]}")
        mappings+=("--hook $hook_keys send-key=key:$target_key")
        
        # Collect modifiers to block
        for key in "${current_keys[@]}"; do
            if [[ "$key" =~ (left|right)?(ctrl|alt|shift|meta) ]] && [[ ! " ${modifiers_to_block[@]} " =~ " ${key} " ]]; then
                modifiers_to_block+=("$key")
            fi
        done
        
        echo "✓ Added mapping: ${current_keys[*]} → $target_key"
        echo ""
    done
    
    if [[ ${#mappings[@]} -eq 0 ]]; then
        echo ""
        echo "❌ No mappings configured. Exiting."
        exit 1
    fi
    
    hooks="${mappings[*]}"
    
    if [[ ${#modifiers_to_block[@]} -gt 0 ]]; then
        block_keys=$(printf "key:%s " "${modifiers_to_block[@]}")
        blocks="--block $block_keys"
    fi
    
    echo ""
    echo "Summary of mappings:"
    for mapping in "${mappings[@]}"; do
        echo "  $mapping"
    done
    echo ""
    if [[ -n "$blocks" ]]; then
        echo "Blocking modifiers: $blocks"
        echo ""
    fi
    read -p "Looks good? [Y/n]: " confirm
    if [[ $confirm =~ ^[Nn] ]]; then
        echo "Aborting."
        exit 0
    fi
    
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo ""
echo "Creating evsieve service..."

# Create systemd service
SERVICE_FILE="/etc/systemd/system/evsieve-mouse.service"

evsieve_cmd="/usr/bin/evsieve --input /dev/input/event$event_num domain=mouse grab $hooks $blocks --output"

sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=Evsieve mouse button remapper for $device_name
After=multi-user.target

[Service]
Type=simple
ExecStart=$evsieve_cmd
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "✓ Service file created"

# Enable and start service
echo "Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable evsieve-mouse.service
sudo systemctl start evsieve-mouse.service

echo ""
echo "=================================================="
echo "  ✓ SUCCESS!"
echo "=================================================="
echo ""
echo "Your mouse buttons are now remapped!"
echo ""
echo "Test your thumb buttons - they should now send"
echo "just 3 and 4 without Ctrl/Alt modifiers."
echo ""
echo "Useful commands:"
echo "  sudo systemctl status evsieve-mouse.service  # Check status"
echo "  sudo systemctl restart evsieve-mouse.service # Restart service"
echo "  sudo systemctl stop evsieve-mouse.service    # Stop service"
echo "  sudo systemctl disable evsieve-mouse.service # Disable on boot"
echo ""
echo "To uninstall completely:"
echo "  sudo systemctl stop evsieve-mouse.service"
echo "  sudo systemctl disable evsieve-mouse.service"
echo "  sudo rm $SERVICE_FILE"
echo "  sudo systemctl daemon-reload"
echo ""
echo "=================================================="
echo ""
echo "🎉 Enjoy your remapped buttons!"
echo ""