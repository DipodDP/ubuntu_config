#!/bin/bash
set -e

echo "macOS Remote Access Setup (NoMachine + Tailscale)"
echo "=================================================="
echo ""
echo "This script will help you set up remote access to your Mac from an iPad"
echo "using NoMachine for remote desktop and Tailscale for secure connectivity."
echo ""

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew is not installed. Please run macos_config.sh first."
  exit 1
fi

# Install Tailscale
echo "Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
  brew install --cask tailscale
  echo "Tailscale installed successfully"
else
  echo "Tailscale already installed"
fi

# Start Tailscale
echo ""
echo "Starting Tailscale..."
open -a Tailscale

echo ""
echo "Please complete the following steps:"
echo "1. Click on the Tailscale icon in the menu bar"
echo "2. Click 'Log in' and authenticate in your browser"
echo "3. Wait for connection to establish"
echo ""
read -p "Press Enter after Tailscale is connected..."

# Get Tailscale IP
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "Could not retrieve IP")
TAILSCALE_HOSTNAME=$(hostname)
MAGICNS_NAME=$(tailscale status --json 2>/dev/null | grep -o '"MagicDNSSuffix":"[^"]*"' | cut -d'"' -f4 || echo "")

echo ""
echo "Tailscale Network Information:"
echo "==============================="
echo "Tailscale IPv4: $TAILSCALE_IP"
echo "Hostname: $TAILSCALE_HOSTNAME"
if [ -n "$MAGICNS_NAME" ]; then
  echo "MagicDNS: ${TAILSCALE_HOSTNAME}.${MAGICNS_NAME}"
fi
echo ""

# Install NoMachine
echo "Installing NoMachine..."
if [ ! -d "/Applications/NoMachine.app" ]; then
  brew install --cask nomachine

  echo "NoMachine installed successfully"
else
  echo "NoMachine already installed"
fi

# Open NoMachine
echo ""
echo "Starting NoMachine..."
open -a NoMachine

# macOS permissions reminder
echo ""
echo "==========================================================="
echo "IMPORTANT: macOS Permissions Setup"
echo "==========================================================="
echo ""
echo "For NoMachine to work properly, you need to grant permissions:"
echo ""
echo "1. Go to: System Settings → Privacy & Security"
echo "2. Grant the following permissions to NoMachine:"
echo "   - Screen Recording"
echo "   - Accessibility"
echo "   - Full Disk Access (if prompted)"
echo ""
echo "3. Keep NoMachine running (it runs automatically on startup)"
echo ""
read -p "Press Enter after granting permissions..."

# Configure NoMachine
echo ""
echo "==========================================================="
echo "NoMachine Configuration"
echo "==========================================================="
echo ""
echo "NoMachine server is now running on this Mac."
echo "Default port: 4000"
echo ""
echo "To change settings:"
echo "1. Open NoMachine"
echo "2. Click on the settings icon"
echo "3. Adjust connection options as needed"
echo ""

# iPad setup instructions
echo ""
echo "==========================================================="
echo "iPad Client Setup Instructions"
echo "==========================================================="
echo ""
echo "On your iPad:"
echo ""
echo "1. Install Tailscale from the App Store"
echo "   - Sign in with the SAME account you used on this Mac"
echo "   - Toggle the VPN ON"
echo "   - Wait for 'Connected' status"
echo ""
echo "2. Install NoMachine from the App Store"
echo "   - Open the app"
echo "   - Tap 'New Connection'"
echo "   - Enter the following:"
echo "     • Host: $TAILSCALE_IP"
if [ -n "$MAGICNS_NAME" ]; then
  echo "       (or: ${TAILSCALE_HOSTNAME}.${MAGICNS_NAME})"
fi
echo "     • Protocol: NX"
echo "     • Port: 4000"
echo "   - Save and connect"
echo "   - Authenticate with your Mac username and password"
echo ""

# Save connection info to file
cat > ~/Desktop/remote_access_info.txt <<EOF
===========================================
Mac Remote Access Information
===========================================
Date: $(date)

Tailscale Information:
- IPv4 Address: $TAILSCALE_IP
- Hostname: $TAILSCALE_HOSTNAME
EOF

if [ -n "$MAGICNS_NAME" ]; then
  echo "- MagicDNS: ${TAILSCALE_HOSTNAME}.${MAGICNS_NAME}" >> ~/Desktop/remote_access_info.txt
fi

cat >> ~/Desktop/remote_access_info.txt <<EOF

NoMachine Information:
- Port: 4000
- Protocol: NX

iPad Connection Settings:
- Host: $TAILSCALE_IP
- Port: 4000
- Protocol: NX
- Credentials: Your Mac username and password

Troubleshooting:
- Ensure Tailscale is connected on both devices
- Verify macOS permissions for NoMachine
- Check that NoMachine is running
- Try using MagicDNS hostname if IP doesn't work

For NoMachine settings:
- Open NoMachine → Settings icon
- Default location: /Applications/NoMachine.app
EOF

echo ""
echo "Connection information saved to: ~/Desktop/remote_access_info.txt"
echo ""

echo "==========================================================="
echo "Setup Complete!"
echo "==========================================================="
echo ""
echo "Your Mac is now accessible via Tailscale from your iPad."
echo ""
echo "Quick Test:"
echo "1. Ensure Tailscale shows 'Connected' on both devices"
echo "2. Open NoMachine on iPad"
echo "3. Connect using: $TAILSCALE_IP"
echo "4. Enter your Mac credentials"
echo ""
echo "Troubleshooting tips:"
echo "- If connection fails, check Tailscale status: tailscale status"
echo "- Restart NoMachine if screen sharing doesn't work"
echo "- Check macOS Firewall settings if needed"
echo ""
