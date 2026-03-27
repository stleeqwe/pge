#!/bin/bash
# PGE Framework Setup — Installs PGE into the current project directory
# Usage: bash ~/Desktop/pge-template/setup.sh           # Fresh install
#        bash ~/Desktop/pge-template/setup.sh --update   # Update existing

set -e

TEMPLATE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(pwd)"
UPDATE_MODE=false

if [ "$1" = "--update" ] || [ "$1" = "-u" ]; then
  UPDATE_MODE=true
fi

if [ "$UPDATE_MODE" = true ]; then
  echo "=== PGE Framework Update ==="
else
  echo "=== PGE Framework Setup ==="
fi
echo "Template: $TEMPLATE_DIR"
echo "Project:  $PROJECT_DIR"
echo ""

# 1. Copy skills (always overwrite — these are template-managed)
mkdir -p "$PROJECT_DIR/.claude/commands"
cp "$TEMPLATE_DIR/.claude/commands/pge.md" "$PROJECT_DIR/.claude/commands/pge.md"
cp "$TEMPLATE_DIR/.claude/commands/pge-team.md" "$PROJECT_DIR/.claude/commands/pge-team.md"
echo "[OK] /pge and /pge-team skills installed"

# 2. Create PGE state directory
mkdir -p "$PROJECT_DIR/.claude/pge/history"
echo "[OK] .claude/pge/ directory created"

# 3. Create dependency map from template (only if not exists)
mkdir -p "$PROJECT_DIR/docs"
if [ ! -f "$PROJECT_DIR/docs/backend-dependency-map.md" ]; then
  cp "$TEMPLATE_DIR/docs/backend-dependency-map-template.md" "$PROJECT_DIR/docs/backend-dependency-map.md"
  echo "[OK] docs/backend-dependency-map.md created (empty template)"
else
  echo "[SKIP] docs/backend-dependency-map.md already exists"
fi

# 4. Add to .gitignore
if [ -f "$PROJECT_DIR/.gitignore" ]; then
  if ! grep -q ".claude/pge/" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
    echo "" >> "$PROJECT_DIR/.gitignore"
    cat "$TEMPLATE_DIR/.gitignore.pge-addition" >> "$PROJECT_DIR/.gitignore"
    echo "[OK] .claude/pge/ added to .gitignore"
  else
    echo "[SKIP] .gitignore already has .claude/pge/"
  fi
else
  cp "$TEMPLATE_DIR/.gitignore.pge-addition" "$PROJECT_DIR/.gitignore"
  echo "[OK] .gitignore created with .claude/pge/"
fi

# 5. Append or replace PGE section in CLAUDE.md
if [ -f "$PROJECT_DIR/CLAUDE.md" ]; then
  if ! grep -q "Backend Consistency Protocol (PGE" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "" >> "$PROJECT_DIR/CLAUDE.md"
    cat "$TEMPLATE_DIR/CLAUDE.md.pge-section" >> "$PROJECT_DIR/CLAUDE.md"
    echo "[OK] PGE protocol appended to CLAUDE.md"
  elif [ "$UPDATE_MODE" = true ]; then
    # Extract everything before the PGE section
    PGE_LINE=$(grep -n "## Backend Consistency Protocol (PGE" "$PROJECT_DIR/CLAUDE.md" | head -1 | cut -d: -f1)
    head -n $((PGE_LINE - 1)) "$PROJECT_DIR/CLAUDE.md" > "$PROJECT_DIR/CLAUDE.md.tmp"
    cat "$TEMPLATE_DIR/CLAUDE.md.pge-section" >> "$PROJECT_DIR/CLAUDE.md.tmp"
    mv "$PROJECT_DIR/CLAUDE.md.tmp" "$PROJECT_DIR/CLAUDE.md"
    echo "[OK] PGE protocol replaced in CLAUDE.md"
  else
    echo "[SKIP] CLAUDE.md already has PGE protocol (use --update to replace)"
  fi
else
  cp "$TEMPLATE_DIR/CLAUDE.md.pge-section" "$PROJECT_DIR/CLAUDE.md"
  echo "[OK] CLAUDE.md created with PGE protocol"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next step: Ask Claude Code to analyze your project and fill in:"
echo "  1. docs/backend-dependency-map.md  (your tables, functions, policies)"
echo "  2. .claude/commands/evaluate.md    (domain-specific checklists)"
echo "  3. CLAUDE.md High-Risk Change Matrix (your high-risk targets)"
echo ""
echo "Just tell Claude: \"Analyze this project and fill in the PGE dependency map and domain checklists\""
