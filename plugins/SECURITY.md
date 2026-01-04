# Potions Plugin Security Model

This document describes the security model for the Potions plugin system.

## Overview

Potions takes security seriously. Plugins can install software and modify configurations, so we implement multiple layers of protection.

## Security Principles

### 1. Verified Registry

Only plugins in the verified registry (`plugins/registry/verified.txt`) can be installed from remote sources. This ensures:

- Code has been reviewed by Potions maintainers
- No known malicious patterns
- Follows security best practices
- Checksums verified on download

### 2. Local Plugin Warning

Local plugins bypass verification but display a clear warning:

```
⚠️  WARNING: Installing local plugin
   Path: /path/to/plugin

   Local plugins are NOT verified by Potions Quality Assurance.
   Only install plugins from sources you trust.
```

### 3. Automatic Security Scanning

All plugins undergo security scanning for:

| Pattern | Severity | Description |
|---------|----------|-------------|
| `curl \| bash` | Critical | Remote code execution |
| `wget \| bash` | Critical | Remote code execution |
| `eval $var` | High | Code injection |
| `rm -rf /` | Critical | Dangerous deletion |
| `rm -rf $var` | High | Variable path deletion |
| `chmod 777` | Medium | World-writable permissions |
| `sudo rm` | Medium | Privileged deletion |
| Private keys | Critical | Credential exposure |
| API keys | High | Credential exposure |

### 4. Checksums

Critical files can have SHA256 checksums in the manifest for verification:

```json
{
  "checksums": {
    "install.sh": "sha256:abc123...",
    "packages/main.sh": "sha256:def456..."
  }
}
```

## Plugin Types

### Verified Remote Plugins

| Aspect | Status |
|--------|--------|
| Registry check | Required |
| Checksum verification | Yes |
| Security scan | Yes |
| Maintainer reviewed | Yes |

### Local Plugins

| Aspect | Status |
|--------|--------|
| Registry check | Skipped |
| Checksum verification | Skipped |
| Security scan | Optional |
| Warning displayed | Yes |

### Unverified Remote Plugins

| Aspect | Status |
|--------|--------|
| Installation | **REJECTED** |

## Security Scan Details

### Critical Patterns (Block Installation)

```bash
# Remote code execution
curl ... | bash
wget ... | sh
base64 -d ... | bash

# Filesystem destruction
rm -rf /
rm -rf /*
mkfs.*
> /dev/sd*

# Code injection with fork bomb
:(){:|:&};:
```

### High Risk Patterns (Warning)

```bash
# Eval with variables
eval "$user_input"
eval "$(some_command)"

# Variable path operations
rm -rf "$untrusted_path"

# Direct disk access
dd if=...
```

### Medium Risk Patterns (Note)

```bash
# Privilege escalation
sudo rm ...
sudo chmod ...
sudo chown ...

# Permissions
chmod 777 ...
chmod -R 777 ...
```

### Sensitive Data Patterns

```bash
# Credentials (case-insensitive)
password=...
api_key=...
secret=...
token=...

# Private keys
BEGIN RSA PRIVATE KEY
BEGIN PRIVATE KEY
AWS_ACCESS_KEY
AWS_SECRET
```

## Running Security Audits

### Quick Scan

```bash
./plugins.sh verify my-plugin
```

### Full Audit

```bash
# From plugins/core/scanner.sh
security_audit /path/to/plugin
```

### Manual Verification

```bash
# Check for critical patterns
grep -rE 'curl.*\|.*bash' plugin/
grep -rE 'eval.*\$' plugin/
grep -rE 'rm -rf /' plugin/
```

## Registry Verification Process

To add a plugin to the verified registry:

1. **Submission**: Plugin author submits PR
2. **Automated Checks**: CI runs validation and security scans
3. **Manual Review**: Maintainer reviews all code
4. **Verification Script**: Maintainer runs:
   ```bash
   ./plugins/registry/verify_submission.sh owner/repo
   ```
5. **Registry Update**: If approved, add to `verified.txt`
6. **Checksum Generation**: CI regenerates checksums

## Best Practices for Plugin Authors

### DO

- Quote all variables: `"$var"` not `$var`
- Use `set -eo pipefail` in scripts
- Validate all inputs
- Use platform detection functions
- Clean up temporary files
- Preserve user customizations
- Document sudo usage

### DON'T

- Use `eval` with external input
- Pipe untrusted data to shell
- Hardcode credentials or paths
- Use `rm -rf` with variable paths without validation
- Request unnecessary sudo access
- Overwrite user files without backup

## Reporting Security Issues

If you find a security vulnerability:

1. **Do NOT** open a public issue
2. Email security concerns to the maintainers
3. Include detailed steps to reproduce
4. Allow time for a fix before disclosure

## Security Checklist

Before installing a plugin:

- [ ] Is it from the verified registry?
- [ ] If local, do you trust the source?
- [ ] Have you reviewed the install.sh?
- [ ] Does it request unusual permissions?
- [ ] Are there any security scan warnings?

Before publishing a plugin:

- [ ] Run `./plugins.sh verify your-plugin`
- [ ] Run `./plugins.sh validate your-plugin`
- [ ] Check all variables are quoted
- [ ] Remove any hardcoded credentials
- [ ] Minimize sudo usage
- [ ] Document any required permissions
