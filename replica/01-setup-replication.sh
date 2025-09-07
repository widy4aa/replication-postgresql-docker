#!/bin/bash
set -e

# Tunggu hingga master siap
until PGPASSWORD=replpass pg_isready -h master -U repluser; do
  echo "Waiting for master to be ready..."
  sleep 2
done

# Hapus data lama dan lakukan base backup
rm -rf /var/lib/postgresql/data/*
PGPASSWORD=replpass pg_basebackup -h master -D /var/lib/postgresql/data -U repluser -Fp -Xs -P

# Buat file standby.signal untuk mengaktifkan mode standby
touch /var/lib/postgresql/data/standby.signal

# Tambahkan konfigurasi koneksi ke primary di postgresql.auto.conf
cat > /var/lib/postgresql/data/postgresql.auto.conf <<EOF
# Konfigurasi replikasi
primary_conninfo = 'host=master port=5432 user=repluser password=replpass application_name=pg_replica'
restore_command = ''
hot_standby = on
EOF

# Pastikan kepemilikan file benar
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data