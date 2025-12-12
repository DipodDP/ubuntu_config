#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Cross-Platform Sibling User Setup Script v3
# Works on: Linux (Ubuntu, Debian, etc.) and macOS
#
# USAGE:
#   sudo ./create_sibling_user_v3.sh
#   - Auto-detects current user and creates sibling with "dev" suffix
#   - Provides interactive prompts to customize usernames
# ============================================================================

# ---- Configuration ----
# Auto-detect current user (when run with sudo, use SUDO_USER)
CURRENT_USER="${SUDO_USER:-$USER}"
USER1="${USER1:-$CURRENT_USER}"      # source owner (can be overridden via prompt)
USER2="${USER2:-${CURRENT_USER}dev}" # destination user (can be overridden via prompt)

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
  HOME_BASE="/Users"
  PRIMARY_GROUP="staff"
else
  OS="linux"
  HOME_BASE="/home"
  PRIMARY_GROUP="${USER1}"
fi

# Initialize paths (will be updated after user configuration)
SRC_HOME="${HOME_BASE}/${USER1}"
DST_HOME="${HOME_BASE}/${USER2}"
SRC_SSH="${SRC_HOME}/.ssh"
DST_SSH="${DST_HOME}/.ssh"

# ---- List of configs to symlink ----
# WARNING: Do NOT symlink .ssh, .local, or entire .config
# Only symlink specific, safe items
CONFIGS_TO_LINK=(
  ".zshrc"
  ".oh-my-zsh"
  ".p10k.zsh"
  ".tmux.conf"
  ".tmux"
  ".docker"
  ".fly"
  ".gitconfig"
  ".config/nvim"    # Symlinked, but with write ACLs
  "sync-proxy.sh"   # If it exists
  # Add more as needed, but be selective
)

# ---- Subdirectories to symlink from .local ----
# NOTE: .local/share is NOT included - must be separate for nvim
LOCAL_SUBDIRS_TO_LINK=(
  "bin"
  "lib"
)

# ============================================================================
# Functions
# ============================================================================

set_acl_linux() {
  local target="$1"
  local user="$2"
  local perms="$3"

  if command -v setfacl >/dev/null 2>&1; then
    setfacl -m "u:${user}:${perms}" "$target" 2>/dev/null || true
    setfacl -m "d:u:${user}:${perms}" "$target" 2>/dev/null || true
  fi
}

set_acl_macos() {
  local target="$1"
  local user="$2"
  local perms="$3"

  # Convert Linux-style permissions to macOS ACL format
  local acl_perms=""
  case "$perms" in
    rwX|rwx)
      acl_perms="list,add_file,search,delete,add_subdirectory,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit"
      ;;
    rX|rx)
      acl_perms="list,search,read,execute,readattr,readextattr,readsecurity,file_inherit,directory_inherit"
      ;;
    r)
      acl_perms="read,readattr,readextattr,readsecurity,file_inherit,directory_inherit"
      ;;
    x)
      acl_perms="list,search,readattr,readextattr,readsecurity"
      ;;
  esac

  chmod +a "user:${user} allow ${acl_perms}" "$target" 2>/dev/null || true
}

set_acl_recursive() {
  local target="$1"
  local user="$2"
  local perms="$3"

  if [ "$OS" = "macos" ]; then
    set_acl_macos "$target" "$user" "$perms"
  else
    set_acl_linux "$target" "$user" "$perms"
    # Recursively set ACL on Linux
    if [ -d "$target" ]; then
      setfacl -R -m "u:${user}:${perms}" "$target" 2>/dev/null || true
      setfacl -R -m "d:u:${user}:${perms}" "$target" 2>/dev/null || true
    fi
  fi
}

# ============================================================================
# Pre-flight checks
# ============================================================================

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ This script must be run with sudo or as root"
  exit 1
fi

if ! id "$USER1" &>/dev/null; then
  echo "❌ User ${USER1} does not exist"
  exit 1
fi

if ! id "$USER2" &>/dev/null; then
  echo "❌ User ${USER2} does not exist. Create it first."
  exit 1
fi

echo "================================"
echo "Sibling User Setup Script v3"
echo "================================"
echo "OS detected: ${OS}"
echo

# Interactive configuration
echo "Current configuration:"
echo "  - Source user: ${USER1}"
echo "  - Destination user: ${USER2}"
echo

