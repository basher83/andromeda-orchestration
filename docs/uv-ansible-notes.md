# UV and Ansible Integration Notes

## Current Approach

This project uses `uv` with Ansible in a virtual environment setup, which avoids the limitations described in [uv issue #6314](https://github.com/astral-sh/uv/issues/6314).

### Why we use `uv pip install` instead of `uv tool install`

The issue with `uv tool install ansible-core` is that it doesn't install all the necessary executables from Ansible's sub-packages. This would mean commands like `ansible-playbook`, `ansible-galaxy`, etc. wouldn't be available.

Our approach:

1. Create a virtual environment: `uv venv`
2. Install packages in the venv: `uv pip install -e ".[dev]"`
3. Run commands with: `uv run <command>`

This ensures all Ansible executables are properly installed and accessible.

### Benefits of our approach

- **All executables available**: `ansible`, `ansible-playbook`, `ansible-galaxy`, `ansible-lint`, etc.
- **Consistent environment**: All tools use the same Python environment
- **No system pollution**: Everything is isolated in the virtual environment
- **Works with editable installs**: Development dependencies are properly managed

### Commands that work with our setup

All these commands work correctly:

```bash
uv run ansible --version
uv run ansible-playbook playbooks/site.yml
uv run ansible-galaxy collection install -r requirements.yml
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
uv run ansible-lint
uv run ansible-vault encrypt_string
```

### If uv adds `--install-deps` in the future

Once uv implements the feature to install executables from dependency packages (as discussed in the issue), we could potentially simplify to:

```bash
uv tool install ansible-core --install-deps
```

But for now, our virtual environment approach is more reliable and gives us better control over the environment.

## Taskfile Integration

The Taskfile.yml is configured to use `uv run` for all Python-based commands, which ensures consistency across the project. This approach works seamlessly with our virtual environment setup.

## Troubleshooting

If you encounter issues with Ansible commands not being found:

1. Ensure you've run the setup: `task setup`
2. Check the virtual environment exists: `ls .venv/bin/`
3. Verify ansible is installed: `uv pip list | grep ansible`
4. Try running directly: `.venv/bin/ansible --version`

If commands work with `.venv/bin/` prefix but not with `uv run`, ensure you're in the project directory where the `.venv` exists.
