#!/usr/bin/env bash
# Find all TODO tags in documentation
# This script is maintained for backward compatibility
# For more comprehensive tag searching, use find-tags.sh

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the new find-tags.sh script with TODO filter
"${SCRIPT_DIR}/find-tags.sh" TODO
