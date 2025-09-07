#!/bin/bash
set -e

echo "Setting up PostgreSQL replica..."

DATA_DIR=/var/lib/postgresql/data

# Function untuk menjalankan perintah sebagai postgres user
run_as_postgres() {
    su - postgres -c "$1"
}

# Function untuk menunggu master siap
wait_for_master() {
    echo "Waiting for master to be ready..."
    until run_as_postgres "PGPASSWORD=replpass pg_isready -h master -U repluser"; do
        echo "Master not ready yet, waiting..."
        sleep 2
    done
    echo "Master is ready!"
}

# Function untuk melakukan base backup
perform_base_backup() {
    echo "Performing base backup from master..."
    # Hapus direktori data jika sudah ada
    if [ -d "$DATA_DIR" ] && [ "$(ls -A $DATA_DIR)" ]; then
        echo "Cleaning existing data directory..."
        rm -rf $DATA_DIR/*
    fi
    
    # Lakukan base backup sebagai postgres user
    run_as_postgres "PGPASSWORD=replpass pg_basebackup -h master -D $DATA_DIR -U repluser -X stream -P -v"
    
    echo "Base backup completed!"
}

# Function untuk setup replica configuration
setup_replica_config() {
    echo "Setting up replica configuration..."
    
    # Buat standby.signal file
    touch $DATA_DIR/standby.signal
    
    # Buat atau update postgresql.auto.conf dengan koneksi ke primary
    cat > $DATA_DIR/postgresql.auto.conf <<EOF
# Replica configuration - managed by setup script
primary_conninfo = 'host=master port=5432 user=repluser password=replpass application_name=pg_replica'
primary_slot_name = 'replica_slot'
hot_standby = on
wal_receiver_timeout = '60s'
EOF

    # Set proper permissions
    chown -R postgres:postgres $DATA_DIR
    chmod 700 $DATA_DIR
    chmod 600 $DATA_DIR/postgresql.auto.conf
    
    echo "Replica configuration completed!"
}

# Main execution
wait_for_master
perform_base_backup
setup_replica_config

echo "Starting PostgreSQL server in replica mode..."
exec /usr/local/bin/docker-entrypoint.sh postgres
exec /usr/local/bin/docker-entrypoint.sh postgres
exec /usr/local/bin/docker-entrypoint.sh postgres
