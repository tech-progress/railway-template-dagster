#!/usr/bin/env bash
set -euo pipefail

template_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  ".dockerignore"
  ".env.example"
  ".railway/railway.ts"
  "CHANGELOG.md"
  "Dockerfile"
  "MARKETPLACE.md"
  "PUBLISHING.md"
  "README.md"
  "SUPPORT.md"
  "UPGRADE.md"
  "VERSION"
  "app/definitions.py"
  "compose.yaml"
  "dagster.yaml"
  "requirements.txt"
  "scripts/audit-template.sh"
  "scripts/daemon_health.py"
  "scripts/database.sh"
  "scripts/remote-smoke.sh"
  "scripts/smoke.sh"
  "scripts/start.sh"
  "template-defaults.json"
  "tests/test_daemon_health.py"
  "tests/test_definitions.py"
  "tests/test_start.py"
  "workspace.yaml"
)

for file in "${required_files[@]}"; do
  test -f "${template_root}/${file}" || {
    echo "Missing required file: ${file}" >&2
    exit 1
  }
done

template_version="$(<"${template_root}/VERSION")"
semver_pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
if [[ ! "${template_version}" =~ ${semver_pattern} ]]; then
  echo "VERSION must contain one stable MAJOR.MINOR.PATCH version." >&2
  exit 1
fi
escaped_version="${template_version//./\\.}"
grep -Eq "^## \\[${escaped_version}\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" \
  "${template_root}/CHANGELOG.md" || {
  echo "CHANGELOG.md has no entry for ${template_version}." >&2
  exit 1
}
for file in README.md PUBLISHING.md; do
  grep -Fq "current template release is \`v${template_version}\`" \
    "${template_root}/${file}" || {
    echo "${file} does not identify the current template release." >&2
    exit 1
  }
done
template_major="${template_version%%.*}"
grep -Fq "branch: \"release-v${template_major}\"" \
  "${template_root}/.railway/railway.ts" || {
  echo ".railway/railway.ts does not use the VERSION major release channel." >&2
  exit 1
}
for file in README.md MARKETPLACE.md PUBLISHING.md; do
  grep -Fq "\`release-v${template_major}\`" "${template_root}/${file}" || {
    echo "${file} does not identify the VERSION major release channel." >&2
    exit 1
  }
done

if find "${template_root}" -type f \( -name ".env" -o -name "*.local" \) -print -quit | grep -q .; then
  echo "Local secret file found in the template directory" >&2
  exit 1
fi

docker compose -f "${template_root}/compose.yaml" config --quiet
jq empty "${template_root}/template-defaults.json"
bash -n \
  "${template_root}/scripts/audit-template.sh" \
  "${template_root}/scripts/database.sh" \
  "${template_root}/scripts/remote-smoke.sh" \
  "${template_root}/scripts/smoke.sh" \
  "${template_root}/scripts/start.sh"
python3 -c \
  "compile(open('${template_root}/scripts/daemon_health.py', encoding='utf-8').read(), 'scripts/daemon_health.py', 'exec')"
(cd "${template_root}" && python3 -m unittest discover -s tests -p test_start.py)

grep -Fq "dagster==1.13.25" "${template_root}/requirements.txt"
grep -Fxq "dagster-webserver==1.13.25" "${template_root}/requirements.txt"
grep -Fxq "dagster-postgres==0.29.25" "${template_root}/requirements.txt"
grep -Fxq "psycopg2-binary==2.9.13" "${template_root}/requirements.txt"
grep -Fq "python:3.12.15-slim-bookworm@sha256:54c85f3c47607a77f32adec749d3c81d1348bf25833671f512b26a9b6d778cb3" "${template_root}/Dockerfile"
grep -Fq "postgres:17.11-bookworm@sha256:639ab7ceb90e13123085b741fb31ef493fba25463002f6da665352e7b534b652" "${template_root}/compose.yaml"
grep -Fq "max_concurrent_runs: 1" "${template_root}/dagster.yaml"
grep -Fq "class: DefaultRunLauncher" "${template_root}/dagster.yaml"

if grep -Rqs "/var/run/docker.sock\\|DockerRunLauncher" \
  "${template_root}/.railway" \
  "${template_root}/app" \
  "${template_root}/compose.yaml" \
  "${template_root}/dagster.yaml" \
  "${template_root}/Dockerfile" \
  "${template_root}/scripts/start.sh"; then
  echo "The template must not require a Docker socket or DockerRunLauncher" >&2
  exit 1
fi

echo "Dagster template structure and Compose configuration are valid."
