# replication-postgresql-docker
Simple Replication Postgresql Using Docker

## Deskripsi Proyek
Proyek ini bertujuan untuk membuat replikasi database PostgreSQL menggunakan Docker. Replikasi database adalah proses sinkronisasi data antara server utama (primary) dan server cadangan (replica) untuk memastikan ketersediaan data yang tinggi dan toleransi kesalahan.

## Fitur
- Konfigurasi replikasi PostgreSQL dengan mudah menggunakan Docker Compose.
- Menyediakan server primary dan replica yang saling terhubung.
- Data yang diubah di server primary akan secara otomatis direplikasi ke server replica.

## Prasyarat
Sebelum memulai, pastikan Anda telah menginstal:
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

## Cara Menggunakan
1. Clone repositori ini ke komputer Anda:
   ```bash
   git clone https://github.com/username/replication-postgresql-docker.git
   cd replication-postgresql-docker
   ```

2. Jalankan Docker Compose untuk memulai layanan:
   ```bash
   docker-compose up -d
   ```

3. Verifikasi bahwa container telah berjalan:
   ```bash
   docker ps
   ```

4. Masuk ke container PostgreSQL primary:
   ```bash
   docker exec -it primary-container-name psql -U postgres
   ```

5. Masuk ke container PostgreSQL replica untuk memverifikasi replikasi:
   ```bash
   docker exec -it replica-container-name psql -U postgres
   ```

## Struktur Proyek
- `docker-compose.yml`: File konfigurasi Docker Compose untuk mengatur container primary dan replica.
- `primary`: Direktori yang berisi konfigurasi untuk server primary.
- `replica`: Direktori yang berisi konfigurasi untuk server replica.

## Catatan
- Pastikan Anda mengganti `primary-container-name` dan `replica-container-name` dengan nama container yang sesuai di file `docker-compose.yml`.
- Jika terjadi masalah, periksa log container menggunakan perintah:
  ```bash
  docker logs <container-name>
  ```
