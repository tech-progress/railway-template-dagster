FROM python:3.12.15-slim-bookworm@sha256:54c85f3c47607a77f32adec749d3c81d1348bf25833671f512b26a9b6d778cb3

ENV DAGSTER_HOME=/opt/dagster/dagster_home \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /opt/dagster/app

COPY requirements.txt .
RUN pip install --no-cache-dir --requirement requirements.txt

COPY app ./app
COPY dagster.yaml workspace.yaml ./
COPY scripts/daemon_health.py scripts/database.sh scripts/start.sh ./scripts/
RUN chmod 0555 ./scripts/daemon_health.py ./scripts/start.sh \
    && mkdir -p "${DAGSTER_HOME}" \
    && cp dagster.yaml "${DAGSTER_HOME}/dagster.yaml"

EXPOSE 3000

CMD ["./scripts/start.sh", "webserver"]
