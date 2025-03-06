#!/bin/bash
# Script to collect Lustre jobstats using fefssv_v3.py with collectl

# Check if we have sudo privilege
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo"
   exit 1
fi

# Check if collectl is installed
if ! command -v collectl &> /dev/null; then
    echo "collectl is not installed. Installing..."
    # Try to detect OS and install
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y collectl
    elif command -v yum &> /dev/null; then
        yum install -y collectl
    else
        echo "Could not install collectl. Please install it manually."
        exit 1
    fi
fi

# Check if the Python script exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_PLUGIN="$SCRIPT_DIR/fefssv_v3.py"

if [ ! -f "$PYTHON_PLUGIN" ]; then
    echo "Error: Could not find fefssv_v3.py in $SCRIPT_DIR"
    exit 1
fi

# Make sure the plugin is executable
chmod +x "$PYTHON_PLUGIN"

# Create output directory
OUTPUT_DIR="$SCRIPT_DIR/lustre_stats"
mkdir -p "$OUTPUT_DIR"

# Show usage information
function show_usage {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -m, --mdt        Collect MDT statistics (default)"
    echo "  -o, --ost        Collect OST statistics"
    echo "  -d, --detail     Show detailed output per volume"
    echo "  -v, --verbose    Show verbose output per job"
    echo "  -i, --interval N Set collection interval in seconds (default: 10)"
    echo "  -t, --time N     Run for N seconds then exit"
    echo "  -f, --file NAME  Save to specified filename"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --mdt --detail --interval 5 --time 60"
    echo "  $0 --ost --verbose --file ost_stats"
    exit 1
}

# Default values
VOLUME_TYPE="mdt"
OUTPUT_MODE=""
INTERVAL="10"
RUNTIME=""
FILENAME="lustre_stats_$(date +%Y%m%d_%H%M%S)"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -m|--mdt)
            VOLUME_TYPE="mdt"
            shift
            ;;
        -o|--ost)
            VOLUME_TYPE="ost"
            shift
            ;;
        -d|--detail)
            OUTPUT_MODE="d"
            shift
            ;;
        -v|--verbose)
            OUTPUT_MODE="v"
            shift
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -t|--time)
            RUNTIME="$2"
            shift 2
            ;;
        -f|--file)
            FILENAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Build the command
CMD="collectl --import $PYTHON_PLUGIN -s+Ljobstats --interval $INTERVAL"

# Add options
if [ ! -z "$OUTPUT_MODE" ]; then
    CMD="$CMD --devopts $OUTPUT_MODE,$VOLUME_TYPE"
else
    CMD="$CMD --devopts $VOLUME_TYPE"
fi

# Add runtime if specified
if [ ! -z "$RUNTIME" ]; then
    CMD="$CMD --all $RUNTIME"
fi

# Add output file
CMD="$CMD -f $OUTPUT_DIR/$FILENAME"

echo "Starting Lustre statistics collection..."
echo "Command: $CMD"
echo "Output will be saved to $OUTPUT_DIR/$FILENAME"
echo "Press Ctrl+C to stop collection"

# Run the command
eval $CMD

echo "Collection complete. Data saved to $OUTPUT_DIR/$FILENAME"
