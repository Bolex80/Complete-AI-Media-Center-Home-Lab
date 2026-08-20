#!/usr/bin/env bash
# Pre-commit secret scanner for the Complete-AI-Media-Center-Home-Lab repo.
# Blocks commits that contain likely secrets (passwords, API keys, tokens,
# private keys). Install with:  cp scripts/secret-scan.sh .git/hooks/pre-commit
set -euo pipefail

# Patterns that indicate a real secret (not a placeholder).
# Each is a grep -E pattern. Keep them tight to avoid false positives.
SECRET_PATTERNS=(
  # Hardcoded passwords in ConvertTo-SecureString / PSCredential
  'ConvertTo-SecureString[[:space:]]+"[^"]+"'
  # Common password assignments with a real-looking value
  '(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9@#!$%^&*._-]{8,}'
  # API keys / tokens
  '(api[_-]?key|secret|token)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9_-]{16,}'
  # AWS access keys
  'AKIA[0-9A-Z]{16}'
  # GitHub tokens
  'gh[pousr]_[A-Za-z0-9]{20,}'
  # Slack tokens
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  # Private key headers
  'BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY'
  # OpenAI-style keys
  'sk-[A-Za-z0-9]{20,}'
)

# Values that are clearly placeholders / examples and should be allowed.
ALLOWLIST=(
  'changeme'
  'your_'
  'YOUR_'
  'placeholder'
  'example'
  'os.environ/'
  'ssh-keyobtained at installation goes here'
  'REDACTED'
  'see Vaultwarden'
  'password manager'
  'password vault'
  'pass\.benthem'
  'vaultwarden'
  'passwordless'
  'password-protected'
  'password field'
  'password for'
  'your_password'
  'your_secure'
  'admin_password'
  'db_password'
  'db_root_password'
  'eurooffice_jwt'
  'jwt_secret'
  'JWT_SECRET'
  'MYSQL_.*_PASSWORD_FILE'
  '/run/secrets/'
  'secrets/.*\.txt'
  '\.env\.example'
  'API_KEY=\$\{'
  'PASSWORD=\$\{'
)

# Files to scan (everything staged, text only).
staged=$(git diff --cached --name-only --diff-filter=ACM)
if [[ -z "$staged" ]]; then
  exit 0
fi

violations=0
while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  # Skip binary files
  if file "$file" | grep -qiE 'binary|image|archive'; then
    continue
  fi
  # Skip the hook itself and .gitignore
  case "$file" in
    .git/hooks/*|scripts/secret-scan.sh|.gitignore) continue ;;
  esac

  for pat in "${SECRET_PATTERNS[@]}"; do
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # Skip allowlisted lines
      skip=0
      for allow in "${ALLOWLIST[@]}"; do
        if grep -qiE "$allow" <<< "$line"; then
          skip=1
          break
        fi
      done
      [[ $skip -eq 1 ]] && continue
      echo "⚠️  Possible secret in $file:"
      echo "    $line"
      violations=$((violations+1))
    done < <(grep -nE "$pat" "$file" 2>/dev/null || true)
  done
done <<< "$staged"

if [[ $violations -gt 0 ]]; then
  echo ""
  echo "❌ Commit blocked: $violations potential secret(s) found."
  echo "   Remove the secret, use an env var / password manager reference,"
  echo "   or add an explicit allowlist entry to scripts/secret-scan.sh."
  exit 1
fi

exit 0
