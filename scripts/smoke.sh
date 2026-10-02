#!/usr/bin/env bash
set -euo pipefail

base_url="${1:-http://127.0.0.1:3000}"
container="${DAGSTER_DAEMON_CONTAINER:-railway-dagster-template-daemon-1}"

curl --fail --silent --show-error "${base_url}/server_info" >/dev/null
curl --fail --silent --show-error "${base_url}/graphql" \
  --header "content-type: application/json" \
  --data '{"query":"query { version repositoriesOrError { __typename } }"}' |
  grep -q '"version"'

if [[ "${base_url}" == "http://127.0.0.1:3000" || -n "${DAGSTER_DAEMON_CONTAINER:-}" ]]; then
  exec_with_database() {
    docker exec "${container}" bash -c 'source ./scripts/database.sh; exec "$@"' bash "$@"
  }

  run_id="$(
    exec_with_database \
      python -c "import uuid; print(uuid.uuid4())"
  )"

  exec_with_database \
    dagster job launch \
    --workspace workspace.yaml \
    --location railway_starter \
    --job daily_metrics_job \
    --run-id "${run_id}"

  for attempt in $(seq 1 30); do
    status="$(
      exec_with_database \
        python -c \
          "import sys; from dagster import DagsterInstance; run = DagsterInstance.get().get_run_by_id(sys.argv[1]); print(run.status.value if run else 'MISSING')" \
          "${run_id}"
    )"

    if [[ "${status}" == "SUCCESS" ]]; then
      break
    fi

    if [[ "${status}" == "FAILURE" || "${status}" == "CANCELED" ]]; then
      echo "Queued Dagster run ${run_id} ended with ${status}" >&2
      exit 1
    fi

    if [[ "${attempt}" == "30" ]]; then
      echo "Queued Dagster run ${run_id} remained ${status}" >&2
      exit 1
    fi

    sleep 1
  done

  echo "Dagster webserver, GraphQL API, and queued sample job passed."
  exit 0
fi

echo "Dagster webserver and GraphQL API passed."
