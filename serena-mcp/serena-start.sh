#!/bin/bash
set -e

# Auto-discover and initialize Serena projects if enabled
if [ "$SERENA_AUTODISCOVER" = "1" ]; then
  echo "SERENA_AUTODISCOVER enabled, scanning /workspaces/projects..."

  if [ -d /workspaces/projects ]; then
    # Array to collect project paths
    PROJECT_PATHS=()

    # Iterate through each subdirectory in /workspaces/projects
    for project_dir in /workspaces/projects/*/; do
      if [ -d "$project_dir" ]; then
        # Remove trailing slash
        project_dir="${project_dir%/}"
        project_name=$(basename "$project_dir")
        echo "Initializing Serena project in $project_name"

        # Change to the project directory and run serena project create
        cd "$project_dir"

        # Pipe 'yes' to accept all prompts
        if yes | serena project create 2>&1; then
          echo "Successfully initialized Serena project: $project_name"
        else
          echo "Warning: Failed to initialize Serena project: $project_name (may already exist)"
        fi

        # Add to project paths array
        PROJECT_PATHS+=("$project_dir")
      fi
    done

    echo "Serena project auto-discovery complete"

    # Update serena_config.yml with discovered projects
    if [ ${#PROJECT_PATHS[@]} -gt 0 ]; then
      echo "Updating serena_config.yml with ${#PROJECT_PATHS[@]} discovered projects..."

      # Update the YAML config with discovered project paths
      python3 /workspaces/serena/config/update_serena_config.py "${PROJECT_PATHS[@]}"
    else
      echo "No projects found to add to serena_config.yml"
    fi
  else
    echo "Warning: /workspaces/projects directory not found, skipping auto-discovery"
  fi
else
  echo "SERENA_AUTODISCOVER not enabled, skipping project auto-discovery"
fi

# Start the Serena MCP server
echo "Starting Serena MCP server..."
exec serena start-mcp-server \
  --transport streamable-http \
  --port 9121 \
  --host 0.0.0.0 \
  --enable-web-dashboard true \
  --context claude-code
