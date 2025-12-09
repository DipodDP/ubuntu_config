#!/usr/bin/env bash
set -euo pipefail

# ---- params ----
USER1="dp"             # source owner
USER2="dpdev"          # destination user
ACCESS="rwX"            # rX (read+traverse) or rwX (read+write+traverse)
# SRC_LOCAL="/home/${USER1}/.local"
# DST_LOCAL="/home/${USER2}/.local"
SRC_CONFIG="/home/${USER1}/.config"
DST_CONFIG="/home/${USER2}/.config"
SRC_SSH="/home/${USER1}/.ssh"
DST_SSH_DIR="/home/${USER2}/.ssh"
SRC_SSH_CONFIG="${SRC_SSH}/config"
DST_SSH_DIR_CONFIG="${DST_SSH_DIR}/config"

# ---- List of configs to symlink ----
# Add items relative to home directory.
# Example: ".zshrc", ".config/nvim"
CONFIGS_TO_LINK=(
  ".zshrc"
  ".oh-my-zsh"
  ".p10k.zsh"
  ".tmux.conf"
  ".tmux"
  ".docker"
  ".fly"
  # ".gitconfig"
  # ".config/htop"
  # ".config/mc"
  # ".config/kitty"
  # ".config/nvim"
)


if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo or as root."
  exit 1
fi

echo "Copying SSH keys from ${SRC_SSH} -> ${DST_SSH_DIR}"
echo "And linking various configs for ${USER2} from ${USER1}"
read -p "Proceed? [y/N] " yn
case "$yn" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 0 ;;
esac

echo "Script will:"
# echo "- link ${DST_LOCAL}/bin,lib,share -> ${SRC_LOCAL}/bin,lib,share"
echo "- set ACL ${ACCESS} for ${USER2} on ${USER1}'s dirs"
echo "- create symlinks for various configs (zsh, tmux, docker, etc.)"
echo "- create symlink ${DST_SSH_DIR_CONFIG} -> ${SRC_SSH_CONFIG} (safe: only file)"
read -p "Continue? [y/N] " yn
case "$yn" in
  [Yy]*) ;;
  *) echo "Aborted."; exit 0 ;;
esac

# ----- Backup existing dipod targets -----
# for sub in bin lib share; do
#   if [ -e "${DST_LOCAL}/${sub}" ] || [ -L "${DST_LOCAL}/${sub}" ]; then
#     ts=$(date +%s)
#     mv "${DST_LOCAL}/${sub}" "${DST_LOCAL}/${sub}.bak.${ts}"
#     echo "Backed up ${DST_LOCAL}/${sub} -> ${DST_LOCAL}/${sub}.bak.${ts}"
#   fi
# done

# ---- Ensure source local subdirs exist and owned by USER1 ----
# sudo -u "${USER1}" mkdir -p "${SRC_LOCAL}/bin" "${SRC_LOCAL}/lib" "${SRC_LOCAL}/share"
# chown -R "${USER1}:${USER1}" "${SRC_LOCAL}"
# conservative permissions for dp's .local: dirs 755, files 644
# find "${SRC_LOCAL}" -type d -exec chmod 755 {} \; 2>/dev/null || true
# find "${SRC_LOCAL}" -type f -exec chmod 644 {} \; 2>/dev/null || true

# ---- Allow traversal of /home/USER1 by USER2 ----
echo "Setting base ACLs for ${USER2} to access /home/${USER1}"
setfacl -m u:${USER2}:x "/home/${USER1}" 2>/dev/null || true
setfacl -m d:u:${USER2}:x "/home/${USER1}" 2>/dev/null || true

# ---------------------------
# Symlink dotfiles and configs
# ---------------------------
echo
echo "--- Processing dotfile/config symlinks ---"

for item in "${CONFIGS_TO_LINK[@]}"; do
  SRC_ITEM="/home/${USER1}/${item}"
  DST_ITEM="/home/${USER2}/${item}"

  if [ ! -e "${SRC_ITEM}" ]; then
    echo "SKIPPING: Source ${SRC_ITEM} does not exist."
    continue
  fi

  echo "Processing: ${item}"

  # Ensure parent directory of destination exists
  DST_PARENT=$(dirname "${DST_ITEM}")
  if [ ! -d "${DST_PARENT}" ]; then
    mkdir -p "${DST_PARENT}"
    chown "${USER2}:${USER2}" "${DST_PARENT}"
    chmod 755 "${DST_PARENT}"
    echo "Created parent dir: ${DST_PARENT}"
  fi

  # Backup existing destination
  if [ -e "${DST_ITEM}" ] || [ -L "${DST_ITEM}" ]; then
    ts=$(date +%s)
    echo "Backing up existing ${DST_ITEM}..."
    mv "${DST_ITEM}" "${DST_ITEM}.bak.${ts}"
    # echo "Backed up ${DST_ITEM} -> ${DST_ITEM}.bak.${ts}"
  fi

  # Set ACL on source for USER2 to allow access
  # This is needed for the symlink to be useful
  echo "Setting ACLs on source: ${SRC_ITEM}"
  setfacl -R -m u:${USER2}:${ACCESS} "${SRC_ITEM}" 2>/dev/null || true
  setfacl -R -m d:u:${USER2}:${ACCESS} "${SRC_ITEM}" 2>/dev/null || true

  # Create symlink
  echo "Creating symlink: ${DST_ITEM} -> ${SRC_ITEM}"
  ln -snf "${SRC_ITEM}" "${DST_ITEM}"

  # Change symlink ownership to USER2
  chown -h "${USER2}:${USER2}" "${DST_ITEM}"
