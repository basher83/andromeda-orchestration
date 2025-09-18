#!/bin/bash
# MegaLinter Local Testing Script
# This script helps developers test MegaLinter locally before pushing to CI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse command line arguments
QUICK_MODE=false
FAST_MODE=false
LINT_FILTER=""
TIMEOUT=300

       while [[ $# -gt 0 ]]; do
           case $1 in
               --quick)
                   QUICK_MODE=true
                   shift
                   ;;
               --fast)
                   FAST_MODE=true
                   shift
                   ;;
               --linter=*)
                   LINT_FILTER="${1#*=}"
                   shift
                   ;;
               --timeout=*)
                   TIMEOUT="${1#*=}"
                   shift
                   ;;
               --help)
                   echo "Usage: $0 [OPTIONS]"
                   echo ""
                   echo "Options:"
                   echo "  --quick         Quick validation mode (limited linters)"
                   echo "  --fast          Use efrecon/mega-linter-runner (fastest, no Node.js)"
                   echo "  --linter=NAME   Test specific linter (e.g., ANSIBLE_ANSIBLE_LINT)"
                   echo "  --timeout=SEC   Set timeout in seconds (default: 300)"
                   echo "  --help          Show this help message"
                   echo ""
                   echo "Examples:"
                   echo "  $0 --quick"
                   echo "  $0 --fast"
                   echo "  $0 --linter=ANSIBLE_ANSIBLE_LINT"
                   echo "  $0 --timeout=120"
                   exit 0
                   ;;
               *)
                   echo "Unknown option: $1"
                   echo "Use --help for usage information"
                   exit 1
                   ;;
           esac
       done

echo "🔍 MegaLinter Local Testing"
echo "==========================="
echo "Repository: $REPO_ROOT"
if [ "$FAST_MODE" = true ]; then
    echo "Mode: Fast (efrecon/mega-linter-runner)"
elif [ "$QUICK_MODE" = true ]; then
    echo "Mode: Quick"
else
    echo "Mode: Full"
fi
echo "Linter Filter: $([ -n "$LINT_FILTER" ] && echo "$LINT_FILTER" || echo "All")"
echo "Timeout: ${TIMEOUT}s"
echo

cd "$REPO_ROOT"

# Check if uv is available
if ! command -v uv &> /dev/null; then
    echo "❌ uv is not installed. Please install uv first:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# Check if docker is available for MegaLinter
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. MegaLinter requires Docker to run locally."
    echo "   Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Ansible Galaxy collections are installed
if [ ! -d "$HOME/.ansible/collections" ]; then
    echo "📦 Installing Ansible Galaxy collections..."
    uv sync --extra dev
    uv run ansible-galaxy collection install -r requirements.yml
fi

# Check if .mega-linter.yml exists
if [ ! -f ".mega-linter.yml" ]; then
    echo "❌ .mega-linter.yml not found!"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo

# Handle fast mode with efrecon/mega-linter-runner
if [ "$FAST_MODE" = true ]; then
    echo "🚀 Using efrecon/mega-linter-runner (fast mode)"
    echo "This method uses Docker containers directly without Node.js dependencies"
    echo

    # Use local mega-linter-runner.sh script
    if [ ! -f "$SCRIPT_DIR/mega-linter-runner.sh" ]; then
        echo "❌ Local mega-linter-runner.sh not found!"
        echo "   Expected location: $SCRIPT_DIR/mega-linter-runner.sh"
        exit 1
    fi

    # Build command for efrecon runner
    EFRECON_CMD="$SCRIPT_DIR/mega-linter-runner.sh --flavor terraform"

    # Add linter filter if specified
    if [ -n "$LINT_FILTER" ]; then
        EFRECON_CMD="$EFRECON_CMD --linter-filter $LINT_FILTER"
    fi

    # Add timeout
    EFRECON_CMD="$EFRECON_CMD --timeout $TIMEOUT"

    echo "🏃 Running local mega-linter-runner.sh..."
    echo "Command: $EFRECON_CMD"
    echo

    # Run the local script
    bash -c "$EFRECON_CMD"

    echo
    echo "✅ Fast MegaLinter run completed!"
    echo
    echo "💡 Tips:"
    echo "   - This method is fastest as it uses pre-built containers"
    echo "   - No Node.js dependencies required"
    echo "   - For more control, use the regular Docker method"
    exit 0
fi

# Build MegaLinter command
echo "🚀 Running MegaLinter..."
echo "This may take several minutes depending on repository size..."
echo

DOCKER_CMD="docker run --rm \
    -v \"$PWD:/tmp/lint\" \
    -w \"/tmp/lint\" \
    --env-file <(env | grep -E '^(ANSIBLE_|PYTHON_|YAML_|MARKDOWN_|ACTION_)' || true) \
    oxsecurity/megalinter:v8 \
    --config-file .mega-linter.yml"

# Add quick mode settings
if [ "$QUICK_MODE" = true ]; then
    DOCKER_CMD="$DOCKER_CMD \
        --linters-filter ANSIBLE_ANSIBLE_LINT,YAML_YAMLLINT,YAML_PRETTIER,PYTHON_RUFF,MARKDOWN_MARKDOWNLINT"
fi

# Add linter filter
if [ -n "$LINT_FILTER" ]; then
    DOCKER_CMD="$DOCKER_CMD --linters-filter $LINT_FILTER"
fi

# Add timeout and run
echo "Command: timeout ${TIMEOUT}s $DOCKER_CMD"
echo

timeout "$TIMEOUT" bash -c "$DOCKER_CMD"

echo
echo "✅ MegaLinter completed successfully!"
echo
echo "💡 Tips:"
echo "   - Use 'mega-linter-runner --fix' to auto-fix issues"
echo "   - Run specific linters with --linters-filter"
echo "   - See https://megalinter.io/8/configuration/ for more options"
