#!/bin/bash
set -e

# Script can run standalone or from macos_config.sh
SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)}"

# Validate SCRIPT_DIR
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
  echo "Error: Could not determine repository root"
  exit 1
fi

# Configuration
CONFIG_DIR="$SCRIPT_DIR/config"
EXTENSIONS_FILE="$CONFIG_DIR/vscode_extensions.txt"
TEMP_VSCODE="/tmp/vscode_extensions.$$.txt"
TEMP_CURSOR="/tmp/cursor_extensions.$$.txt"

# Create config directory if missing
mkdir -p "$CONFIG_DIR"

# Initialize temp files
> "$TEMP_VSCODE"
> "$TEMP_CURSOR"

# Detect installed editors and export extensions
detect_and_export() {
  local has_vscode=false
  local has_cursor=false
  local vscode_count=0
  local cursor_count=0

  # Check and export from VSCode
  if command -v code &> /dev/null; then
    has_vscode=true
    echo "Exporting extensions from VS Code..."
    code --list-extensions > "$TEMP_VSCODE" 2>/dev/null || true
    vscode_count=$(grep -c . "$TEMP_VSCODE" 2>/dev/null || echo 0)
    echo "  Found $vscode_count extensions"
  fi

  # Check and export from Cursor
  if command -v cursor &> /dev/null; then
    has_cursor=true
    echo "Exporting extensions from Cursor..."
    cursor --list-extensions > "$TEMP_CURSOR" 2>/dev/null || true
    cursor_count=$(grep -c . "$TEMP_CURSOR" 2>/dev/null || echo 0)
    echo "  Found $cursor_count extensions"
  fi

  # Error if neither editor is installed
  if [ "$has_vscode" = false ] && [ "$has_cursor" = false ]; then
    echo "Error: Neither VS Code nor Cursor is installed"
    echo "Install at least one editor before running this script"
    rm -f "$TEMP_VSCODE" "$TEMP_CURSOR"
    exit 1
  fi

  echo "$has_vscode:$has_cursor:$vscode_count:$cursor_count"
}

# Merge, deduplicate, and sort extensions
merge_and_dedupe() {
  local merged_file="/tmp/merged_extensions.$$.txt"

  # Combine all temp files, filter valid extension IDs, sort, and remove duplicates
  # Extension IDs must match pattern: publisher.extension-name
  cat "$TEMP_VSCODE" "$TEMP_CURSOR" 2>/dev/null | \
    grep -E '^[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+$' | \
    sort -u > "$merged_file"

  echo "$merged_file"
}

# Main execution
main() {
  echo ""
  echo "VSCode/Cursor Extension Export"
  echo "================================"
  echo ""

  # Detect editors and export
  result=$(detect_and_export)

  # Merge and deduplicate
  merged_file=$(merge_and_dedupe)
  unique_count=$(grep -c . "$merged_file" 2>/dev/null || echo 0)

  if [ "$unique_count" -eq 0 ]; then
    echo ""
    echo "Warning: No extensions found to export"
    echo "Make sure you have extensions installed in VS Code or Cursor"
    rm -f "$TEMP_VSCODE" "$TEMP_CURSOR" "$merged_file"
    exit 0
  fi

  # Backup existing file
  if [ -f "$EXTENSIONS_FILE" ]; then
    backup_file="${EXTENSIONS_FILE}.backup.$(date +%s)"
    cp "$EXTENSIONS_FILE" "$backup_file"
    echo "Backed up existing extensions to:"
    echo "  $backup_file"
    echo ""
  fi

  # Write header and extensions to tracked file
  {
    echo "# VSCode/Cursor Extensions"
    echo "# Auto-generated on $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# To install these extensions, run: ./scripts/editors_setup.sh"
    echo ""
    cat "$merged_file"
  } > "$EXTENSIONS_FILE"

  # Cleanup temp files
  rm -f "$TEMP_VSCODE" "$TEMP_CURSOR" "$merged_file"

  echo ""
  echo "✓ Exported $unique_count unique extensions to:"
  echo "  $EXTENSIONS_FILE"
  echo ""
  echo "You can now commit this file to track your extensions:"
  echo "  git add config/vscode_extensions.txt"
  echo "  git commit -m \"Update VSCode/Cursor extensions\""
  echo ""
}

main
