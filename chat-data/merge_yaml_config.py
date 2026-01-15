#!/usr/bin/env python3
"""
Merges YAML configuration files by applying overrides to a base config.
Usage: merge_yaml_config.py <base_config> <overrides_config>
"""

import sys
import yaml


def merge_dicts(base, override):
    """Recursively merge override dict into base dict."""
    for key, value in override.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            merge_dicts(base[key], value)
        else:
            base[key] = value


def main():
    if len(sys.argv) != 3:
        print("Usage: merge_yaml_config.py <base_config> <overrides_config>")
        sys.exit(1)

    base_config_path = sys.argv[1]
    overrides_config_path = sys.argv[2]

    # Load both files
    with open(base_config_path, 'r') as f:
        config = yaml.safe_load(f)

    with open(overrides_config_path, 'r') as f:
        overrides = yaml.safe_load(f)

    # Merge overrides into config (overrides take precedence)
    merge_dicts(config, overrides)

    # Write back to base config file
    with open(base_config_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False,
                  allow_unicode=True, width=120, indent=2)


if __name__ == '__main__':
    main()
