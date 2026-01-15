#!/usr/bin/env python3
"""
Updates serena_config.yml with a list of project paths.
Usage: update_serena_config.py <path1> <path2> <path3> ...
"""

import yaml
import sys

config_path = '/workspaces/serena/config/serena_config.yml'

# Get project paths from command line arguments
project_paths = sys.argv[1:] if len(sys.argv) > 1 else []

# Load the config
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# Update the projects list
config['projects'] = project_paths

# Write back the config
with open(config_path, 'w') as f:
    yaml.dump(config, f, default_flow_style=False, sort_keys=False)

print(f"Successfully updated serena_config.yml with {len(project_paths)} projects")
