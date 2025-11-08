# logitech-gaming-mouse-button-remap
Fix Linux button remapping for Logitech gaming mice with keyboard-mode buttons (G502, G604, etc)
# Logitech Gaming Mouse Button Remap for Linux

Fix for Logitech gaming mice (G502, G604, G703, etc.) that have buttons sending keyboard combinations instead of clean mouse buttons on Linux.

## The Problem

Many Logitech gaming mice have extra buttons that are hardcoded at the firmware level to send keyboard key combinations like `Ctrl+Alt+3` or `Alt+4`. This makes them unusable for most applications and games.

**Symptoms:**
- Pressing mouse buttons triggers keyboard shortcuts
- Buttons send `^[` (escape) characters in terminal
- Can't bind mouse buttons in games because they're seen as keyboard combos
- Piper can't remap these buttons (they're not detected as mouse buttons)

**Why this happens:**
The mouse reports these buttons through a "keyboard" interface instead of the mouse interface, sending key events that include modifier keys (Ctrl, Alt) before the actual button number.

## The Solution

This script uses `evsieve` to intercept the keyboard events from your mouse and remap them to clean key presses, making the buttons usable in games and applications.

**Before:** Button press → `Ctrl+Alt+3`  
**After:** Button press → `3`

## Requirements

- Linux (tested on Manjaro/Arch, should work on any distro)
- `evsieve` - The key remapping tool
- `xinput` - Usually pre-installed
- `systemd` - For making the fix permanent

## Installation

### 1. Install evsieve

**Arch/Manjaro:**
```bash
yay -S evsieve
# or
paru -S evsieve
```

**Other distros:**
```bash
# Build from source
git clone https://github.com/KarsMulder/evsieve.git
cd evsieve
cargo build --release
sudo cp target/release/evsieve /usr/local/bin/
```

### 2. Download and run the script

```bash
# Download the script
wget https://raw.githubusercontent.com/[YOUR-USERNAME]/logitech-gaming-mouse-button-remap/main/g502-button-remap.sh

# Make it executable
chmod +x g502-button-remap.sh

# Run it
./g502-button-remap.sh
```

The script will:
1. Detect your gaming mouse
2. Guide you through testing buttons
3. Let you choose standard or custom mapping
4. Create a systemd service for automatic startup
5. Enable and start the service

### 3. Test your buttons

Your buttons should now work! The remapping persists across reboots.

## Supported Mice

**Confirmed working:**
- Logitech G502 HERO

**Should work with (untested):**
- Logitech G604
- Logitech G703
- Logitech G403
- Other Logitech mice with "keyboard mode" buttons
- Potentially other brands (Razer, Corsair, SteelSeries) with similar issues

**Tested your mouse?** Please open an issue or PR to add it to the list!

## Custom Mapping

The script supports custom button mappings for mice with different configurations. When prompted, choose option 2 "Custom mapping" and specify:
- What keys each button currently sends (from evtest)
- What key you want it to send instead

## Uninstalling

```bash
sudo systemctl stop evsieve-mouse.service
sudo systemctl disable evsieve-mouse.service
sudo rm /etc/systemd/system/evsieve-mouse.service
sudo systemctl daemon-reload
```

## Troubleshooting

### Buttons still not working after install
```bash
# Check if service is running
sudo systemctl status evsieve-mouse.service

# Restart the service
sudo systemctl restart evsieve-mouse.service

# Check for errors
journalctl -u evsieve-mouse.service -n 50
```

### Script can't detect my mouse
The script will show all input devices. Manually note your mouse's keyboard device ID and enter it when prompted.

### Different buttons need remapping
Run the script and choose option 2 "Custom mapping" to configure any button combination.

## How It Works

1. **Detection:** Script finds gaming mice that report as both pointer and keyboard devices
2. **Testing:** Uses `evtest` to identify which buttons send keyboard combos
3. **Remapping:** Configures `evsieve` to intercept keyboard events from the mouse and strip modifiers
4. **Persistence:** Creates a systemd service that runs at boot

## Contributing

Found a bug? Have a different mouse model? Want to improve the script?

**Contributions welcome!**
- Open an issue with your mouse model and evtest output
- Submit a PR with improvements
- Add your mouse model to the compatibility list

## Credits

- Created by [@patchwork](https://github.com/[YOUR-USERNAME]) after a day of fighting with AI assistants 😄
- Uses [evsieve](https://github.com/KarsMulder/evsieve) by KarsMulder
- Inspired by frustration with "simple" tasks being complicated on Linux

## License

MIT License - Do whatever you want with this code!

## Star History

If this saved you hours of frustration, give it a ⭐!
