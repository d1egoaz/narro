#!/bin/bash

# Narro Simple Release Script
# ============================
# Builds DMG locally and creates GitHub release with asset upload
#
# Prerequisites:
# - gh CLI installed (brew install gh)
# - gh auth login (authenticate with GitHub)
#
# Usage:
#   ./scripts/release.sh v1.2.0
#   ./scripts/release.sh v1.2.0 --skip-signing  # For unsigned builds

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for gh CLI
    if ! command -v gh &> /dev/null; then
        log_error "gh CLI not found. Install it first:"
        echo "  brew install gh"
        exit 1
    fi

    # Check gh auth status
    if ! gh auth status &> /dev/null; then
        log_error "Not authenticated with GitHub. Run:"
        echo "  gh auth login"
        exit 1
    fi

    log_success "Prerequisites verified"
}

# Parse arguments
if [ $# -lt 1 ]; then
    log_error "Usage: $0 <version> [--skip-signing]"
    echo ""
    echo "Examples:"
    echo "  $0 v1.2.0                # Build and release with signing"
    echo "  $0 v1.2.0 --skip-signing # Build and release without signing"
    exit 1
fi

VERSION="$1"
SKIP_SIGNING=""

# Parse optional flags
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-signing)
            SKIP_SIGNING="--skip-signing"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Version must be in format: v1.2.3"
    exit 1
fi

# Strip 'v' prefix for internal use
VERSION_NUMBER="${VERSION#v}"

echo "🚀 Narro Release Script"
echo "======================="
echo "Version: $VERSION"
if [ -n "$SKIP_SIGNING" ]; then
    log_warning "Building WITHOUT code signing"
fi
echo ""

# Check prerequisites
check_prerequisites

# Step 1: Update Info.plist with version
log_info "Updating version in Info.plist to $VERSION_NUMBER..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION_NUMBER" NarroApp/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION_NUMBER" NarroApp/Info.plist
log_success "Version updated in Info.plist"

# Step 2: Build DMG
log_info "Building DMG..."
if ! ./scripts/build-dmg.sh $SKIP_SIGNING; then
    log_error "Build failed"
    exit 1
fi

# Find the created DMG
DMG_FILE=$(find . -maxdepth 1 -name "Narro-${VERSION_NUMBER}-Universal.dmg" -type f)
CHECKSUM_FILE="${DMG_FILE}.sha256"

if [ ! -f "$DMG_FILE" ]; then
    log_error "DMG file not found: Narro-${VERSION_NUMBER}-Universal.dmg"
    exit 1
fi

if [ ! -f "$CHECKSUM_FILE" ]; then
    log_warning "Checksum file not found: $CHECKSUM_FILE"
fi

log_success "Build completed: $DMG_FILE"

# Step 3: Check if tag exists
log_info "Checking if tag $VERSION exists..."
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    log_warning "Tag $VERSION already exists locally"
    read -p "Delete and recreate tag? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "$VERSION"
        git push origin ":refs/tags/$VERSION" 2>/dev/null || true
    else
        log_error "Release aborted"
        exit 1
    fi
fi

# Step 4: Create git tag
log_info "Creating git tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION"
log_success "Tag created and pushed"

# Step 5: Generate release notes
log_info "Generating release notes..."
RELEASE_NOTES=$(cat <<EOF
## Narro $VERSION

### Installation
1. Download \`Narro-${VERSION_NUMBER}-Universal.dmg\` below
2. Open the DMG and drag Narro to your Applications folder
3. Launch Narro from Applications

### Requirements
- macOS 14.0 or later
- Apple Silicon (M1/M2/M3) or Intel Mac
- OpenAI API key

### Verification
SHA-256 checksum is provided below for verification.

---

For more information, see the [README](https://github.com/d1egoaz/narro#readme).
EOF
)

# Step 6: Create GitHub release
log_info "Creating GitHub release..."
if gh release view "$VERSION" >/dev/null 2>&1; then
    log_warning "Release $VERSION already exists on GitHub"
    read -p "Delete and recreate release? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gh release delete "$VERSION" --yes
    else
        log_error "Release aborted"
        exit 1
    fi
fi

# Create release and upload assets
UPLOAD_ARGS=("$DMG_FILE")
if [ -f "$CHECKSUM_FILE" ]; then
    UPLOAD_ARGS+=("$CHECKSUM_FILE")
fi

gh release create "$VERSION" \
    --title "Narro $VERSION" \
    --notes "$RELEASE_NOTES" \
    "${UPLOAD_ARGS[@]}"

log_success "Release created successfully!"

# Step 7: Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "Release $VERSION completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 DMG: $DMG_FILE"
echo "🏷️  Tag: $VERSION"
echo "🔗 Release URL: https://github.com/d1egoaz/narro/releases/tag/$VERSION"
echo ""

if [ -n "$SKIP_SIGNING" ]; then
    log_warning "This is an UNSIGNED build (development only)"
    echo "   Users may see security warnings when opening the app."
    echo ""
fi

echo "Next steps:"
echo "1. Visit the release URL above to verify"
echo "2. Test the download and installation"
echo "3. Share the release with users!"
echo ""
