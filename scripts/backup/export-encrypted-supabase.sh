#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKUP_DIR="${KWICK_BACKUP_DIR:-$HOME/.local/share/kwick-backups}"
RETENTION_DAYS="${KWICK_BACKUP_RETENTION_DAYS:-30}"
RCLONE_DEST="${KWICK_BACKUP_RCLONE_DEST:-}"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI is required." >&2
  exit 1
fi
if ! command -v gpg >/dev/null 2>&1; then
  echo "GPG is required." >&2
  exit 1
fi

umask 077
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ -n "${KWICK_BACKUP_PASSPHRASE_FILE:-}" ]]; then
  PASS_FILE="$KWICK_BACKUP_PASSPHRASE_FILE"
  test -s "$PASS_FILE"
elif command -v secret-tool >/dev/null 2>&1; then
  secret-tool lookup service kwick-backup account database-backup > "$TMP/passphrase"
  chmod 600 "$TMP/passphrase"
  PASS_FILE="$TMP/passphrase"
else
  echo "Set KWICK_BACKUP_PASSPHRASE_FILE or install/unlock GNOME Secret Service." >&2
  exit 1
fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$BACKUP_DIR/kwick-db-$STAMP.tar.gz.gpg"

cd "$ROOT"
supabase db dump --linked --schema public,storage --file "$TMP/schema.sql"
supabase db dump --linked --data-only --schema public,storage --file "$TMP/data.sql"

cat > "$TMP/manifest.txt" <<EOF
Kwick Supabase logical backup
Created UTC: $STAMP
Project ref: hpfzhovriwpivtotoyxw
Includes: public and storage schema definitions; public and storage database rows.
Excludes: auth.users credentials/sessions; binary Storage object payloads; Supabase project settings and secrets.
Storage binary objects must be exported separately before this can be treated as a complete application backup.
Restore into an isolated project first. Never test restore over production.
Encryption: GPG AES-256 symmetric.
EOF

tar -czf "$TMP/kwick-db-$STAMP.tar.gz" -C "$TMP" schema.sql data.sql manifest.txt
gpg --batch --yes --pinentry-mode loopback --passphrase-file "$PASS_FILE" \
  --symmetric --cipher-algo AES256 --output "$OUT" "$TMP/kwick-db-$STAMP.tar.gz"
chmod 600 "$OUT"

gpg --batch --pinentry-mode loopback --passphrase-file "$PASS_FILE" --decrypt "$OUT" \
  | tar -tzf - > "$TMP/verified-files.txt"
grep -qx 'schema.sql' "$TMP/verified-files.txt"
grep -qx 'data.sql' "$TMP/verified-files.txt"
grep -qx 'manifest.txt' "$TMP/verified-files.txt"

sha256sum "$OUT"
echo "Encrypted backup verified: $OUT"

if [[ -n "$RCLONE_DEST" ]]; then
  if ! command -v rclone >/dev/null 2>&1; then
    echo "KWICK_BACKUP_RCLONE_DEST is set but rclone is unavailable." >&2
    exit 1
  fi
  rclone copy "$OUT" "$RCLONE_DEST" --immutable
  echo "Encrypted backup copied to configured off-site destination."
else
  echo "WARNING: no off-site destination configured; this copy remains local."
fi

find "$BACKUP_DIR" -type f -name 'kwick-db-*.tar.gz.gpg' -mtime +"$RETENTION_DAYS" -delete
