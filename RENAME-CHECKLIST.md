# Repository Rename Checklist

Renaming from `netbox-ansible` to `andromeda-orchestration`

## Pre-Rename Tasks
- [ ] Commit all current changes
- [ ] Push to GitHub
- [ ] Note any external references to the old repo name

## GitHub Rename
- [ ] Go to Settings → General
- [ ] Change repository name to `andromeda-orchestration`
- [ ] Click Rename

## Post-Rename Updates

### Local Git Remote
```bash
git remote set-url origin https://github.com/basher83/andromeda-orchestration.git
git remote -v  # Verify
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