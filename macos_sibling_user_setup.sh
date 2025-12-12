#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# macOS Sibling User Setup Script
# ============================================================================
# Purpose: Create and configure a second "sibling" user that shares
#          development environment with the primary user, safely.
#
# Adapted from Linux multi-user setup with macOS-specific considerations.
# ============================================================================

# --- CONFIGURATION ---
# Auto-detect current user (when run with sudo, use SUDO_USER)
CURRENT_USER="${SUDO_USER:-$USER}"
PRIMARY_USER="${PRIMARY_USER:-$CURRENT_USER}"
SIBLING_USER="${SIBLING_USER:-${CURRENT_USER}dev}"
SHARED_GROUP="${SHARED_GROUP:-devshared}"
SHARED_DIR="/Users/Shared/dev"

# List of safe configs to symlink (relative to home directory)
CONFIGS_TO_LINK=(
  ".zshrc"
  ".oh-my-zsh"
  ".p10k.zsh"
  ".tmux.conf"
  ".tmux"
  ".tmux.conf.local"
  ".config/nvim"
  ".ai"
  # Add more as needed, but be careful with sensitive configs
  # ".gitconfig"  # Only if it doesn't contain credentials
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- HELPER FUNCTIONS ---

print_header() {
  echo ""
  echo -e "${BLUE}============================================================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}============================================================================${NC}"
  echo ""
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

confirm() {
  local prompt="$1"
  local response
  read -p "$prompt [y/N]: " response
  case "$response" in
    [Yy]*) return 0 ;;
    *) return 1 ;;
  esac
}

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    print_error "This script must be run with sudo or as root."
    exit 1
  fi
}

