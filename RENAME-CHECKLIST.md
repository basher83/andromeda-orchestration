# Repository Rename Checklist

Renaming from `andromeda-orchestration` to `andromeda-orchestration`

## Pre-Rename Tasks

- [x] Commit all current changes
- [x] Push to GitHub
- [x] Note any external references to the old repo name
  - [x] Updated pyproject.toml and regenerated uv.lock

## GitHub Rename

- [x] Go to Settings → General
- [x] Change repository name to `andromeda-orchestration`
- [x] Click Rename

## Post-Rename Updates

### Local Git Remote

```bash
git remote set-url origin https://github.com/basher83/andromeda-orchestration.git
git remote -v  # Verify
```

**confirmed**

```bash
git remote -v
origin	https://github.com/basher83/andromeda-orchestration.git (fetch)
origin	https://github.com/basher83/andromeda-orchestration.git (push)
```

### Documentation Updates (already done in this session)

- [x] README.md title updated
- [x] CI badge URL updated
- [x] Historical note updated

### Other References to Update

- [ ] Any external documentation linking here
- [ ] terraform-homelab references (if any)
- [ ] Mission Control references (if any)
- [ ] Local scripts or aliases
- [ ] Environment variables (if any reference the repo)

### Verify Everything Works

- [ ] Clone fresh copy to test
- [ ] Run `task setup` to ensure everything works
- [ ] Test a simple playbook run

## Benefits of New Name

- ✅ Follows Mission Control galaxy-tier naming convention
- ✅ Clearly indicates production-level importance
- ✅ "Orchestration" better describes the full scope
- ✅ Maintains space theme consistency with terraform-homelab

## Notes

- GitHub will automatically redirect the old URL
- Existing clones will continue to work (but should update remote)
- All issues, PRs, stars, and history are preserved
