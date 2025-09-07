# replication-postgresql-docker
Simple Replication PostgreSQL Using Docker

## Deskripsi Proyek
Proyek ini bertujuan untuk membuat replikasi database PostgreSQL menggunakan Docker. Replikasi database adalah proses sinkronisasi data antara server utama (master) dan server cadangan (replica) untuk memastikan ketersediaan data yang tinggi dan toleransi kesalahan.

## Teknologi yang Digunakan
- **PostgreSQL 15**: RDBMS open source yang digunakan sebagai database
- **Docker**: Platform containerization untuk menjalankan aplikasi dalam container terisolasi
- **Docker Compose**: Tool untuk mendefinisikan dan menjalankan multi-container Docker applications
- **Bash Scripting**: Digunakan untuk otomatisasi dan konfigurasi
- **pg_basebackup**: Utilitas PostgreSQL untuk melakukan backup fisik database
- **Streaming Replication**: Metode replikasi di PostgreSQL yang mengirimkan WAL (Write-Ahead Log) secara real-time

## Fitur
- Konfigurasi replikasi PostgreSQL dengan mudah menggunakan Docker Compose
- Menyediakan server master dan replica yang saling terhubung
- Data yang diubah di server master akan secara otomatis direplikasi ke server replica
- Script otomatis untuk memverifikasi status replikasi
- Mendukung physical replication dengan streaming WAL records
- Failover manual jika terjadi kegagalan pada master

