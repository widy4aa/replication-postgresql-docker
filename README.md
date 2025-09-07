# replication-postgresql-docker
Simple Replication PostgreSQL Using Docker

## Deskripsi Proyek
Proyek ini bertujuan untuk membuat replikasi database PostgreSQL menggunakan Docker. Replikasi database adalah proses sinkronisasi data antara server utama (master) dan server cadangan (replica) untuk memastikan ketersediaan data yang tinggi dan toleransi kesalahan.

## Fitur
- Konfigurasi replikasi PostgreSQL dengan mudah menggunakan Docker Compose
- Menyediakan server master dan replica yang saling terhubung
- Data yang diubah di server master akan secara otomatis direplikasi ke server replica
- Script otomatis untuk memverifikasi status replikasi

## Prasyarat
Sebelum memulai, pastikan Anda telah menginstal:
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

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

## Struktur Proyek
- `docker-compose.yml`: File konfigurasi Docker Compose
- `master/`: Konfigurasi untuk node master
- `replica/`: Konfigurasi untuk node replica
- `clean.sh`: Skrip untuk membersihkan setup
- `testing.sh`: Skrip untuk menguji replikasi dengan data

## Catatan Penting
- Pastikan port 5434 dan 5435 tidak digunakan oleh layanan lain di komputer Anda
- Replica PostgreSQL berada dalam mode read-only. Write operations hanya dapat dilakukan di master
- Jika mengubah konfigurasi, jalankan `./clean.sh` sebelum memulai ulang
