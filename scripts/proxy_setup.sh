#!/bin/bash
set -e

# Validate environment
if [ -z "$SCRIPT_DIR" ]; then
  echo "Error: SCRIPT_DIR not set. This script must be called from macos_config.sh"
  exit 1
fi

if [ -z "$SILENT_MODE" ]; then
  echo "Warning: SILENT_MODE not set, defaulting to false"
  SILENT_MODE=false
fi

# Proxy configuration
choice="n"  # Initialize to prevent unbound variable error
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to configure proxy settings? (y/N): " choice
fi
if [ "$choice" = "y" ]; then
  echo ""
  echo "=== Proxy Configuration Options ==="
  echo ""
  echo "1. System Proxy Sync - Auto-sync with macOS system proxy settings"
  echo "2. v2rayA - Advanced proxy with shunt rules (selective routing)"
  echo "3. Both"
  echo "4. Skip"
  echo ""
  read -p "Enter choice [1-4]: " proxy_choice

  # Option 1 or 3: System Proxy Sync
  if [ "$proxy_choice" = "1" ] || [ "$proxy_choice" = "3" ]; then
    echo ""
    echo "=== System Proxy Sync Setup ==="
    echo ""
    echo "This will create a script that automatically syncs macOS system proxy"
    echo "settings to your terminal environment variables."
    echo ""

    # Create sync-proxy.sh script
    cat > ~/sync-proxy.sh <<'EOF'
#!/bin/bash

# Check if HTTP proxy is enabled in system settings
HTTP_ENABLE=$(scutil --proxy | grep "HTTPEnable" | awk '{print $3}')

if [[ "$HTTP_ENABLE" == "1" ]]; then
  # Get HTTP proxy host and port
  HTTP_HOST=$(scutil --proxy | grep "HTTPProxy" | awk '{print $3}')
  HTTP_PORT=$(scutil --proxy | grep "HTTPPort" | awk '{print $3}')

  if [[ -n "$HTTP_HOST" ]] && [[ -n "$HTTP_PORT" ]]; then
    export http_proxy="http://${HTTP_HOST}:${HTTP_PORT}"
  fi
else
  # Proxy disabled in system settings
  unset http_proxy
  unset all_proxy
fi

# Check if SOCKS proxy is enabled
SOCKS_ENABLE=$(scutil --proxy | grep "SOCKSEnable" | awk '{print $3}')

if [[ "$SOCKS_ENABLE" == "1" ]]; then
  SOCKS_HOST=$(scutil --proxy | grep "SOCKSProxy" | awk '{print $3}')
  SOCKS_PORT=$(scutil --proxy | grep "SOCKSPort" | awk '{print $3}')

  if [[ -n "$SOCKS_HOST" ]] && [[ -n "$SOCKS_PORT" ]]; then
    export all_proxy="socks5://${SOCKS_HOST}:${SOCKS_PORT}"
  fi
fi
EOF

    chmod +x ~/sync-proxy.sh
    echo "Created ~/sync-proxy.sh"

    # Add to .zshrc
    if ! grep -q "sync-proxy.sh" ~/.zshrc; then
      cat >> ~/.zshrc <<'EOF'

# Auto-sync macOS system proxy to terminal
source ~/sync-proxy.sh

# Alias to manually sync proxy settings
alias proxy-sync='source ~/sync-proxy.sh'
EOF
      echo "Added sync-proxy.sh to ~/.zshrc"
    fi

    echo ""
    echo "System proxy sync configured!"
    echo ""
    echo "Your terminal will now automatically use macOS system proxy settings."
    echo "Configure proxy: System Settings > Network > [Your Network] > Proxies"
    echo ""
    echo "Commands:"
    echo "  proxy-sync      - Manually sync proxy settings"
    echo "  proxy_status    - View current proxy settings"
    echo ""
  fi

  # Option 2 or 3: v2rayA
  if [ "$proxy_choice" = "2" ] || [ "$proxy_choice" = "3" ]; then
    echo ""
    echo "=== v2rayA Configuration with Shunt Rules ==="
    echo ""
    echo "v2rayA provides shunt rules for selective proxying:"
    echo ""
    echo "Port Comparison:"
    echo "  - Port 20171: Basic HTTP proxy (all traffic proxied)"
    echo "  - Port 20172: HTTP with shunt rules (selective routing)"
    echo ""
    echo "Shunt rules enable selective proxying based on:"
    echo "  - Domains (e.g., proxy only GitHub)"
    echo "  - Geosites (e.g., proxy only foreign sites)"
    echo "  - IP addresses"
    echo ""

    read -p "Do you want to install v2rayA? (y/N): " install_v2raya
    if [ "$install_v2raya" = "y" ]; then
      echo "Installing v2rayA..."
      brew install v2raya

      echo ""
      echo "v2rayA installed successfully!"
      echo ""
      echo "To start v2rayA:"
      echo "  brew services start v2raya"
      echo ""
      echo "Access web interface at: http://localhost:2017"
      echo ""

      read -p "Do you want to add v2rayA proxy functions to ~/.zshrc? (y/N): " add_v2ray_env
      if [ "$add_v2ray_env" = "y" ]; then
        if ! grep -q "v2rayA proxy" ~/.zshrc; then
          cat >> ~/.zshrc <<'EOF'

# v2rayA proxy configuration (with shunt rules on port 20172)
# Functions to enable/disable v2rayA proxy
v2ray_proxy_on() {
  export http_proxy=http://127.0.0.1:20172
  export all_proxy=socks5://127.0.0.1:20170
  echo "✓ v2rayA proxy enabled (with shunt rules)"
}

v2ray_proxy_off() {
  unset http_proxy
  unset all_proxy
  echo "✓ v2rayA proxy disabled"
}

# Alias for basic proxy without shunt rules
v2ray_proxy_basic() {
  export http_proxy=http://127.0.0.1:20171
  export all_proxy=socks5://127.0.0.1:20170
  echo "✓ v2rayA basic proxy enabled (no shunt rules)"
}
EOF
          echo "v2rayA proxy functions added to ~/.zshrc"
          echo ""
          echo "Commands:"
          echo "  v2ray_proxy_on    - Enable v2rayA with shunt rules (port 20172)"
          echo "  v2ray_proxy_basic - Enable v2rayA without shunt rules (port 20171)"
          echo "  v2ray_proxy_off   - Disable v2rayA proxy"
        fi
      fi
    else
      echo "Skipping v2rayA installation"
      echo "You can install it later with: brew install v2raya"
    fi
  fi

  # Add general proxy status function if not already present
  if ! grep -q "proxy_status()" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# Check current proxy settings
proxy_status() {
  echo "=== Current Proxy Settings ==="
  echo ""
  echo "Terminal environment variables:"
  echo "  http_proxy:  ${http_proxy:-<not set>}"
  echo "  https_proxy: ${https_proxy:-<not set>}"
  echo "  all_proxy:   ${all_proxy:-<not set>}"
  echo ""
  echo "macOS system proxy (scutil --proxy):"
  scutil --proxy | grep -E "HTTPEnable|HTTPProxy|HTTPPort|HTTPSEnable|HTTPSProxy|HTTPSPort|SOCKSEnable|SOCKSProxy|SOCKSPort"
}
EOF
    echo "Added proxy_status function to ~/.zshrc"
  fi
fi
