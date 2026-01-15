#!/bin/bash

# Entry point script for Docker container
# Keeps the container running indefinitely

echo "whoami? `whoami`; which claude? `which claude`"

echo "Adding Serena MCP to Claude Code..."
claude mcp add --transport http serena http://serena-mcp:9121/mcp

echo "Adding Context7 MCP to Claude Code..."
if [ -n "$CONTEXT7_API_KEY" ]; then claude mcp add --transport http context7 https://mcp.context7.com/mcp --header "CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}"; fi

echo "Container started at $(date)"
echo "Running indefinitely..."

# Keep container running indefinitely without blocking
# This allows the container to stay up and respond to signals properly
tail -f /dev/null
