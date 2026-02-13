# Quickstart: Pin Base Images to Immutable Digests

## Prerequisites

- Docker with Buildx enabled
- Access to local repository and CI workflow runs
- Feature branch: `001-pin-image-digests`

## 1) Confirm feature scope

Verify only these Dockerfiles are in scope:

- `Dockerfile`
- `docker/Dockerfile`
- `docker/Dockerfile.ide`
- `docker/memory.Dockerfile`

## 2) Identify candidate digests

For each external `FROM` in the in-scope Dockerfiles:

1. Resolve an immutable digest for the intended upstream image tag.
2. Confirm the digest supports both `linux/amd64` and `linux/arm64`.
3. If either platform is missing, stop and choose a compliant base reference.

## 3) Apply pinning updates

Update each external `FROM` to `tag@digest` format.

Expected outcome:

- No tag-only external base references remain in scoped files.

## 4) Run local verification

Run the project's local verification flow for container builds and checks.

Expected outcome:

- Local verification passes with no regressions.

## 5) Validate CI gate

Push branch and ensure CI checks pass, including multi-architecture build/validation.

Expected outcome:

- CI verification passes for in-scope changes.

## 6) Document refresh evidence

Record old/new digests and verification evidence in the pull request description.

Expected outcome:

- Reviewer can trace each digest update and confirm both local + CI validation.

## 7) Capture two-run reproducibility evidence

Run the digest validator twice and confirm output consistency.

```bash
./scripts/validate-base-image-digests.sh --json > /tmp/digest-run-1.json
./scripts/validate-base-image-digests.sh --json > /tmp/digest-run-2.json
diff -u /tmp/digest-run-1.json /tmp/digest-run-2.json
```

Expected outcome:

- No diff output, proving stable digest validation results across repeated runs.

## 8) Execute timed refresh run (under 30 minutes)

Measure one full refresh cycle from digest discovery to local verification completion.

```bash
start_ts=$(date +%s)
# perform digest refresh steps
./scripts/validate-base-image-digests.sh
end_ts=$(date +%s)
elapsed=$((end_ts - start_ts))
echo "timed refresh duration: ${elapsed} seconds"
test "${elapsed}" -lt 1800
```

Expected outcome:

- Timed refresh duration is under 1800 seconds (30 minutes).

## Evidence template (PR)

- Dockerfile -> old digest -> new digest
- Local validator output (text + JSON)
- CI workflow URL showing digest validation pass
- Reproducibility diff result (`no changes`)
- Timed refresh duration in seconds