done

echo "--- Dotfile/config symlinking complete ---"
echo

# ---- Set ACLs for bin, lib, share ----
# setfacl -R -m u:${USER2}:${ACCESS} "${SRC_LOCAL}/bin"    2>/dev/null || true
# setfacl -R -m d:u:${USER2}:${ACCESS} "${SRC_LOCAL}/bin"  2>/dev/null || true
#
# setfacl -R -m u:${USER2}:${ACCESS} "${SRC_LOCAL}/lib"    2>/dev/null || true
# setfacl -R -m d:u:${USER2}:${ACCESS} "${SRC_LOCAL}/lib"  2>/dev/null || true

# for share, we allow rwX by default if ACCESS contains w; keep ACCESS for consistency
# setfacl -R -m u:${USER2}:${ACCESS} "${SRC_LOCAL}/share"  2>/dev/null || true
# setfacl -R -m d:u:${USER2}:${ACCESS} "${SRC_LOCAL}/share" 2>/dev/null || true

# ---- Ensure destination .local exists and owned by USER2 ----
# mkdir -p "${DST_LOCAL}"
# chown "${USER2}:${USER2}" "${DST_LOCAL}"
# chmod 755 "${DST_LOCAL}"

# ---- Create symlinks in destination .local ----
# ln -sf "${SRC_LOCAL}/bin"  "${DST_LOCAL}/bin"
# ln -sf "${SRC_LOCAL}/lib"  "${DST_LOCAL}/lib"
# ln -sf "${SRC_LOCAL}/share" "${DST_LOCAL}/share"
# cosmetic: make symlink reported as owned by USER2
# chown -h "${USER2}:${USER2}" "${DST_LOCAL}/bin" "${DST_LOCAL}/lib" "${DST_LOCAL}/share" 2>/dev/null || true
#
# echo "Local subfolder symlinks created."

# ---------------------------
# SSH config linking (SAFE)
# ---------------------------

# Backup existing dst .ssh (file or dir or symlink)
if [ -e "${DST_SSH_DIR}" ] || [ -L "${DST_SSH_DIR}" ]; then
  ts=$(date +%s)
  echo "Backup: ${DST_SSH_DIR} -> ${DST_SSH_DIR}.bak.${ts}"
  mv "${DST_SSH_DIR}" "${DST_SSH_DIR}.bak.${ts}"
fi

# Ensure dipod has a real .ssh dir
if [ ! -d "${DST_SSH_DIR}" ]; then
  mkdir -p "${DST_SSH_DIR}"
  chown "${USER2}:${USER2}" "${DST_SSH_DIR}"
  chmod 700 "${DST_SSH_DIR}"
  echo "Created ${DST_SSH_DIR} with owner ${USER2} and perms 700"
else
  # ensure safe perms and owner
  chown "${USER2}:${USER2}" "${DST_SSH_DIR}"
  chmod 700 "${DST_SSH_DIR}"
fi

# Ensure source config exists; if not, create empty file owned by USER1
if [ ! -f "${SRC_SSH_CONFIG}" ]; then
  echo "# created by script" > "${SRC_SSH_CONFIG}"
  chown "${USER1}:${USER1}" "${SRC_SSH_CONFIG}"
  chmod 600 "${SRC_SSH_CONFIG}"
  echo "Created placeholder ${SRC_SSH_CONFIG}"
else
  # ensure source config perms/owner safe
  chown "${USER1}:${USER1}" "${SRC_SSH_CONFIG}"
  chmod 600 "${SRC_SSH_CONFIG}"
fi

# Backup existing dst config if file exists
if [ -e "${DST_SSH_DIR_CONFIG}" ] && [ ! -L "${DST_SSH_DIR_CONFIG}" ]; then
  ts=$(date +%s)
  mv "${DST_SSH_DIR_CONFIG}" "${DST_SSH_DIR_CONFIG}.bak.${ts}"
  echo "Backed up ${DST_SSH_DIR_CONFIG} -> ${DST_SSH_DIR_CONFIG}.bak.${ts}"
fi

# # Create symlink for config (file) — safe
# ln -sf "${SRC_SSH_CONFIG}" "${DST_SSH_DIR_CONFIG}"
# # set symlink owner cosmetically to USER2
# chown -h "${USER2}:${USER2}" "${DST_SSH_DIR_CONFIG}" 2>/dev/null || true
#
# # ensure the link target has strict perms (private)
# chown "${USER1}:${USER1}" "${SRC_SSH_CONFIG}"
# chmod 600 "${SRC_SSH_CONFIG}"

# echo "SSH config symlink created: ${DST_SSH_DIR_CONFIG} -> ${SRC_SSH_CONFIG}"
echo "Ensured ${DST_SSH_DIR} perms 700 and ${SRC_SSH_CONFIG} perms 600 (owner: ${USER1})."

# If config symlink was desired and already created: keep it.
# We'll copy everything *except* a pre-existing dst config symlink targets (so we don't overwrite symlink).
# Copy files/dirs from source to destination, excluding nothing but handling config carefully.

# If you earlier created symlink DST_SSH_DIR_CONFIG -> SRC_SSH_CONFIG, then DST_SSH_CONFIG is a symlink; exclude it from being replaced.
# We'll copy all items from SRC to DST except 'config' if DST_SSH_DIR_CONFIG already exists and is a symlink.
# EXCLUDE_ARG=""
# if [ -L "${DST_SSH_DIR_CONFIG}" ] || [ -e "${DST_SSH_CONFIG}.bak"* ] 2>/dev/null; then
#   EXCLUDE_ARG="--exclude=config"
# fi

# Use rsync if available for robust copy; fallback to find+cp if not.
if command -v rsync >/dev/null 2>&1; then
  # copy, preserve perms/links/timestamps; we'll fix ownership/permissions below
  echo "Using rsync to copy (excluding config if symlink present)..."
  rsync -a --copy-unsafe-links "${SRC_SSH}/" "${DST_SSH_DIR}/"
else
  echo "rsync not found — falling back to cp (excluding config if needed)..."
  # copy each top-level entry except config (if exclude set)
  shopt -s nullglob
  for item in "${SRC_SSH}"/* "${SRC_SSH}"/.*; do
    # skip . and ..
    [ "$(basename "$item")" = "." ] && continue
    [ "$(basename "$item")" = ".." ] && continue
    # skip if exclusion
    # if [ -n "${EXCLUDE_ARG}" ] && [ "$(basename "$item")" = "config" ]; then
    #   continue
    # fi
    cp -a "$item" "${DST_SSH_DIR}/" || true
  done
  shopt -u nullglob
fi

# If dst config symlink doesn't exist and source config exists, create normal copy (not symlink)
if [ ! -e "${DST_SSH_DIR_CONFIG}" ] && [ -f "${SRC_SSH_CONFIG}" ]; then
  echo "No existing config in dst — copying config file."
  cp -a "${SRC_SSH_CONFIG}" "${DST_SSH_DIR_CONFIG}"
fi

# Set ownership to destination user
chown -R "${USER2}:${USER2}" "${DST_SSH_DIR}"

# Secure permissions:
# directories 700
find "${DST_SSH_DIR}" -type d -exec chmod 700 {} \;

# default files -> 600
find "${DST_SSH_DIR}" -type f -exec chmod 600 {} \;

# public keys -> 644
find "${DST_SSH_DIR}" -name "*.pub" -type f -exec chmod 644 {} \;

# ensure authorized_keys 600 if exists
if [ -f "${DST_SSH_DIR}/authorized_keys" ]; then
  chmod 600 "${DST_SSH_DIR}/authorized_keys"
fi

# Remove ACLs that might interfere
if command -v setfacl >/dev/null 2>&1; then
  setfacl -R -b "${DST_SSH_DIR}" 2>/dev/null || true
fi

echo "Copy complete. Permissions snapshot:"
ls -ld "${DST_SSH_DIR}"
ls -l "${DST_SSH_DIR}" | sed -n '1,200p'

echo
echo "Quick tests (run these as normal user or from your session):"
echo "  sudo -u ${USER2} ssh -T git@github.com"
echo "  sudo -u ${USER2} ssh -v your_host.example.com"
echo
echo "If you used a config symlink earlier, it remains unchanged. If you prefer the config file to be copied (not symlink), remove the symlink and re-run with rsync (no exclude)."


# ---- Quick non-destructive tests ----
echo
echo "Quick checks:"
# echo "1) ls -ld ${DST_LOCAL} and symlinks:"
# ls -ld "${DST_LOCAL}" "${DST_LOCAL}/bin" "${DST_LOCAL}/lib" "${DST_LOCAL}/share" 2>/dev/null || true
echo
echo "2) ls -ld ${DST_SSH_DIR} and config:"
ls -ld "${DST_SSH_DIR}" "${DST_SSH_CONFIG}" 2>/dev/null || true
echo
echo "3) Test read access for ${USER2}:"
# sudo -u "${USER2}" bash -lc "ls -la ~/.local/bin || true; test -r ~/.ssh/config && echo 'ssh config readable' || echo 'ssh config NOT readable'"
echo "4) Test linked configs:"
sudo -u "${USER2}" bash -c "ls -la ~/{.zshrc,.tmux.conf,.gitconfig}" 2>/dev/null || true
echo
echo "Done. If any test fails, inspect permissions and ACLs."

