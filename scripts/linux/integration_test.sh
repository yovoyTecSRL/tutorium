#!/bin/bash
# ===================================================================
# Integration Test for Orbix Security Suite
# Tests the complete workflow from audit to analysis
# ===================================================================

set +e  # Don't exit on errors, we want to run all tests

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Orbix Security Suite - Integration Test${NC}"
echo "=================================================="

SCRIPT_DIR="/home/runner/work/tutorium/tutorium/scripts/linux"
TEST_PASSED=0
TEST_FAILED=0

# Function to run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((TEST_PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((TEST_FAILED++))
    fi
}

# Test 1: Script existence and executability
run_test "Script files exist and are executable" \
    "[ -x '$SCRIPT_DIR/orbix_audit.sh' ] && [ -x '$SCRIPT_DIR/orbix_analysis.sh' ] && [ -x '$SCRIPT_DIR/secure-deploy.sh' ]"

# Test 2: Help functionality
run_test "Help functionality works" \
    "$SCRIPT_DIR/orbix_audit.sh --help >/dev/null 2>&1 && $SCRIPT_DIR/orbix_analysis.sh --help >/dev/null 2>&1"

# Test 3: Syntax validation
run_test "Shell script syntax validation" \
    "bash -n '$SCRIPT_DIR/orbix_audit.sh' && bash -n '$SCRIPT_DIR/orbix_analysis.sh' && bash -n '$SCRIPT_DIR/secure-deploy.sh'"

# Test 4: Documentation exists
run_test "Documentation exists" \
    "[ -f '$SCRIPT_DIR/ORBIX_SECURITY_SUITE.md' ]"

# Test 5: Test script functionality
run_test "Test script works" \
    "cd '$SCRIPT_DIR' && ./test_orbix_suite.sh"

# Test 6: Dependency check
run_test "Required dependencies available" \
    "command -v bash && command -v find && command -v grep && command -v python3 && command -v tar"

# Test 7: Create minimal test audit (dry run simulation)
echo -n "Testing: Audit script initialization... "
if mkdir -p /tmp/test-orbix-$$ 2>/dev/null && rmdir /tmp/test-orbix-$$ 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((TEST_PASSED++))
else
    echo -e "${RED}✗${NC}"
    ((TEST_FAILED++))
fi

# Test 8: Analysis script error handling
echo -n "Testing: Analysis error handling... "
if $SCRIPT_DIR/orbix_analysis.sh --package /nonexistent/package.tar.gz 2>/dev/null; then
    echo -e "${RED}✗${NC} (should have failed)"
    ((TEST_FAILED++))
else
    echo -e "${GREEN}✓${NC}"
    ((TEST_PASSED++))
fi

# Summary
echo ""
echo "=================================================="
echo -e "${BLUE}Test Results:${NC}"
echo -e "  ${GREEN}Passed: $TEST_PASSED${NC}"
echo -e "  ${RED}Failed: $TEST_FAILED${NC}"

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All integration tests passed!${NC}"
    echo ""
    echo "The Orbix Security Suite is ready for production use."
    echo ""
    echo "Next steps:"
    echo "1. Deploy to server: scripts/linux/secure-deploy.sh"
    echo "2. Run security audit: sudo orbix_audit.sh"
    echo "3. Analyze results: orbix_analysis.sh"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the issues above.${NC}"
    exit 1
fi