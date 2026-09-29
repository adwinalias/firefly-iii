# Hostinger deployment

This directory deploys the official Firefly III 6.7.6 image and PostgreSQL 17.11 on the Hostinger VPS. Traefik is the existing, separate reverse proxy. The only public route is `finance.adwinalias.com`; the app's host port binds to loopback and the database has no host port. The Firefly services share an internal Docker network with no default outbound internet route. The daily Firefly scheduler uses 23:00 UTC, which is 03:00 in Dubai.

## Install

1. Create an `A` record for `finance.adwinalias.com` pointing to the VPS.
2. Copy this directory to `/opt/firefly-iii` on the VPS. Copy `.env.example` to `.env`, replace the owner email and all three secret placeholders with unique generated values, then `chmod 600 .env`.
3. Run `docker compose config --quiet` and `docker compose up -d` from `/opt/firefly-iii`.
4. Wait for HTTPS and create the two intended user accounts. Firefly III's admin setting **Single user mode** should then be enabled, which closes public registration while preserving the existing accounts.
5. Install `backup.cron` as `/etc/cron.d/firefly-iii-backup` (mode `644`), then restart the host cron service. Hostinger's separate weekly VPS backups provide the off-VPS copy; check that they continue to run.

## Backups and restore

`backup.sh` writes a dated root-only archive in `/var/backups/firefly-iii` containing a PostgreSQL custom-format dump, uploads, Compose configuration, `.env`, and checksums. It keeps 14 days of local archives. Hostinger's weekly VPS backup is held separately from the server. A current archive should also be copied off the VPS before major changes.

To restore an archive on a clean VPS, extract it privately, verify `sha256sum -c SHA256SUMS`, restore `config.tar.gz` to `/opt/firefly-iii`, start only the database with `docker compose up -d db`, then run `pg_restore --clean --if-exists --no-owner -U firefly -d firefly` inside the database container using `database.dump` as input. Restore `uploads.tar.gz` into the `firefly-iii-uploads` volume and start the app and cron with `docker compose up -d`. Do not put backup archives or `.env` in Git.
