# Changelog

All notable changes to the Dagster Railway template are recorded here. The template version is independent of the bundled Dagster version.

## [1.0.2] - 2026-10-02

- Upgrade Dagster and its webserver to 1.13.25, dagster-postgres to 0.29.25, and psycopg2-binary to 2.9.13.
- Refresh Python to 3.12.15 and local PostgreSQL to 17.11 while retaining Debian Bookworm and immutable image digests.
- Verify the coupled dependency pins and current runtime images without changing the service contract.
- Select the installed psycopg2 driver explicitly for PostgreSQL URLs, preserving startup with SQLAlchemy 2.1's changed default driver.

## [1.0.1] - 2026-07-28

- Hardened release verification so the changelog, public documentation, and Railway major release channel cannot drift from `VERSION`.
- Clarified which release commands run in the private monorepo and standalone public repository.

## [1.0.0] - 2026-07-28

- Published the initial three-service Dagster template with a public webserver, private daemon, and PostgreSQL.
- Established `release-v1` as the compatible Railway source channel.
