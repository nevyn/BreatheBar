#!/usr/bin/env bash
# release.sh — bump version, commit, push, and create a GitHub release.
# The release triggers CI which builds, signs, notarizes, and attaches the zip.
#
# Usage:
#   ./release.sh minor    # 1.3 → 1.4  (default)
#   ./release.sh major    # 1.3 → 2.0

set -euo pipefail

BUMP="${1:-minor}"
PBXPROJ="BreatheBar.xcodeproj/project.pbxproj"

# ── Sanity checks ────────────────────────────────────────────────────────────

if [[ "$BUMP" != "major" && "$BUMP" != "minor" ]]; then
    echo "error: argument must be 'major' or 'minor'" >&2
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "error: 'gh' CLI not found — install it with: brew install gh" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "error: working tree has uncommitted changes — commit or stash them first" >&2
    git status --short
    exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$BRANCH" != "main" ]]; then
    echo "error: not on main (currently on '$BRANCH')" >&2
    exit 1
fi

# ── Read current version ─────────────────────────────────────────────────────

CURRENT_VERSION="$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" \
    | sed 's/.*MARKETING_VERSION = \(.*\);.*/\1/' | tr -d '\t ')"

MAJOR="$(echo "$CURRENT_VERSION" | cut -d. -f1)"
MINOR="$(echo "$CURRENT_VERSION" | cut -d. -f2)"

# ── Compute new version ───────────────────────────────────────────────────────

if [[ "$BUMP" == "major" ]]; then
    MAJOR=$((MAJOR + 1))
    MINOR=0
else
    MINOR=$((MINOR + 1))
fi

NEW_VERSION="${MAJOR}.${MINOR}"

echo "Bumping: $CURRENT_VERSION → $NEW_VERSION"

# ── Update pbxproj ────────────────────────────────────────────────────────────
# Escape dots so sed treats them as literals, not wildcards.

ESC_VER="$(echo "$CURRENT_VERSION" | sed 's/\./\\./g')"

sed -i '' \
    "s/MARKETING_VERSION = ${ESC_VER};/MARKETING_VERSION = ${NEW_VERSION};/g" \
    "$PBXPROJ"

# Verify the field was actually updated
CHECK_VER="$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" \
    | sed 's/.*MARKETING_VERSION = \(.*\);.*/\1/' | tr -d '\t ')"

if [[ "$CHECK_VER" != "$NEW_VERSION" ]]; then
    echo "error: pbxproj update failed — check the file manually" >&2
    exit 1
fi

# ── Commit & push ─────────────────────────────────────────────────────────────

git add "$PBXPROJ"
git commit -m "Bump version to $NEW_VERSION"
git push

# ── Create GitHub release (triggers CI) ──────────────────────────────────────

gh release create "v${NEW_VERSION}" \
    --title "v${NEW_VERSION}" \
    --generate-notes

echo ""
echo "✓ Released v${NEW_VERSION} — CI is building, signing, and notarizing."
