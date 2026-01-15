#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
model=$(echo "$input" | jq -r '.model.display_name // .model.id // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "~"')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Get git branch (skip optional locks to avoid conflicts)
if [ -d "$cwd/.git" ]; then
    git_branch=$(cd "$cwd" && git -c core.fileMode=false config --global --add safe.directory "$cwd" 2>/dev/null; git branch --show-current 2>/dev/null || echo "detached")
else
    # Check parent directories for git repo
    check_dir="$cwd"
    git_branch=""
    while [ "$check_dir" != "/" ] && [ "$check_dir" != "." ]; do
        if [ -d "$check_dir/.git" ]; then
            git_branch=$(cd "$check_dir" && git -c core.fileMode=false config --global --add safe.directory "$check_dir" 2>/dev/null; git branch --show-current 2>/dev/null || echo "detached")
            break
        fi
        check_dir=$(dirname "$check_dir")
    done
    if [ -z "$git_branch" ]; then
        git_branch="no-git"
    fi
fi

# Format directory path (replace home with ~)
home_dir="$HOME"
if [ -n "$home_dir" ] && [[ "$cwd" == "$home_dir"* ]]; then
    display_dir="~${cwd#$home_dir}"
else
    display_dir="$cwd"
fi

# Build status line components
components=()

# Model
components+=("$(printf '\033[1m%s\033[0m' "$model")")

# Git Branch
if [ "$git_branch" != "no-git" ]; then
    components+=("$(printf '\033[36m%s\033[0m' "$git_branch")")
fi

# Tokens (context remaining)
if [ -n "$remaining" ]; then
    # Color code based on remaining percentage
    if (( $(echo "$remaining < 20" | bc -l 2>/dev/null || echo 0) )); then
        token_color='\033[31m' # Red
    elif (( $(echo "$remaining < 50" | bc -l 2>/dev/null || echo 0) )); then
        token_color='\033[33m' # Yellow
    else
        token_color='\033[32m' # Green
    fi
    # Round to 1 decimal place
    remaining_formatted=$(printf "%.1f" "$remaining")
    components+=("$(printf "${token_color}%s%%\033[0m" "$remaining_formatted")")
fi

# Directory
components+=("$(printf '\033[34m%s\033[0m' "$display_dir")")

# Join components with separator
separator=" $(printf '\033[2m|\033[0m') "
output=""
for i in "${!components[@]}"; do
    if [ $i -eq 0 ]; then
        output="${components[$i]}"
    else
        output="$output$separator${components[$i]}"
    fi
done

echo -e "$output"
