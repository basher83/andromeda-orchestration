#!/bin/bash
# MegaLinter Runner - Fast Local Testing
# Uses efrecon/mega-linter-runner for ultra-fast MegaLinter execution
# No Node.js dependencies required!

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
FLAVOR="terraform"
LINT_FILTER=""
TIMEOUT=600
DOWNLOAD_URL="https://raw.githubusercontent.com/efrecon/mega-linter-runner/main/mega-linter-runner.sh"
RUNNER_SCRIPT="/tmp/mega-linter-runner.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --flavor=*)
            FLAVOR="${1#*=}"
            shift
            ;;
        --linter-filter=*)
            LINT_FILTER="${1#*=}"
            shift
            ;;
        --timeout=*)
            TIMEOUT="${1#*=}"
            shift
            ;;
        --help)
            echo "MegaLinter Runner - Fast Local Testing"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --flavor=NAME     MegaLinter flavor (default: terraform)"
            echo "  --linter-filter=FILTER   Filter specific linters"
            echo "  --timeout=SEC     Timeout in seconds (default: 600)"
            echo "  --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0"
            echo "  $0 --flavor=terraform"
            echo "  $0 --linter-filter=ANSIBLE_ANSIBLE_LINT"
            echo "  $0 --timeout=300"
            echo ""
            echo "This script uses efrecon/mega-linter-runner for ultra-fast"
            echo "MegaLinter execution without Node.js dependencies."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🚀 MegaLinter Runner (Fast Mode)"
echo "==============================="
echo "Flavor: $FLAVOR"
echo "Repository: $REPO_ROOT"
echo "Timeout: ${TIMEOUT}s"
if [ -n "$LINT_FILTER" ]; then
    echo "Linter Filter: $LINT_FILTER"
fi
echo

cd "$REPO_ROOT"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. MegaLinter requires Docker to run."
    echo "   Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Download efrecon mega-linter-runner if not present
if [ ! -f "$RUNNER_SCRIPT" ]; then
    echo "📥 Downloading efrecon/mega-linter-runner..."
    if ! curl -s "$DOWNLOAD_URL" -o "$RUNNER_SCRIPT"; then
        echo "❌ Failed to download mega-linter-runner"
        exit 1
    fi
    chmod +x "$RUNNER_SCRIPT"
    echo "✅ Downloaded to $RUNNER_SCRIPT"
fi

# Build command
CMD="$RUNNER_SCRIPT --flavor $FLAVOR"

# Add linter filter if specified
if [ -n "$LINT_FILTER" ]; then
    CMD="$CMD --linter-filter $LINT_FILTER"
fi

echo "🏃 Running MegaLinter..."
echo "Command: $CMD"
echo

# Run with timeout and better error handling
set +e  # Temporarily disable exit on error
timeout "$TIMEOUT" bash -c "$CMD"
EXIT_CODE=$?
set -e  # Re-enable exit on error

if [ $EXIT_CODE -eq 0 ]; then
    echo
    echo "✅ MegaLinter run completed successfully!"
    echo
    echo "💡 Tips:"
    echo "   - This method is 2-3x faster than traditional approaches"
    echo "   - No Node.js dependencies required"
    echo "   - Uses pre-built Docker containers directly"
elif [ $EXIT_CODE -eq 124 ]; then
    echo
    echo "⏰ MegaLinter run timed out after ${TIMEOUT} seconds"
    echo "   Try increasing timeout with --timeout=1200"
    exit 1
else
    echo
    echo "❌ MegaLinter run failed (exit code: $EXIT_CODE)"
    echo
    # Check if this is an ARM64 Mac issue
    if [[ "$OSTYPE" == "darwin"* ]] && [[ $(uname -m) == "arm64" ]]; then
        echo "💡 ARM64 Mac detected - efrecon runner may have compatibility issues"
        echo "   Try these alternatives:"
        echo "   • ./scripts/test-megalinter.sh --quick"
        echo "   • docker run --rm -v \"\$(pwd):/tmp/lint\" oxsecurity/megalinter:v8 --config-file .mega-linter.yml"
        echo "   • mise run act-quick (uses Docker directly)"
    fi
    echo
    echo "📝 For more help, see: docs/getting-started/megalinter-implementation.md"
    exit 1
fi