read -p "Enter PRIMARY user name [default: ${USER1}]: " input_primary
USER1="${input_primary:-$USER1}"

read -p "Enter SIBLING user suffix [default: dev]: " input_suffix
SUFFIX="${input_suffix:-dev}"

read -p "Enter SIBLING user name [default: ${USER1}${SUFFIX}]: " input_sibling
USER2="${input_sibling:-${USER1}${SUFFIX}}"

# Update paths after user configuration
SRC_HOME="${HOME_BASE}/${USER1}"
DST_HOME="${HOME_BASE}/${USER2}"
SRC_SSH="${SRC_HOME}/.ssh"
DST_SSH="${DST_HOME}/.ssh"

echo
echo "Final configuration:"
echo "  - Source user: ${USER1}"
echo "  - Destination user: ${USER2}"
echo "  - Home base: ${HOME_BASE}"
echo
echo "This script will:"
echo "  1. Set proper permissions on ${USER1}'s home directory"
echo "  2. Create symlinks for dotfiles and configs"
echo "  3. Create symlinks for .local/bin and .local/lib ONLY"
echo "  4. Create INDEPENDENT .local/share (for nvim plugins)"
echo "  5. Copy (NOT symlink) .ssh directory with proper permissions"
echo "  6. Setup Rust/Cargo sharing (if installed)"
echo "  7. Apply ACLs for ${USER2} to access ${USER1}'s files"
echo
read -p "Proceed? [y/N] " yn
case "$yn" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# ============================================================================
# Step 1: Fix base home directory permissions
# ============================================================================

echo
echo "Step 1: Setting up base home directory permissions..."

chmod 755 "${SRC_HOME}"
set_acl_macos "${SRC_HOME}" "${USER2}" "x" 2>/dev/null || set_acl_linux "${SRC_HOME}" "${USER2}" "x"
echo "  ✓ Set ${SRC_HOME} to 755 and added ACL for ${USER2}"

# ============================================================================
# Step 2: Create .local structure with SEPARATE share directory
# ============================================================================

echo
echo "Step 2: Setting up .local directory structure..."

# Ensure source .local exists
if [ ! -d "${SRC_HOME}/.local" ]; then
  sudo -u "${USER1}" mkdir -p "${SRC_HOME}/.local"
fi

chmod 755 "${SRC_HOME}/.local"
set_acl_recursive "${SRC_HOME}/.local" "${USER2}" "rX"

# Create destination .local directory
if [ ! -d "${DST_HOME}/.local" ]; then
  mkdir -p "${DST_HOME}/.local"
  chown "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.local"
  chmod 755 "${DST_HOME}/.local"
fi

# Symlink ONLY bin and lib (NOT share!)
for subdir in "${LOCAL_SUBDIRS_TO_LINK[@]}"; do
  SRC_SUBDIR="${SRC_HOME}/.local/${subdir}"
  DST_SUBDIR="${DST_HOME}/.local/${subdir}"

  # Ensure source exists
  if [ ! -d "$SRC_SUBDIR" ]; then
    sudo -u "${USER1}" mkdir -p "$SRC_SUBDIR"
  fi

  # Set proper permissions on source
  chmod 755 "$SRC_SUBDIR"
  set_acl_recursive "$SRC_SUBDIR" "${USER2}" "rX"

  # Backup existing destination
  if [ -e "$DST_SUBDIR" ] || [ -L "$DST_SUBDIR" ]; then
    ts=$(date +%s)
    mv "$DST_SUBDIR" "${DST_SUBDIR}.bak.${ts}"
    echo "  ⚠️  Backed up existing ${subdir}"
  fi

  # Create symlink
  ln -snf "$SRC_SUBDIR" "$DST_SUBDIR"
  chown -h "${USER2}:${PRIMARY_GROUP}" "$DST_SUBDIR"
  echo "  ✓ Linked ${subdir}: ${DST_SUBDIR} -> ${SRC_SUBDIR}"
done

# Create INDEPENDENT .local/share for USER2
echo "  ℹ️  Creating independent .local/share for ${USER2}..."
if [ ! -d "${DST_HOME}/.local/share" ]; then
  mkdir -p "${DST_HOME}/.local/share"
  chown "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.local/share"
  chmod 755 "${DST_HOME}/.local/share"
  echo "  ✓ Created independent .local/share"
