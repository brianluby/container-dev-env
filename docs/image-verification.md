# Image Verification Guide

How to verify the integrity and provenance of `container-dev-env` images before pulling them into your environment.

## Prerequisites

Install [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) (v2+):

```bash
# macOS
brew install cosign

# Linux (pinned binary)
COSIGN_VERSION=v2.4.0
curl -L "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64" -o cosign
chmod +x cosign
sudo mv cosign /usr/local/bin/cosign
```

## Signature Verification

Verify that the image was built by the expected GitHub Actions workflow:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/.*/.github/workflows/container-build.yml@refs/heads/main" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<OWNER>/<REPO>:latest
```

Replace `<OWNER>/<REPO>` with your GitHub org/user and repository name (e.g. `myorg/container-dev-env`).

A successful result prints the verified signature payload as JSON. If verification fails, cosign exits with a non-zero status and prints an error describing the mismatch.

## SBOM Retrieval

Retrieve the SPDX SBOM attestation attached to the image:

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="https://github.com/.*/.github/workflows/container-build.yml@refs/heads/main" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<OWNER>/<REPO>:latest
```

This verifies the attestation signature and outputs the full SPDX JSON document wrapped in an in-toto statement.

## SBOM Inspection

### Extract the SBOM payload

The attestation output is an in-toto statement. Extract the SPDX content with `jq`:

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="https://github.com/.*/.github/workflows/container-build.yml@refs/heads/main" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/<OWNER>/<REPO>:latest \
  | jq -r '.payload' | base64 -d | jq '.predicate' > sbom.spdx.json
```

### List all packages

```bash
jq -r '.packages[].name' sbom.spdx.json | sort
```

### Count dpkg (Debian) packages

```bash
jq '[.packages[] | select(any(.externalRefs[]?; .referenceType == "purl" and ((.referenceLocator // "") | contains("pkg:deb/"))))] | length' sbom.spdx.json
```

### Check for specific components

```bash
# Node.js
jq '.packages[] | select(.name | test("node"; "i"))' sbom.spdx.json

# uv (Python package manager)
jq '.packages[] | select(.name == "uv")' sbom.spdx.json

# chezmoi
jq '.packages[] | select(.name == "chezmoi")' sbom.spdx.json
```

If a query returns an empty result, the component is not present in the SBOM.

## Trust Model

### Sigstore

[Sigstore](https://www.sigstore.dev/) is the open-source framework that underpins the entire signing and verification flow. It eliminates the need for long-lived signing keys by combining three services:

### Fulcio -- Certificate Authority

Fulcio issues short-lived X.509 certificates (valid for ~10 minutes) based on an OIDC identity token. In the GitHub Actions context, the token proves that a specific workflow in a specific repository triggered the build. Because the certificates expire almost immediately, there are no long-lived keys to manage, rotate, or revoke.

### Rekor -- Transparency Log

Every signing event is recorded in Rekor, a tamper-evident transparency log. This provides a public, auditable record that a particular artifact was signed at a particular time by a particular identity. Anyone can query Rekor to confirm that a signature exists and has not been altered.

### Why keyless signing is secure

Traditional image signing requires generating a key pair, storing the private key securely, and rotating it periodically. Keyless signing with Sigstore removes all of that:

- **No private key storage.** The ephemeral key exists only for the duration of the signing operation.
- **No key rotation.** Each build gets a fresh certificate; there is nothing to rotate.
- **Identity-based trust.** Verification checks _who_ signed (the GitHub Actions OIDC identity) rather than _which key_ was used.
- **Transparency log.** Rekor provides a tamper-proof audit trail independent of the signer.

### GitHub Actions OIDC

When a GitHub Actions workflow runs, GitHub's OIDC provider issues a token that encodes the repository, workflow file path, branch, and other context. Fulcio exchanges this token for a signing certificate, binding the image signature directly to the CI job that produced it. During verification, cosign checks that the certificate's identity fields match the expected workflow and issuer, confirming the image was built by the correct pipeline.
