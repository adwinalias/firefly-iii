#!/usr/bin/env bash
set -euo pipefail
umask 077

deploy_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_dir="${FIREFLY_BACKUP_DIR:-/var/backups/firefly-iii}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$backup_dir"
tmp_dir="$(mktemp -d "$backup_dir/.backup-${timestamp}-XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

cd "$deploy_dir"
docker compose exec -T db sh -c 'exec pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$tmp_dir/database.dump"
docker compose exec -T db pg_restore --list < "$tmp_dir/database.dump" > /dev/null
tar -C /var/lib/docker/volumes/firefly-iii-uploads/_data -czf "$tmp_dir/uploads.tar.gz" .
tar -C "$deploy_dir" -czf "$tmp_dir/config.tar.gz" compose.yaml .env
(cd "$tmp_dir" && sha256sum database.dump uploads.tar.gz config.tar.gz > SHA256SUMS)
archive="$backup_dir/firefly-iii-${timestamp}.tar.gz"
tar -C "$tmp_dir" -czf "$archive" .
tar -tzf "$archive" > /dev/null
chmod 600 "$archive"
find "$backup_dir" -maxdepth 1 -name 'firefly-iii-*.tar.gz' -mtime +13 -delete
printf '%s\n' "$archive"