else
  echo "  ✓ .local/share already exists (independent)"
fi

# Create INDEPENDENT .local/state for USER2
if [ ! -d "${DST_HOME}/.local/state" ]; then
  mkdir -p "${DST_HOME}/.local/state"
  chown "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.local/state"
  chmod 755 "${DST_HOME}/.local/state"
  echo "  ✓ Created independent .local/state"
fi

# ============================================================================
# Step 3: Symlink dotfiles and config directories
# ============================================================================

echo
echo "Step 3: Creating symlinks for dotfiles and configs..."

for item in "${CONFIGS_TO_LINK[@]}"; do
  SRC_ITEM="${SRC_HOME}/${item}"
  DST_ITEM="${DST_HOME}/${item}"

  # Skip if source doesn't exist
  if [ ! -e "$SRC_ITEM" ]; then
    echo "  ⚠️  SKIP: ${item} (source doesn't exist)"
    continue
  fi

  # Ensure parent directory exists
  DST_PARENT=$(dirname "$DST_ITEM")
  if [ ! -d "$DST_PARENT" ]; then
    mkdir -p "$DST_PARENT"
    chown "${USER2}:${PRIMARY_GROUP}" "$DST_PARENT"
    chmod 755 "$DST_PARENT"
  fi

  # Backup existing destination
  if [ -e "$DST_ITEM" ] || [ -L "$DST_ITEM" ]; then
    ts=$(date +%s)
    mv "$DST_ITEM" "${DST_ITEM}.bak.${ts}"
    echo "  ⚠️  Backed up existing ${item}"
  fi

  # Set permissions and ACLs on source
  if [ -d "$SRC_ITEM" ]; then
    chmod 755 "$SRC_ITEM"
    # Special handling for .config/nvim - needs write access for lazy-lock.json
    if [[ "$item" == *"nvim"* ]]; then
      chmod 775 "$SRC_ITEM"
      set_acl_macos "$SRC_ITEM" "${USER2}" "rwX" 2>/dev/null || set_acl_recursive "$SRC_ITEM" "${USER2}" "rwX"
      echo "  ✓ Set write ACL on ${item} (for lazy-lock.json)"
    else
      set_acl_recursive "$SRC_ITEM" "${USER2}" "rX"
    fi
  else
    chmod 644 "$SRC_ITEM"
    set_acl_recursive "$SRC_ITEM" "${USER2}" "rX"
  fi

  # Create symlink
  ln -snf "$SRC_ITEM" "$DST_ITEM"
  chown -h "${USER2}:${PRIMARY_GROUP}" "$DST_ITEM"
  echo "  ✓ Linked ${item}"
done

# Fix lazy-lock.json if it exists
if [ -f "${SRC_HOME}/.config/nvim/lazy-lock.json" ]; then
  chmod 666 "${SRC_HOME}/.config/nvim/lazy-lock.json"
  if [ "$OS" = "macos" ]; then
    chmod +a "user:${USER2} allow read,write,append,readattr,writeattr,readextattr,writeextattr,readsecurity" "${SRC_HOME}/.config/nvim/lazy-lock.json" 2>/dev/null || true
  fi
  echo "  ✓ Fixed lazy-lock.json permissions"
fi

# ============================================================================
# Step 4: Fix .config base directory if needed
# ============================================================================

echo
echo "Step 4: Ensuring .config directory is accessible..."

if [ -d "${SRC_HOME}/.config" ]; then
  chmod 755 "${SRC_HOME}/.config"
  set_acl_recursive "${SRC_HOME}/.config" "${USER2}" "rX"
  echo "  ✓ Fixed .config permissions"

  # Fix common restrictive subdirectories
  for subdir in git v2raya; do
    if [ -d "${SRC_HOME}/.config/${subdir}" ]; then
      chmod 755 "${SRC_HOME}/.config/${subdir}"
      set_acl_recursive "${SRC_HOME}/.config/${subdir}" "${USER2}" "rX"
      echo "  ✓ Fixed .config/${subdir}"
    fi
  done
fi

# ============================================================================
# Step 5: Copy (NOT symlink) .ssh directory
# ============================================================================

echo
echo "Step 5: Copying SSH directory (NEVER symlink .ssh)..."

