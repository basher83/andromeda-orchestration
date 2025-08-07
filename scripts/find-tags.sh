#!/usr/bin/env bash
# Find all tags (TODO, FIXME, BUG, etc.) in code and documentation
# Usage: ./find-tags.sh [tag-type]
# Examples:
#   ./find-tags.sh          # Find all tags
#   ./find-tags.sh TODO     # Find only TODO tags
#   ./find-tags.sh FIXME    # Find only FIXME tags

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Tag colors based on priority
declare -A TAG_COLORS=(
    ["SECURITY"]="${RED}"
    ["FIXME"]="${RED}"
    ["BUG"]="${RED}"
    ["TODO"]="${YELLOW}"
    ["HACK"]="${YELLOW}"
    ["DEPRECATED"]="${MAGENTA}"
    ["WARNING"]="${CYAN}"
    ["NOTE"]="${BLUE}"
)

# Get tag type from argument or use all
TAG_FILTER="${1:-ALL}"
TAG_FILTER=$(echo "$TAG_FILTER" | tr '[:lower:]' '[:upper:]')

# Build regex pattern
if [ "$TAG_FILTER" = "ALL" ]; then
    DOC_PATTERN='\[(TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY)\]:'
    CODE_PATTERN='# (TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY):'
    ALL_PATTERN='(\[|# )(TODO|FIXME|BUG|HACK|WARNING|NOTE|DEPRECATED|SECURITY):'
    echo -e "${GREEN}Searching for all tags in project...${NC}\n"
else
    DOC_PATTERN="\[${TAG_FILTER}\]:"
    CODE_PATTERN="# ${TAG_FILTER}:"
    ALL_PATTERN="(\[|# )${TAG_FILTER}:"
    echo -e "${GREEN}Searching for ${TAG_FILTER} tags in project...${NC}\n"
fi

# Function to count tags by type
count_tags() {
    local pattern="$1"
    local count=$(rg "$pattern" . \
        --glob '!.venv/**' \
        --glob '!venv/**' \
        --glob '!.archive/**' \
        --glob '!.testing/**' \
        --glob '!.git/**' \
        --glob '!node_modules/**' \
        --count-matches 2>/dev/null | \
        awk -F: '{sum+=$2} END {print sum}')
    echo "${count:-0}"
}

# Function to display tags with context
show_tags() {
    local pattern="$1"
    local title="$2"
    
    echo -e "${YELLOW}=== $title ===${NC}"
    
    # Find and display with colors
    rg "$pattern" . \
        --glob '!.venv/**' \
        --glob '!venv/**' \
        --glob '!.archive/**' \
        --glob '!.testing/**' \
        --glob '!.git/**' \
        --glob '!node_modules/**' \
        --no-heading \
        --line-number \
        --color never 2>/dev/null | \
    while IFS= read -r line; do
        # Simple coloring based on tag presence
        displayed=false
        for tag in TODO FIXME BUG HACK WARNING NOTE DEPRECATED SECURITY; do
            if [[ $line == *"[$tag]:"* ]] || [[ $line == *"# $tag:"* ]]; then
                color="${TAG_COLORS[$tag]:-$NC}"
                echo -e "${color}${line}${NC}"
                displayed=true
                break
            fi
        done
        if [ "$displayed" = false ]; then
            echo "$line"
        fi
    done || echo "  No tags found"
    
    echo ""
}

# Show tags in documentation
if [ "$TAG_FILTER" = "ALL" ] || [ "$TAG_FILTER" = "TODO" ] || [ "$TAG_FILTER" = "FIXME" ] || \
   [ "$TAG_FILTER" = "BUG" ] || [ "$TAG_FILTER" = "HACK" ] || [ "$TAG_FILTER" = "WARNING" ] || \
   [ "$TAG_FILTER" = "NOTE" ] || [ "$TAG_FILTER" = "DEPRECATED" ] || [ "$TAG_FILTER" = "SECURITY" ]; then
    
    # Documentation tags
    show_tags "$DOC_PATTERN" "Documentation Tags"
    
    # Code tags
    show_tags "$CODE_PATTERN" "Code Tags"
fi

# Summary statistics
echo -e "${CYAN}=== Summary ===${NC}"

if [ "$TAG_FILTER" = "ALL" ]; then
    # Count each tag type
    declare -A tag_counts
    for tag in TODO FIXME BUG HACK WARNING NOTE DEPRECATED SECURITY; do
        doc_count=$(count_tags "\[${tag}\]:")
        code_count=$(count_tags "# ${tag}:")
        total=$((doc_count + code_count))
        if [ $total -gt 0 ]; then
            tag_counts[$tag]=$total
            color="${TAG_COLORS[$tag]:-$NC}"
            printf "${color}%-12s: %3d${NC}\n" "$tag" "$total"
        fi
    done
    
    # Total count
    echo "-------------------"
    total_all=$(count_tags "$ALL_PATTERN")
    echo -e "${GREEN}Total tags  : ${total_all}${NC}"
    
    # Priority breakdown
    echo ""
    echo -e "${CYAN}=== By Priority ===${NC}"
    
    critical=$((${tag_counts[SECURITY]:-0}))
    high=$((${tag_counts[FIXME]:-0} + ${tag_counts[BUG]:-0}))
    medium=$((${tag_counts[TODO]:-0} + ${tag_counts[HACK]:-0}))
    low=$((${tag_counts[DEPRECATED]:-0}))
    info=$((${tag_counts[WARNING]:-0} + ${tag_counts[NOTE]:-0}))
    
    [ $critical -gt 0 ] && echo -e "${RED}Critical : $critical (SECURITY)${NC}"
    [ $high -gt 0 ] && echo -e "${RED}High     : $high (FIXME, BUG)${NC}"
    [ $medium -gt 0 ] && echo -e "${YELLOW}Medium   : $medium (TODO, HACK)${NC}"
    [ $low -gt 0 ] && echo -e "${MAGENTA}Low      : $low (DEPRECATED)${NC}"
    [ $info -gt 0 ] && echo -e "${BLUE}Info     : $info (WARNING, NOTE)${NC}"
else
    # Single tag type count
    total=$(count_tags "$ALL_PATTERN")
    color="${TAG_COLORS[$TAG_FILTER]:-$NC}"
    echo -e "${color}Total ${TAG_FILTER} tags: ${total}${NC}"
fi

# Suggest next action
echo ""
if [ "$TAG_FILTER" = "ALL" ]; then
    if [ ${tag_counts[SECURITY]:-0} -gt 0 ]; then
        echo -e "${RED}⚠️  SECURITY tags found - address immediately!${NC}"
    elif [ ${tag_counts[FIXME]:-0} -gt 0 ] || [ ${tag_counts[BUG]:-0} -gt 0 ]; then
        echo -e "${RED}⚠️  High priority issues found (FIXME/BUG) - address in current sprint${NC}"
    elif [ ${tag_counts[TODO]:-0} -gt 0 ]; then
        echo -e "${YELLOW}📝 TODO items found - schedule for next refactor${NC}"
    else
        echo -e "${GREEN}✅ No action items found!${NC}"
    fi
fi