#!/bin/bash
# Script to compare the output of the Perl and Python implementations of fefssv

# Check if we have sudo privilege
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo"
   exit 1
fi

# Make sure both modules exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_MODULE="$SCRIPT_DIR/fefssv_v3.py"
PERL_MODULE="$SCRIPT_DIR/fefssv.ph"

if [ ! -f "$PYTHON_MODULE" ]; then
    echo "Error: Python module not found at $PYTHON_MODULE"
    exit 1
fi

if [ ! -f "$PERL_MODULE" ]; then
    echo "Error: Perl module not found at $PERL_MODULE"
    exit 1
fi

# Make Python module executable
chmod +x "$PYTHON_MODULE"

# Create temporary output directory
TEMP_DIR="$(mktemp -d)"
PERL_OUTPUT="$TEMP_DIR/perl_output.csv"
PYTHON_OUTPUT="$TEMP_DIR/python_output.csv"

echo "=== Comparing Perl and Python implementations of fefssv ==="
echo "Running tests with both implementations..."

# Test with MDT stats in detail mode
echo "Testing MDT stats in detail mode..."
echo "  Running Perl version..."
collectl --import "$PERL_MODULE" -s+Ljobstats --devopts d,mdt --all 5 --export csv,"$PERL_OUTPUT.mdt.detail"
echo "  Running Python version..."
collectl --import "$PYTHON_MODULE" -s+Ljobstats --devopts d,mdt --all 5 --export csv,"$PYTHON_OUTPUT.mdt.detail"

# Test with OST stats in detail mode
echo "Testing OST stats in detail mode..."
echo "  Running Perl version..."
collectl --import "$PERL_MODULE" -s+Ljobstats --devopts d,ost --all 5 --export csv,"$PERL_OUTPUT.ost.detail"
echo "  Running Python version..."
collectl --import "$PYTHON_MODULE" -s+Ljobstats --devopts d,ost --all 5 --export csv,"$PYTHON_OUTPUT.ost.detail"

# Test with MDT stats in verbose mode
echo "Testing MDT stats in verbose mode..."
echo "  Running Perl version..."
collectl --import "$PERL_MODULE" -s+Ljobstats --devopts v,mdt --all 5 --export csv,"$PERL_OUTPUT.mdt.verbose"
echo "  Running Python version..."
collectl --import "$PYTHON_MODULE" -s+Ljobstats --devopts v,mdt --all 5 --export csv,"$PYTHON_OUTPUT.mdt.verbose"

# Test with OST stats in verbose mode
echo "Testing OST stats in verbose mode..."
echo "  Running Perl version..."
collectl --import "$PERL_MODULE" -s+Ljobstats --devopts v,ost --all 5 --export csv,"$PERL_OUTPUT.ost.verbose"
echo "  Running Python version..."
collectl --import "$PYTHON_MODULE" -s+Ljobstats --devopts v,ost --all 5 --export csv,"$PYTHON_OUTPUT.ost.verbose"

# Analyze the differences
echo "=== Analysis of differences ==="

check_differences() {
    local perl_file="$1"
    local python_file="$2"
    local test_name="$3"

    if [ ! -f "$perl_file" ] || [ ! -f "$python_file" ]; then
        echo "[$test_name] ERROR: One or both output files missing"
        return
    fi

    # Remove header lines and timestamps that might differ
    grep -v "^#" "$perl_file" | cut -d, -f3- > "${perl_file}.tmp"
    grep -v "^#" "$python_file" | cut -d, -f3- > "${python_file}.tmp"

    # Compare data values only
    if diff -q "${perl_file}.tmp" "${python_file}.tmp" > /dev/null; then
        echo "[$test_name] MATCH: Data values are identical"
    else
        echo "[$test_name] DIFFERENCE: Data values differ"
        echo "  Differences:"
        diff -u "${perl_file}.tmp" "${python_file}.tmp" | head -n 20
    fi
}

check_differences "$PERL_OUTPUT.mdt.detail" "$PYTHON_OUTPUT.mdt.detail" "MDT Detail Mode"
check_differences "$PERL_OUTPUT.ost.detail" "$PYTHON_OUTPUT.ost.detail" "OST Detail Mode"
check_differences "$PERL_OUTPUT.mdt.verbose" "$PYTHON_OUTPUT.mdt.verbose" "MDT Verbose Mode"
check_differences "$PERL_OUTPUT.ost.verbose" "$PYTHON_OUTPUT.ost.verbose" "OST Verbose Mode"

# Clean up
echo "=== Cleaning up temporary files ==="
rm -rf "$TEMP_DIR"

echo "=== Comparison complete ==="
echo "Both implementations should produce equivalent data with potentially minor formatting differences."
echo "If you see significant differences, check for bugs in the Python reimplementation."
