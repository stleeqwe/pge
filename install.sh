#!/bin/bash
# PGE Skills Installer — Installs /pge and /pge-team as global Claude Code skills
# Usage: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "=== PGE Skills Installer ==="
echo ""

# Install skills
mkdir -p "$SKILLS_DIR/pge" "$SKILLS_DIR/pge-team" "$SKILLS_DIR/pge-perf" "$SKILLS_DIR/pge-design"
cp "$SCRIPT_DIR/pge/SKILL.md" "$SKILLS_DIR/pge/SKILL.md"
cp "$SCRIPT_DIR/pge-team/SKILL.md" "$SKILLS_DIR/pge-team/SKILL.md"
cp "$SCRIPT_DIR/pge-perf/SKILL.md" "$SKILLS_DIR/pge-perf/SKILL.md"
cp "$SCRIPT_DIR/pge-design/SKILL.md" "$SKILLS_DIR/pge-design/SKILL.md"

echo "[OK] /pge        → $SKILLS_DIR/pge/SKILL.md"
echo "[OK] /pge-team   → $SKILLS_DIR/pge-team/SKILL.md"
echo "[OK] /pge-perf   → $SKILLS_DIR/pge-perf/SKILL.md"
echo "[OK] /pge-design → $SKILLS_DIR/pge-design/SKILL.md"
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Skills are now available in ALL projects. Usage:"
echo ""
echo "  Default (autonomous):   fix the follow sync bug"
echo "  Full protocol:          fix the follow sync bug /pge"
echo "  Team investigation:     fix the follow sync bug /pge-team"
echo "  Performance optimize:   optimize chat list /pge-perf"
echo "  Design quality:         improve profile screen /pge-design"
echo ""
echo "On first /pge run in a new project, it will auto-create:"
echo "  .claude/pge/            (state directory, gitignored)"
echo "  docs/backend-dependency-map.md  (if missing, prompts to generate)"