check_user_exists() {
  local user="$1"
  if id "$user" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

check_group_exists() {
  local group="$1"
  if dscl . -read /Groups/"$group" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

get_next_uid() {
  # Get next available UID >= 501
  local max_uid=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
  local next_uid=$((max_uid + 1))
  if [ "$next_uid" -lt 501 ]; then
    next_uid=501
  fi
  echo "$next_uid"
}

get_next_gid() {
  # Get next available GID >= 501
  local max_gid=$(dscl . -list /Groups PrimaryGroupID | awk '{print $2}' | sort -n | tail -1)
  local next_gid=$((max_gid + 1))
  if [ "$next_gid" -lt 501 ]; then
    next_gid=501
  fi
  echo "$next_gid"
}

# --- MAIN FUNCTIONS ---

create_sibling_user() {
  print_header "Creating Sibling User: $SIBLING_USER"

  if check_user_exists "$SIBLING_USER"; then
    print_warning "User '$SIBLING_USER' already exists. Skipping user creation."
    return 0
  fi

  local full_name
  local password
  local make_admin=false

  read -p "Enter full name for $SIBLING_USER [DP Dev]: " full_name
  full_name="${full_name:-DP Dev}"

  read -sp "Enter password for $SIBLING_USER: " password
  echo ""

  if confirm "Make $SIBLING_USER an administrator?"; then
    make_admin=true
  fi

  print_info "Creating user $SIBLING_USER..."

  # Create user using sysadminctl (macOS 10.13+)
  if command -v sysadminctl &>/dev/null; then
    sudo sysadminctl -addUser "$SIBLING_USER" \
      -fullName "$full_name" \
      -password "$password" \
      -home "/Users/$SIBLING_USER" \
      -shell /bin/zsh \
      -admin

    if ! $make_admin; then
      # Remove from admin group if not requested
      sudo dseditgroup -o edit -d "$SIBLING_USER" -t user admin 2>/dev/null || true
    fi

    print_success "User $SIBLING_USER created successfully"
  else
    print_error "sysadminctl not available. Please create user manually via System Settings."
    exit 1
  fi

  # Create home directory if it doesn't exist (macOS sometimes doesn't create it automatically)
  if [ ! -d "/Users/$SIBLING_USER" ]; then
    print_warning "Home directory not created automatically, creating it now..."

    # Use createhomedir if available (recommended)
    if command -v createhomedir &>/dev/null; then
      createhomedir -c -u "$SIBLING_USER"
      print_success "Home directory created using createhomedir"
    else
      # Fallback: create manually with proper structure
      print_info "Creating home directory manually..."

      # Create home directory
      mkdir -p "/Users/$SIBLING_USER"

      # Copy skeleton files from template
      if [ -d "/System/Library/User Template/English.lproj" ]; then
        rsync -a "/System/Library/User Template/English.lproj/" "/Users/$SIBLING_USER/"
      fi

      # Set ownership
      chown -R "$SIBLING_USER:staff" "/Users/$SIBLING_USER"

      print_success "Home directory created manually"
    fi
  fi

  # Ensure home directory has correct permissions
  chmod 755 "/Users/$SIBLING_USER"

  print_success "User creation complete"
}

create_shared_group() {
  print_header "Setting Up Shared Group: $SHARED_GROUP"

  if check_group_exists "$SHARED_GROUP"; then
    print_warning "Group '$SHARED_GROUP' already exists. Verifying membership..."
  else
    print_info "Creating group $SHARED_GROUP..."
    local next_gid=$(get_next_gid)

    sudo dseditgroup -o create -i "$next_gid" "$SHARED_GROUP"
    print_success "Group $SHARED_GROUP created with GID $next_gid"
  fi

  # Add both users to the shared group
  print_info "Adding users to $SHARED_GROUP..."

  for user in "$PRIMARY_USER" "$SIBLING_USER"; do
    if check_user_exists "$user"; then
      sudo dseditgroup -o edit -a "$user" -t user "$SHARED_GROUP" 2>/dev/null || true
      print_success "Added $user to $SHARED_GROUP"
    else
      print_warning "User $user does not exist, skipping..."
    fi
  done

  print_success "Shared group setup complete"
}

setup_shared_directory() {
  print_header "Setting Up Shared Directory: $SHARED_DIR"

  # Create shared directory if it doesn't exist
  if [ ! -d "$SHARED_DIR" ]; then
    print_info "Creating $SHARED_DIR..."
    sudo mkdir -p "$SHARED_DIR"
  else
    print_warning "$SHARED_DIR already exists"
  fi

  # Set ownership to root:SHARED_GROUP
  sudo chown root:"$SHARED_GROUP" "$SHARED_DIR"

  # Set permissions: rwxrwxr-x with setgid
  sudo chmod 2775 "$SHARED_DIR"

  # Add ACLs for both users (macOS style)
  print_info "Setting ACLs on $SHARED_DIR..."
  sudo chmod +a "group:$SHARED_GROUP allow read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity,file_inherit,directory_inherit" "$SHARED_DIR" 2>/dev/null || true

  # Create subdirectories
  for subdir in projects scripts data; do
    if [ ! -d "$SHARED_DIR/$subdir" ]; then
      sudo mkdir -p "$SHARED_DIR/$subdir"
      print_success "Created $SHARED_DIR/$subdir"
    fi
  done

  # Fix permissions on subdirectories
  sudo chown -R root:"$SHARED_GROUP" "$SHARED_DIR"
  sudo chmod -R 2775 "$SHARED_DIR"

  print_success "Shared directory setup complete"

  # Create symlinks to shared projects in each user's home
  print_info "Creating symlinks to shared projects..."

  for user in "$PRIMARY_USER" "$SIBLING_USER"; do
    local user_home="/Users/$user"
    if [ -d "$user_home" ]; then
      if [ ! -e "$user_home/shared_projects" ]; then
        sudo -u "$user" ln -s "$SHARED_DIR/projects" "$user_home/shared_projects"
        print_success "Created ~/shared_projects for $user"
      fi
    fi
  done
}

share_local_subdirs() {
  print_header "Sharing .local Subdirectories (SAFE)"

  print_warning "This will share .local/bin, .local/lib, and .local/share from $PRIMARY_USER to $SIBLING_USER"
  print_warning "Tools installed by $PRIMARY_USER via pipx/npm will be available to $SIBLING_USER"

  if ! confirm "Proceed with .local sharing?"; then
    print_info "Skipping .local sharing"
    return 0
  fi

  local src_local="/Users/$PRIMARY_USER/.local"
  local dst_local="/Users/$SIBLING_USER/.local"

  # Ensure source .local structure exists
  for subdir in bin lib share; do
    sudo -u "$PRIMARY_USER" mkdir -p "$src_local/$subdir"
  done

  # Set conservative permissions on PRIMARY's .local
  print_info "Setting permissions on $PRIMARY_USER's .local..."
  find "$src_local" -type d -exec chmod 755 {} \; 2>/dev/null || true
  find "$src_local" -type f -exec chmod 644 {} \; 2>/dev/null || true
  # Executables in bin should be 755
  find "$src_local/bin" -type f -exec chmod 755 {} \; 2>/dev/null || true

  # Allow traversal of PRIMARY's home by SIBLING (macOS ACL)
  print_info "Setting ACL for $SIBLING_USER to access $PRIMARY_USER's home..."
  sudo chmod +a "user:$SIBLING_USER allow read,execute,readattr,readextattr,readsecurity" "/Users/$PRIMARY_USER" 2>/dev/null || true

  # Set ACLs on .local subdirectories
  for subdir in bin lib share; do
    local src_path="$src_local/$subdir"
    if [ -d "$src_path" ]; then
      print_info "Setting ACLs on $src_path..."
      sudo chmod +a "user:$SIBLING_USER allow read,execute,readattr,readextattr,readsecurity,file_inherit,directory_inherit" "$src_path" 2>/dev/null || true
    fi
  done

  # Backup existing SIBLING .local subdirs
  for subdir in bin lib share; do
    local dst_path="$dst_local/$subdir"
    if [ -e "$dst_path" ] || [ -L "$dst_path" ]; then
      local ts=$(date +%s)
      sudo mv "$dst_path" "$dst_path.bak.$ts"
      print_info "Backed up $dst_path to $dst_path.bak.$ts"
    fi
  done

  # Ensure SIBLING's .local directory exists
  sudo -u "$SIBLING_USER" mkdir -p "$dst_local"

  # Create symlinks
  for subdir in bin lib share; do
    sudo -u "$SIBLING_USER" ln -s "$src_local/$subdir" "$dst_local/$subdir"
    print_success "Created symlink: $dst_local/$subdir -> $src_local/$subdir"
  done

  print_success ".local subdirectory sharing complete"
}

share_configs() {
  print_header "Sharing Configuration Files (SAFE)"

  print_info "This will create symlinks for specific config files/directories:"
  for config in "${CONFIGS_TO_LINK[@]}"; do
    echo "  - $config"
  done

  if ! confirm "Proceed with config sharing?"; then
    print_info "Skipping config sharing"
    return 0
  fi

  for item in "${CONFIGS_TO_LINK[@]}"; do
    local src_item="/Users/$PRIMARY_USER/$item"
    local dst_item="/Users/$SIBLING_USER/$item"

    if [ ! -e "$src_item" ]; then
      print_warning "Source $src_item does not exist. Skipping."
      continue
    fi

    print_info "Processing: $item"

    # Ensure parent directory exists
    local dst_parent=$(dirname "$dst_item")
    if [ ! -d "$dst_parent" ]; then
      sudo -u "$SIBLING_USER" mkdir -p "$dst_parent"
      print_info "Created parent dir: $dst_parent"
    fi

    # Backup existing destination
    if [ -e "$dst_item" ] || [ -L "$dst_item" ]; then
      local ts=$(date +%s)
      sudo mv "$dst_item" "$dst_item.bak.$ts"
      print_info "Backed up $dst_item to $dst_item.bak.$ts"
    fi

    # Set ACL on source for SIBLING to read
    sudo chmod +a "user:$SIBLING_USER allow read,execute,readattr,readextattr,readsecurity,file_inherit,directory_inherit" "$src_item" 2>/dev/null || true

    # Create symlink
    sudo -u "$SIBLING_USER" ln -s "$src_item" "$dst_item"
    print_success "Created symlink: $dst_item -> $src_item"
  done

  print_success "Config sharing complete"
}

copy_ssh_safely() {
  print_header "Copying SSH Keys (NEVER SYMLINK)"

  print_warning "SSH keys will be COPIED (not symlinked) from $PRIMARY_USER to $SIBLING_USER"
  print_warning "This is required because SSH enforces strict ownership rules"

  if ! confirm "Proceed with SSH key copy?"; then
    print_info "Skipping SSH key copy"
    return 0
  fi

  local src_ssh="/Users/$PRIMARY_USER/.ssh"
  local dst_ssh="/Users/$SIBLING_USER/.ssh"

  if [ ! -d "$src_ssh" ]; then
    print_error "Source SSH directory $src_ssh does not exist!"
    return 1
  fi

  # Backup existing destination .ssh
  if [ -e "$dst_ssh" ] || [ -L "$dst_ssh" ]; then
    local ts=$(date +%s)
    sudo mv "$dst_ssh" "$dst_ssh.bak.$ts"
    print_info "Backed up $dst_ssh to $dst_ssh.bak.$ts"
  fi

  # Create new .ssh directory
  sudo -u "$SIBLING_USER" mkdir -p "$dst_ssh"
  sudo chmod 700 "$dst_ssh"

  # Copy all SSH files
  print_info "Copying SSH files..."
  sudo cp -a "$src_ssh"/. "$dst_ssh/"

  # Set ownership to SIBLING_USER
  sudo chown -R "$SIBLING_USER:staff" "$dst_ssh"

  # Set strict permissions
  print_info "Setting strict SSH permissions..."
  sudo chmod 700 "$dst_ssh"

  # All files default to 600
  find "$dst_ssh" -type f -exec sudo chmod 600 {} \;

  # Public keys can be 644
  find "$dst_ssh" -name "*.pub" -type f -exec sudo chmod 644 {} \;

  # authorized_keys must be 600
  if [ -f "$dst_ssh/authorized_keys" ]; then
    sudo chmod 600 "$dst_ssh/authorized_keys"
  fi

  # Remove any ACLs that might interfere
  print_info "Removing ACLs from .ssh directory..."
  sudo chmod -N "$dst_ssh" 2>/dev/null || true
  find "$dst_ssh" -exec sudo chmod -N {} \; 2>/dev/null || true

  print_success "SSH keys copied successfully"

  # Verify
  print_info "Verifying SSH permissions..."
  ls -la "$dst_ssh" | head -20
}

run_development_setup() {
  print_header "Development Environment Setup for $SIBLING_USER"

  if ! confirm "Run development environment setup for $SIBLING_USER?"; then
    print_info "Skipping development setup"
    return 0
  fi

  print_info "Switching to $SIBLING_USER to run setup..."

  # Check if macos_config.sh exists
  local setup_script="/Users/$PRIMARY_USER/ubuntu_config/macos_config.sh"
  if [ ! -f "$setup_script" ]; then
    print_warning "Setup script not found at $setup_script"
    print_info "You can run it manually later as $SIBLING_USER"
    return 0
  fi

  print_info "You should run the macos_config.sh script as $SIBLING_USER:"
  print_info "  su - $SIBLING_USER"
  print_info "  cd /Users/$PRIMARY_USER/ubuntu_config"
  print_info "  ./macos_config.sh"
}

validate_setup() {
  print_header "Validating Setup"

  # Check users exist
  print_info "Checking users..."
  for user in "$PRIMARY_USER" "$SIBLING_USER"; do
    if check_user_exists "$user"; then
      print_success "User $user exists"
    else
      print_error "User $user does not exist!"
    fi
  done

  # Check group membership
  print_info "Checking group membership..."
  if check_group_exists "$SHARED_GROUP"; then
    print_success "Group $SHARED_GROUP exists"
    local members=$(dseditgroup -o checkmember -m "$PRIMARY_USER" "$SHARED_GROUP" 2>&1)
    if echo "$members" | grep -q "yes"; then
      print_success "$PRIMARY_USER is member of $SHARED_GROUP"
    fi
    members=$(dseditgroup -o checkmember -m "$SIBLING_USER" "$SHARED_GROUP" 2>&1)
    if echo "$members" | grep -q "yes"; then
      print_success "$SIBLING_USER is member of $SHARED_GROUP"
    fi
  fi

  # Check shared directory
  print_info "Checking shared directory..."
  if [ -d "$SHARED_DIR" ]; then
    print_success "$SHARED_DIR exists"
    ls -ld "$SHARED_DIR"
  fi

  # Check .ssh permissions for SIBLING
  print_info "Checking SSH permissions for $SIBLING_USER..."
  local sibling_ssh="/Users/$SIBLING_USER/.ssh"
  if [ -d "$sibling_ssh" ]; then
    local perms=$(stat -f "%Lp" "$sibling_ssh")
    if [ "$perms" = "700" ]; then
      print_success ".ssh directory has correct permissions (700)"
    else
      print_warning ".ssh directory permissions: $perms (should be 700)"
    fi
  fi

  print_success "Validation complete"
}

print_next_steps() {
  print_header "Next Steps"

  echo "1. Log out and log in as $SIBLING_USER to activate group membership"
  echo ""
  echo "2. As $SIBLING_USER, run the development environment setup:"
  echo "   su - $SIBLING_USER"
  echo "   cd /Users/$PRIMARY_USER/ubuntu_config"
  echo "   ./macos_config.sh"
  echo ""
  echo "3. Test SSH access:"
  echo "   ssh -T git@github.com"
  echo "   ssh your-server.com"
  echo ""
  echo "4. Verify shared tools work:"
  echo "   which python"
  echo "   which node"
  echo ""
  echo "5. Access shared projects:"
  echo "   cd ~/shared_projects"
  echo ""
  print_success "Setup complete!"
}

# --- MAIN SCRIPT ---

main() {
  print_header "macOS Sibling User Setup"

  check_root

  # Prompt for user names and group
  echo ""
  print_info "Current user: $(whoami)"
  print_info "Detected users on system:"
  dscl . -list /Users | grep -v "^_" | grep -v "daemon\|Guest\|nobody\|root" | sed 's/^/  - /'
  echo ""

  read -p "Enter PRIMARY user name [default: $PRIMARY_USER]: " input_primary
  PRIMARY_USER="${input_primary:-$PRIMARY_USER}"

  read -p "Enter SIBLING user suffix [default: dev]: " input_suffix
  SUFFIX="${input_suffix:-dev}"

  read -p "Enter SIBLING user name [default: ${PRIMARY_USER}${SUFFIX}]: " input_sibling
  SIBLING_USER="${input_sibling:-${PRIMARY_USER}${SUFFIX}}"

  read -p "Enter SHARED GROUP name [default: $SHARED_GROUP]: " input_group
  SHARED_GROUP="${input_group:-$SHARED_GROUP}"

  echo ""
  print_info "Configuration:"
  echo "  - Primary user: $PRIMARY_USER"
  echo "  - Sibling user: $SIBLING_USER"
  echo "  - Shared group: $SHARED_GROUP"
  echo "  - Shared directory: $SHARED_DIR"
  echo ""

  print_info "This script will:"
  echo "  - Optionally create user: $SIBLING_USER"
  echo "  - Create shared group: $SHARED_GROUP"
  echo "  - Set up shared directory: $SHARED_DIR"
  echo "  - Share .local subdirectories (bin, lib, share)"
  echo "  - Share configuration files (.zshrc, .tmux, etc.)"
  echo "  - Copy SSH keys (safely, never symlink)"
  echo ""

  if ! confirm "Proceed with setup?"; then
    print_info "Setup cancelled"
    exit 0
  fi

  # Verify PRIMARY user exists
  if ! check_user_exists "$PRIMARY_USER"; then
    print_error "Primary user $PRIMARY_USER does not exist!"
    exit 1
  fi

  # Step 1: Create sibling user (optional)
  if confirm "Create new user $SIBLING_USER?"; then
    create_sibling_user
  else
    if ! check_user_exists "$SIBLING_USER"; then
      print_error "Sibling user $SIBLING_USER does not exist and you chose not to create it!"
      exit 1
    fi
  fi

  # Step 1.5: Ensure home directory exists (even if user already existed)
  if [ ! -d "/Users/$SIBLING_USER" ]; then
    print_warning "Home directory /Users/$SIBLING_USER does not exist!"
    print_info "Creating home directory..."

    # Use createhomedir if available (recommended)
    if command -v createhomedir &>/dev/null; then
      createhomedir -c -u "$SIBLING_USER"
      print_success "Home directory created using createhomedir"
    else
      # Fallback: create manually with proper structure
      print_info "Creating home directory manually..."

      # Create home directory
      mkdir -p "/Users/$SIBLING_USER"

      # Copy skeleton files from template
      if [ -d "/System/Library/User Template/English.lproj" ]; then
        rsync -a "/System/Library/User Template/English.lproj/" "/Users/$SIBLING_USER/"
      fi

      # Set ownership
      chown -R "$SIBLING_USER:staff" "/Users/$SIBLING_USER"

      print_success "Home directory created manually"
    fi

    # Ensure correct permissions
    chmod 755 "/Users/$SIBLING_USER"
  else
    print_success "Home directory /Users/$SIBLING_USER already exists"
  fi

  # Step 2: Create shared group
  create_shared_group

  # Step 3: Setup shared directory
  setup_shared_directory

  # Step 4: Share .local subdirectories
  share_local_subdirs

  # Step 5: Share configs
  share_configs

  # Step 6: Copy SSH keys
  copy_ssh_safely

  # Step 7: Validate
  validate_setup

  # Step 8: Print next steps
  print_next_steps
}

# Run main function
main "$@"
