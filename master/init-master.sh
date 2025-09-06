#!/bin/bash
set -e

# Buat user khusus replication
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE repluser WITH REPLICATION LOGIN PASSWORD 'replpass';
EOSQL

# Tambahkan aturan ke pg_hba.conf
cat <<EOF >> "$PGDATA/pg_hba.conf"
host replication repluser 0.0.0.0/0 md5
host all all 0.0.0.0/0 md5
EOF

# Tambahkan konfigurasi ke postgresql.conf
cat <<EOF >> "$PGDATA/postgresql.conf"
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
EOF