# Backup existing destination .ssh
if [ -e "$DST_SSH" ] || [ -L "$DST_SSH" ]; then
  ts=$(date +%s)
  mv "$DST_SSH" "${DST_SSH}.bak.${ts}"
  echo "  ⚠️  Backed up existing ${DST_SSH}"
fi

# Create destination .ssh directory
mkdir -p "$DST_SSH"
chown "${USER2}:${PRIMARY_GROUP}" "$DST_SSH"
chmod 700 "$DST_SSH"

# Copy SSH files
if [ -d "$SRC_SSH" ]; then
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --copy-unsafe-links "${SRC_SSH}/" "${DST_SSH}/"
    echo "  ✓ Copied SSH files using rsync"
  else
    cp -a "${SRC_SSH}"/* "${DST_SSH}/" 2>/dev/null || true
    echo "  ✓ Copied SSH files using cp"
  fi
else
  echo "  ⚠️  Source .ssh directory doesn't exist"
fi

# Fix ownership and permissions
chown -R "${USER2}:${PRIMARY_GROUP}" "$DST_SSH"
chmod 700 "$DST_SSH"
find "$DST_SSH" -type f -exec chmod 600 {} \; 2>/dev/null || true
find "$DST_SSH" -name "*.pub" -type f -exec chmod 644 {} \; 2>/dev/null || true

# Remove ACLs from .ssh (security)
if [ "$OS" = "linux" ] && command -v setfacl >/dev/null 2>&1; then
  setfacl -R -b "$DST_SSH" 2>/dev/null || true
fi

echo "  ✓ SSH directory copied with secure permissions"

# ============================================================================
# Step 6: Setup Rust/Cargo if installed
# ============================================================================

echo
echo "Step 6: Setting up Rust/Cargo (if installed)..."

if [ -d "${SRC_HOME}/.cargo" ] && [ -d "${SRC_HOME}/.rustup" ]; then
  echo "  ℹ️  Rust is installed for ${USER1}, setting up for ${USER2}..."

  # Create .cargo directory
  mkdir -p "${DST_HOME}/.cargo"
  chown "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.cargo"
  chmod 755 "${DST_HOME}/.cargo"

  # Symlink .cargo/bin
  if [ ! -L "${DST_HOME}/.cargo/bin" ]; then
    ln -sf "${SRC_HOME}/.cargo/bin" "${DST_HOME}/.cargo/bin"
    chown -h "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.cargo/bin"
    chmod 755 "${SRC_HOME}/.cargo/bin"
    set_acl_recursive "${SRC_HOME}/.cargo/bin" "${USER2}" "rX"
    echo "  ✓ Symlinked .cargo/bin"
  fi

  # Symlink .cargo/env
  if [ -f "${SRC_HOME}/.cargo/env" ] && [ ! -L "${DST_HOME}/.cargo/env" ]; then
    ln -sf "${SRC_HOME}/.cargo/env" "${DST_HOME}/.cargo/env"
    chown -h "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.cargo/env"
    set_acl_recursive "${SRC_HOME}/.cargo/env" "${USER2}" "r"
    echo "  ✓ Symlinked .cargo/env"
  fi

  # Create independent registry and git directories
  mkdir -p "${DST_HOME}/.cargo/registry"
  mkdir -p "${DST_HOME}/.cargo/git"
  chown -R "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.cargo/registry"
  chown -R "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.cargo/git"
  echo "  ✓ Created independent cargo registry/git"

  # Symlink .rustup
  if [ ! -L "${DST_HOME}/.rustup" ]; then
    chmod 755 "${SRC_HOME}/.rustup"
    set_acl_recursive "${SRC_HOME}/.rustup" "${USER2}" "rX"
    ln -sf "${SRC_HOME}/.rustup" "${DST_HOME}/.rustup"
    chown -h "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.rustup"
    echo "  ✓ Symlinked .rustup"
  fi

  # Set default toolchain for USER2
  sudo -u "${USER2}" bash << 'EOFRUSTUP' 2>/dev/null || true
if command -v rustup >/dev/null 2>&1; then
  if rustup show 2>&1 | grep -q "no default toolchain"; then
    rustup default stable >/dev/null 2>&1 || true
  fi
fi
EOFRUSTUP

  echo "  ✓ Rust/Cargo setup complete"
else
  echo "  ℹ️  Rust not installed, skipping"
fi

# ============================================================================
# Step 7: Fix executable permissions on binaries
# ============================================================================

echo
echo "Step 7: Ensuring binaries are executable..."

# Fix claude binary if it exists
if [ -d "${SRC_HOME}/.local/share/claude/versions" ]; then
  find "${SRC_HOME}/.local/share/claude/versions" -type f -size +1M -exec chmod 755 {} \; 2>/dev/null || true
  echo "  ✓ Fixed claude binary permissions"
fi

# Fix any other large binaries in .local/share
if [ -d "${SRC_HOME}/.local/share" ]; then
  find "${SRC_HOME}/.local/share" -type f -size +1M -perm -u+r ! -perm -u+x 2>/dev/null | while read -r file; do
    if file "$file" 2>/dev/null | grep -q "executable"; then
      chmod 755 "$file"
    fi
  done 2>/dev/null || true
fi

# ============================================================================
# Step 8: Fix .oh-my-zsh permissions if symlinked
# ============================================================================

if [ -d "${SRC_HOME}/.oh-my-zsh" ]; then
  echo
  echo "Step 8: Ensuring .oh-my-zsh is accessible..."
  chmod 755 "${SRC_HOME}/.oh-my-zsh"
  chmod g-w,o-w "${SRC_HOME}/.oh-my-zsh/custom" 2>/dev/null || true
  if [ "$OS" = "macos" ]; then
    chmod -R +a "user:${USER2} allow read,execute,readattr,readextattr,readsecurity" "${SRC_HOME}/.oh-my-zsh" 2>/dev/null || true
  else
    set_acl_recursive "${SRC_HOME}/.oh-my-zsh" "${USER2}" "rX"
  fi
  echo "  ✓ Fixed .oh-my-zsh permissions"
fi

# ============================================================================
# Step 9: Create user-specific .zshrc.local for overrides
# ============================================================================

echo
echo "Step 9: Creating .zshrc.local for ${USER2}..."

cat > "${DST_HOME}/.zshrc.local" << 'EOFZSHLOCAL'
# User-specific zsh overrides
# Disable oh-my-zsh insecure directory check
ZSH_DISABLE_COMPFIX=true

# Source files if they exist
[ -f ~/sync-proxy.sh ] && source ~/sync-proxy.sh || true
[ -f ~/.cargo/env ] && source ~/.cargo/env || true
EOFZSHLOCAL

chown "${USER2}:${PRIMARY_GROUP}" "${DST_HOME}/.zshrc.local"
chmod 644 "${DST_HOME}/.zshrc.local"
echo "  ✓ Created .zshrc.local"

# ============================================================================
# Summary and Verification
# ============================================================================

echo
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo
echo "What was done:"
echo "  ✓ Fixed ${SRC_HOME} permissions for traversal"
echo "  ✓ Created symlinks for .local/bin and .local/lib"
echo "  ✓ Created INDEPENDENT .local/share (for nvim plugins)"
echo "  ✓ Created symlinks for dotfiles and configs"
echo "  ✓ Copied .ssh directory (not symlinked)"
echo "  ✓ Setup Rust/Cargo sharing (if installed)"
echo "  ✓ Applied ACLs for ${USER2} access"
echo "  ✓ Fixed binary executable permissions"
echo "  ✓ Created .zshrc.local for user overrides"
echo
echo "⚠️  IMPORTANT NOTES:"
echo "  - .local/share is INDEPENDENT (nvim plugins won't conflict)"
echo "  - .config/nvim is SYMLINKED with write access (lazy-lock.json shared)"
echo "  - .ssh is COPIED (not symlinked - security best practice)"
echo "  - .rustup and .cargo/bin are SYMLINKED (shared toolchain)"
echo "  - .cargo/registry is INDEPENDENT (per-user package cache)"
echo
echo "For ${USER2} to fully benefit:"
echo "  - Log out and log back in (to pick up group changes)"
echo "  - Or run: hash -r (to refresh PATH in current shell)"
echo
echo "Verification commands:"
echo "  sudo -u ${USER2} bash -c 'ls ~/.local/bin'"
echo "  sudo -u ${USER2} bash -c 'cat ~/.zshrc | head -3'"
echo "  sudo -u ${USER2} bash -c 'nvim --version'"
echo "  sudo -u ${USER2} bash -c 'cargo --version'"
echo
