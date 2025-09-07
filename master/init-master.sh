#!/bin/bash
set -e

echo "Setting up master node configuration..."

# Setup archive directory
mkdir -p /var/lib/postgresql/data/archive
chmod 700 /var/lib/postgresql/data/archive
chown postgres:postgres /var/lib/postgresql/data/archive

# Buat user khusus replication
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE repluser WITH REPLICATION LOGIN PASSWORD 'replpass';
EOSQL

# Coba buat replication slot
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    SELECT pg_create_physical_replication_slot('replica_slot', true) 
    WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'replica_slot');
EOSQL

# Tambahkan aturan ke pg_hba.conf
cat <<EOF >> "$PGDATA/pg_hba.conf"
# Allow replication connections
host    replication     repluser        0.0.0.0/0               md5
host    replication     repluser        ::/0                    md5
host    all             all             0.0.0.0/0               md5
host    all             all             ::/0                    md5
EOF

echo "Master PostgreSQL setup completed"
host    all             all             ::/0                    md5
EOF

echo "Master PostgreSQL setup completed"
cat <<EOF >> "$PGDATA/postgresql.conf"
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
archive_mode = on
archive_command = 'test ! -f /var/lib/postgresql/data/pgdata/archive/%f && cp %p /var/lib/postgresql/data/pgdata/archive/%f'
EOF

echo "Master PostgreSQL setup completed"
