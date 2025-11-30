#!/bin/bash
# ===================================================================
# Test Script for Orbix Security Suite
# ===================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Testing Orbix Security Suite"
echo "==============================="

# Test 1: Script existence and permissions
echo -n "Testing script files... "
if [ -x "./orbix_audit.sh" ] && [ -x "./orbix_analysis.sh" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Scripts not found or not executable"
    exit 1
fi

# Test 2: Help functionality
echo -n "Testing help functionality... "
if ./orbix_audit.sh --help >/dev/null 2>&1 && ./orbix_analysis.sh --help >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Help functionality failed"
    exit 1
fi

# Test 3: Basic syntax validation
echo -n "Testing script syntax... "
if bash -n ./orbix_audit.sh && bash -n ./orbix_analysis.sh; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Syntax errors found"
    exit 1
fi

# Test 4: Dependencies check
echo -n "Testing basic dependencies... "
MISSING_DEPS=""
for cmd in bash find grep awk ps tar python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -z "$MISSING_DEPS" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "Missing dependencies:$MISSING_DEPS"
fi

# Test 5: Directory creation test
echo -n "Testing directory creation... "
TEST_DIR="/tmp/orbix-test-$$"
if mkdir -p "$TEST_DIR" && [ -d "$TEST_DIR" ]; then
    rmdir "$TEST_DIR"
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo "Cannot create test directories"
    exit 1
fi

# Test 6: Documentation
echo -n "Testing documentation... "
if [ -f "./ORBIX_SECURITY_SUITE.md" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠${NC}"
    echo "Documentation not found"
fi

echo ""
echo -e "${GREEN}🎉 All tests passed!${NC}"
echo ""
echo "Next steps:"
echo "1. Run: ./orbix_audit.sh --help"
echo "2. Run: ./orbix_analysis.sh --help"
echo "3. Review: ./ORBIX_SECURITY_SUITE.md"
echo ""
echo "For production use:"
echo "  sudo ./orbix_audit.sh"
echo "  ./orbix_analysis.sh"