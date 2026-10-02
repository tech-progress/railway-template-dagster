case "${DATABASE_URL:-}" in
  postgres://*) export DATABASE_URL="postgresql+psycopg2://${DATABASE_URL#postgres://}" ;;
  postgresql://*) export DATABASE_URL="postgresql+psycopg2://${DATABASE_URL#postgresql://}" ;;
esac
