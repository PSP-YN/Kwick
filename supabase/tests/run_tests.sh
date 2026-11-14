#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="kwick_db_test_$$"
PORT=54329
PASSWORD="testpassword123"

echo "==> Starting isolated test PostgreSQL container ($CONTAINER_NAME)..."
docker run --rm -d \
    --name "$CONTAINER_NAME" \
    -e POSTGRES_PASSWORD="$PASSWORD" \
    -e POSTGRES_DB="postgres" \
    -v "$(pwd):/workspace" \
    -w /workspace \
    -p "$PORT:5432" \
    postgres:17-alpine > /dev/null

cleanup() {
    echo "==> Stopping test container..."
    docker stop "$CONTAINER_NAME" > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Waiting for PostgreSQL to be ready on port $PORT..."
for i in {1..30}; do
    if docker exec "$CONTAINER_NAME" pg_isready -U postgres -h 127.0.0.1 > /dev/null 2>&1; then
        break
    fi
    sleep 0.5
done

echo "==> Running database migrations and automated test suite..."
docker exec -i "$CONTAINER_NAME" psql -U postgres -h 127.0.0.1 -d postgres -f supabase/tests/database_test.sql

echo "==> Database test execution completed successfully!"
