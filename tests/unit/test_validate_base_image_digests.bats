#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
}

@test "validator: reports JSON status with expected fields" {
  tmp_root="$(mktemp -d)"
  mkdir -p "${tmp_root}/docker"
  cat > "${tmp_root}/Dockerfile" <<'EOF'
FROM debian:bookworm-slim@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
EOF
  cat > "${tmp_root}/docker/Dockerfile" <<'EOF'
FROM debian:bookworm-slim@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
EOF
  cat > "${tmp_root}/docker/Dockerfile.ide" <<'EOF'
FROM gitpod/openvscode-server:1.96.4@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
EOF
  cat > "${tmp_root}/docker/memory.Dockerfile" <<'EOF'
FROM python:3.12-slim-bookworm@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
EOF

  run env DIGEST_VALIDATOR_ROOT="${tmp_root}" "${REPO_ROOT}/scripts/validate-base-image-digests.sh" --json
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'"status":"pass"'* ]]
  [[ "${output}" == *'"checked":'* ]]
  [[ "${output}" == *'"failures":[]'* ]]

  rm -rf "${tmp_root}"
}

@test "validator: fails when in-scope FROM references are unpinned" {
  tmp_root="$(mktemp -d)"
  mkdir -p "${tmp_root}/docker"
  cat > "${tmp_root}/Dockerfile" <<'EOF'
FROM debian:bookworm-slim
EOF
  cat > "${tmp_root}/docker/Dockerfile" <<'EOF'
FROM debian:bookworm-slim
EOF
  cat > "${tmp_root}/docker/Dockerfile.ide" <<'EOF'
FROM gitpod/openvscode-server:1.96.4
EOF
  cat > "${tmp_root}/docker/memory.Dockerfile" <<'EOF'
FROM python:3.12-slim-bookworm
EOF

  run env DIGEST_VALIDATOR_ROOT="${tmp_root}" "${REPO_ROOT}/scripts/validate-base-image-digests.sh" --json
  [ "${status}" -eq 1 ]
  [[ "${output}" == *'"status":"fail"'* ]]
  [[ "${output}" == *"unpinned base reference"* ]]

  rm -rf "${tmp_root}"
}

@test "validator: emits machine-readable failure details for scope coverage" {
  tmp_root="$(mktemp -d)"
  mkdir -p "${tmp_root}/docker"
  cat > "${tmp_root}/Dockerfile" <<'EOF'
FROM debian:bookworm-slim
EOF
  cat > "${tmp_root}/docker/Dockerfile" <<'EOF'
FROM debian:bookworm-slim
EOF
  cat > "${tmp_root}/docker/Dockerfile.ide" <<'EOF'
FROM gitpod/openvscode-server:1.96.4
EOF
  cat > "${tmp_root}/docker/memory.Dockerfile" <<'EOF'
FROM python:3.12-slim-bookworm
EOF

  run env DIGEST_VALIDATOR_ROOT="${tmp_root}" "${REPO_ROOT}/scripts/validate-base-image-digests.sh" --json
  [ "${status}" -eq 1 ]
  [[ "${output}" == *'"failures":['* ]]
  [[ "${output}" == *'Dockerfile: unpinned base reference'* ]]

  rm -rf "${tmp_root}"
}