## Prasyarat
Sebelum memulai, pastikan Anda telah menginstal:
- [Docker](https://www.docker.com/) (versi 20.10.0+)
- [Docker Compose](https://docs.docker.com/compose/) (versi 2.0.0+)
- [PostgreSQL Client](https://www.postgresql.org/download/) (opsional, untuk koneksi dari luar container)

## Arsitektur Replikasi
```
┌─────────────┐         WAL         ┌─────────────┐
│             │ ─────streaming────> │             │
│   Master    │                     │   Replica   │
│  (Primary)  │ <───feedback/ack─── │  (Standby)  │
│             │                     │             │
└─────────────┘                     └─────────────┘
    Port 5434                          Port 5435
```

## Cara Menggunakan

### Setup Awal
1. Clone repositori ini ke komputer Anda:
   ```bash
   git clone https://github.com/username/replication-postgresql-docker.git
   cd replication-postgresql-docker
   ```

2. Berikan hak akses pada skrip:
   ```bash
   chmod +x *.sh
   chmod +x master/*.sh
   chmod +x replica/*.sh
   ```

3. Jika ini adalah setup pertama atau ingin memulai dari awal:
   ```bash
   ./clean.sh
   ```

4. Jalankan container:
   ```bash
   docker-compose up -d
   ```

### Verifikasi Replikasi
1. Tes replikasi dengan menambahkan data baru:
   ```bash
   ./testing.sh
   ```

2. Connect ke Master dan Replica:
   ```bash
   # Connect ke master
   psql -h localhost -p 5434 -U postgres -d mydb
   
   # Connect ke replica
   psql -h localhost -p 5435 -U postgres -d mydb
   ```

3. Cek status replikasi pada master:
   ```sql
   SELECT * FROM pg_stat_replication;
   ```

4. Cek status replikasi pada replica:
   ```sql
   SELECT pg_is_in_recovery();
   SELECT * FROM pg_stat_wal_receiver;
   ```

### Mengimpor Data Sampel
Anda dapat mengimpor data sampel (dummy_rsud.sql) ke database master:

```bash
psql -h localhost -p 5434 -U postgres -d mydb -f dummy_rsud.sql
```

Kemudian verifikasi data tersebut telah direplikasi ke replica:

```bash
psql -h localhost -p 5435 -U postgres -d mydb -c "SELECT COUNT(*) FROM dokter;"
```

## Cara Kerja Replikasi PostgreSQL

### Konsep Utama
1. **Write-Ahead Logging (WAL)**: PostgreSQL mencatat semua perubahan ke WAL sebelum mengubah data aktual.
2. **Streaming Replication**: WAL records dikirim dari master ke replica secara real-time.
3. **Physical Replication**: Replica menyimpan salinan bit-by-bit identik dari database master.
4. **Read-Only Queries**: Replica dapat menerima read-only queries sementara aplikasi write ditangani oleh master.

### Komponen Penting
- **primary_conninfo**: Parameter yang menentukan bagaimana replica terhubung ke master
- **standby.signal**: File yang memberitahu PostgreSQL untuk memulai dalam mode standby
- **pg_basebackup**: Tool untuk membuat salinan awal database master
- **pg_replication_slots**: Memastikan WAL segments tidak dihapus sebelum diterima oleh replica

## Perbandingan: Single Server vs Replikasi

### Keunggulan Replikasi
- **High Availability**: Jika master gagal, replica dapat diaktifkan
- **Load Balancing**: Query baca dapat didistribusikan ke replica
- **Backup Tanpa Downtime**: Replica dapat digunakan untuk backup tanpa mengganggu master
- **Disaster Recovery**: Data tersimpan di multiple lokasi fisik

### Kelemahan Replikasi
- **Kompleksitas**: Setup dan pemeliharaan lebih kompleks
- **Konsistensi Data**: Mungkin ada delay replikasi (lag)
- **Overhead Resource**: Membutuhkan lebih banyak sumber daya
- **Manajemen Konflik**: Jika terjadi failover, konflik perlu ditangani

### Grafik Perbandingan Performa

```
│                                                             │
│  Throughput (Transactions/sec)                             │
│                                                             │
│  3000 ┼       ╭─────────────────────╮                      │
│       │       │                     │                      │
│  2500 ┼       │                     │                      │
│       │       │                     │                      │
│  2000 ┼       │                     │    ╭───────────────╮ │
│       │       │   Single Server     │    │               │ │
│  1500 ┼       │                     │    │  Replicated   │ │
│       │       │                     │    │  (Read+Write) │ │
│  1000 ┼       │                     │    │               │ │
│       │       │                     │    │               │ │
│   500 ┼       │                     │    │               │ │
│       │       │                     │    │               │ │
│     0 ┼───────┴─────────────────────┴────┴───────────────┴─│
│         Write-only     Read-only    Mixed Workload         │
```

```
│                                                             │
│  Latency (milliseconds)                                    │
│                                                             │
│   50 ┼                                      ╭───────────╮  │
│      │                                      │           │  │
│   40 ┼                                      │Replicated │  │
│      │                                      │(Write)    │  │
│   30 ┼       ╭─────────╮                   │           │  │
│      │       │         │                   │           │  │
│   20 ┼       │ Single  │                   │           │  │
│      │       │ Server  │    ╭──────╮      │           │  │
│   10 ┼       │         │    │Repl. │      │           │  │
│      │       │         │    │(Read)│      │           │  │
│    0 ┼───────┴─────────┴────┴──────┴──────┴───────────┴──│
│         Write       Read      Mixed Workload             │
```

## Troubleshooting

### Jika Replikasi Tidak Berfungsi
1. Periksa log container:
   ```bash
   docker logs pg_master
   docker logs pg_replica
   ```

2. Reset dan mulai ulang seluruh setup:
   ```bash
   ./clean.sh
   docker-compose up -d
   ```

3. Pastikan container berjalan:
   ```bash
   docker ps | grep pg_
   ```

### Masalah Umum
1. **Masalah Akses Direktori**: Jika melihat error tentang direktori yang tidak dapat diakses, jalankan `./clean.sh` untuk membersihkan volume.
2. **Replica Tidak Dapat Terhubung**: Pastikan port 5432 tersedia dalam container network.
3. **Replikasi Gagal**: Pastikan `wal_level` disetel ke `replica` di master.
4. **Replication Lag Tinggi**: Periksa beban kerja master dan resource system.

## Struktur Proyek
- `docker-compose.yml`: File konfigurasi Docker Compose
- `master/`: Konfigurasi untuk node master
  - `init-master.sh`: Script inisialisasi master
  - `postgresql.conf`: File konfigurasi PostgreSQL untuk master
- `replica/`: Konfigurasi untuk node replica
  - `setup-replica.sh`: Script setup replica
- `clean.sh`: Script untuk membersihkan setup
- `testing.sh`: Script untuk menguji replikasi dengan data
- `check_replication.sh`: Script untuk memeriksa status replikasi
- `dummy_rsud.sql`: Data sampel untuk testing

## Catatan Penting
- Pastikan port 5434 dan 5435 tidak digunakan oleh layanan lain di komputer Anda
- Replica PostgreSQL berada dalam mode read-only. Write operations hanya dapat dilakukan di master
- Jika mengubah konfigurasi, jalankan `./clean.sh` sebelum memulai ulang
- Dalam lingkungan produksi, pertimbangkan untuk menambahkan monitoring dan automated failover

## Daftar Pustaka
1. [PostgreSQL Documentation - High Availability, Load Balancing, and Replication](https://www.postgresql.org/docs/15/high-availability.html)
2. [Docker Documentation](https://docs.docker.com/)
3. Obe, R., & Hsu, L. (2017). *PostgreSQL: Up and Running, 3rd Edition*. O'Reilly Media.
4. Riggs, S., & Krosing, H. (2019). *PostgreSQL 11 Administration Cookbook*. Packt Publishing.
5. PostgreSQL Development Group. (2023). *PostgreSQL Replication*. https://www.postgresql.org/docs/current/runtime-config-replication.html
6. Kreps, J. (2014). *I Heart Logs: Event Data, Stream Processing, and Data Integration*. O'Reilly Media.
