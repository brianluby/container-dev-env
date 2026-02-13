## Summary

-

## Validation

- [ ] Local checks passed
- [ ] CI checks passed

## Digest Pinning Evidence (required for Docker base image updates)

- [ ] In-scope Dockerfiles use `tag@digest` for external `FROM`
- [ ] `./scripts/validate-base-image-digests.sh` passed locally
- [ ] CI digest validation step passed
- [ ] Two-run reproducibility evidence recorded
- [ ] Timed refresh run recorded under 30 minutes (if refresh performed)

### Old/New digest map

| Dockerfile | Old digest | New digest |
|------------|------------|------------|
| `Dockerfile` | | |
| `docker/Dockerfile` | | |
| `docker/Dockerfile.ide` | | |
| `docker/memory.Dockerfile` | | |

### Verification references

- Local validator output:
- CI workflow URL:
- Reproducibility evidence (`diff` output):
- Timed refresh duration:
