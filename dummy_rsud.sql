

-- =============================================
-- TABEL DOKTER 
-- =============================================
CREATE TABLE dokter (
    id_dokter SERIAL PRIMARY KEY,
    nip VARCHAR(20) UNIQUE NOT NULL,
    nama VARCHAR(100) NOT NULL,
    spesialisasi VARCHAR(50) NOT NULL,
    no_telepon VARCHAR(15),
    email VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Aktif' CHECK (status IN ('Aktif', 'Tidak Aktif')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABEL POLIKLINIK 
-- =============================================
CREATE TABLE poliklinik (
    id_poli SERIAL PRIMARY KEY,
    kode_poli VARCHAR(10) UNIQUE NOT NULL,
    nama_poli VARCHAR(50) NOT NULL,
    lokasi VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABEL TINDAKAN MEDIS 
-- =============================================
CREATE TABLE tindakan_medis (
    id_tindakan SERIAL PRIMARY KEY,
    kode_tindakan VARCHAR(10) UNIQUE NOT NULL,
    nama_tindakan VARCHAR(200) NOT NULL,
    tarif NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABEL PASIEN 
-- =============================================
CREATE TABLE pasien (
    id_pasien SERIAL,
    no_rm VARCHAR(20) NOT NULL,
    nik VARCHAR(16) NOT NULL,
    nama VARCHAR(100) NOT NULL,
    tempat_lahir VARCHAR(50) NOT NULL,
    tanggal_lahir DATE NOT NULL,
    jenis_kelamin VARCHAR(10) CHECK (jenis_kelamin IN ('Laki-laki', 'Perempuan')),
    alamat TEXT,
    no_telepon VARCHAR(15),
    golongan_darah VARCHAR(3),
    alergi TEXT,
    status VARCHAR(20) DEFAULT 'Aktif' CHECK (status IN ('Aktif', 'Nonaktif', 'Meninggal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_pasien, status)
) PARTITION BY LIST (status);

-- Partisi untuk pasien aktif
CREATE TABLE pasien_aktif PARTITION OF pasien
    FOR VALUES IN ('Aktif');

-- Partisi untuk pasien nonaktif
CREATE TABLE pasien_nonaktif PARTITION OF pasien
    FOR VALUES IN ('Nonaktif');

-- Partisi untuk pasien meninggal
CREATE TABLE pasien_meninggal PARTITION OF pasien
    FOR VALUES IN ('Meninggal');

-- =============================================
-- TABEL KUNJUNGAN 
-- =============================================
CREATE TABLE kunjungan (
    id_kunjungan SERIAL,
    id_pasien INTEGER NOT NULL,
    id_dokter INTEGER NOT NULL,
    id_poli INTEGER NOT NULL,
    no_registrasi VARCHAR(20) NOT NULL,
    tgl_kunjungan DATE NOT NULL,
    keluhan_utama TEXT,
    tinggi_badan INTEGER,
    berat_badan INTEGER,
    tekanan_darah VARCHAR(10),
    suhu_badan DECIMAL(4,1),
    status VARCHAR(20) DEFAULT 'Proses' CHECK (status IN ('Proses', 'Selesai', 'Batal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_kunjungan, tgl_kunjungan)
) PARTITION BY RANGE (tgl_kunjungan);

-- Partisi untuk tahun 2023
CREATE TABLE kunjungan_2023 PARTITION OF kunjungan
    FOR VALUES FROM ('2023-01-01') TO ('2023-12-31');

-- Partisi untuk tahun 2024
CREATE TABLE kunjungan_2024 PARTITION OF kunjungan
    FOR VALUES FROM ('2024-01-01') TO ('2024-12-31');

-- Partisi untuk tahun 2025
CREATE TABLE kunjungan_2025 PARTITION OF kunjungan
    FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');

-- =============================================
-- TABEL DIAGNOSIS 
-- =============================================
CREATE TABLE diagnosis (
    id_diagnosis SERIAL,
    id_kunjungan INTEGER NOT NULL,
    kode_icd VARCHAR(10),
    nama_diagnosis VARCHAR(200) NOT NULL,
    jenis_diagnosis VARCHAR(20) CHECK (jenis_diagnosis IN ('Primer', 'Sekunder')),
    catatan_dokter TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_diagnosis, created_at)
) PARTITION BY RANGE (created_at);

-- Partisi untuk tahun 2023
CREATE TABLE diagnosis_2023 PARTITION OF diagnosis
    FOR VALUES FROM ('2023-01-01') TO ('2023-12-31');

-- Partisi untuk tahun 2024
CREATE TABLE diagnosis_2024 PARTITION OF diagnosis
    FOR VALUES FROM ('2024-01-01') TO ('2024-12-31');

-- Partisi untuk tahun 2025
CREATE TABLE diagnosis_2025 PARTITION OF diagnosis
    FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');

-- =============================================
-- TABEL TINDAKAN 
-- =============================================
CREATE TABLE tindakan (
    id_tindakan SERIAL,
    id_kunjungan INTEGER NOT NULL,
    kode_tindakan VARCHAR(10) NOT NULL,
    nama_tindakan VARCHAR(200) NOT NULL,
    hasil_tindakan TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_tindakan, created_at)
) PARTITION BY RANGE (created_at);

-- Partisi untuk tahun 2023
CREATE TABLE tindakan_2023 PARTITION OF tindakan
    FOR VALUES FROM ('2023-01-01') TO ('2023-12-31');

-- Partisi untuk tahun 2024
CREATE TABLE tindakan_2024 PARTITION OF tindakan
    FOR VALUES FROM ('2024-01-01') TO ('2024-12-31');

-- Partisi untuk tahun 2025
CREATE TABLE tindakan_2025 PARTITION OF tindakan
    FOR VALUES FROM ('2025-01-01') TO ('2025-12-31');

-- =============================================
-- TABEL RESEP OBAT 
-- =============================================
CREATE TABLE resep_obat (
    id_resep SERIAL,
    id_kunjungan INTEGER NOT NULL,
    nama_obat VARCHAR(100) NOT NULL,
    dosis VARCHAR(50),
    jumlah INTEGER,
    aturan_pakai TEXT,
    status VARCHAR(20) DEFAULT 'Baru' CHECK (status IN ('Baru', 'Diproses', 'Selesai', 'Batal')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_resep, status)
) PARTITION BY LIST (status);

-- Partisi untuk resep baru
CREATE TABLE resep_baru PARTITION OF resep_obat
    FOR VALUES IN ('Baru');

-- Partisi untuk resep diproses
CREATE TABLE resep_diproses PARTITION OF resep_obat
    FOR VALUES IN ('Diproses');

-- Partisi untuk resep selesai
CREATE TABLE resep_selesai PARTITION OF resep_obat
    FOR VALUES IN ('Selesai');

-- Partisi untuk resep batal
CREATE TABLE resep_batal PARTITION OF resep_obat
    FOR VALUES IN ('Batal');

-- =============================================
-- FUNGSI DAN TRIGGER UNTUK MANAJEMEN FRAGMENTASI
-- =============================================

-- Fungsi untuk membuat partition kunjungan baru otomatis
CREATE OR REPLACE FUNCTION create_kunjungan_partition()
RETURNS TRIGGER AS $$
DECLARE
    year_start DATE;
    year_end DATE;
    partition_name TEXT;
BEGIN
    year_start := DATE_TRUNC('year', NEW.tgl_kunjungan);
    year_end := year_start + INTERVAL '1 year';
    partition_name := 'kunjungan_' || EXTRACT(YEAR FROM NEW.tgl_kunjungan);
    
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF kunjungan ' ||
            'FOR VALUES FROM (%L) TO (%L)',
            partition_name, year_start, year_end
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk auto-create partition kunjungan
CREATE TRIGGER trigger_create_kunjungan_partition
    BEFORE INSERT ON kunjungan
    FOR EACH ROW EXECUTE FUNCTION create_kunjungan_partition();

-- Fungsi untuk memindahkan pasien non-aktif
CREATE OR REPLACE FUNCTION archive_pasien()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status = 'Aktif' AND NEW.status != 'Aktif' THEN
        RAISE NOTICE 'Pasien % dipindahkan ke status %', OLD.id_pasien, NEW.status;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk archive pasien
CREATE TRIGGER trigger_archive_pasien
    AFTER UPDATE OF status ON pasien
    FOR EACH ROW EXECUTE FUNCTION archive_pasien();

-- =============================================
-- INSERT DATA CONTOH
-- =============================================

-- Data poliklinik
INSERT INTO poliklinik (kode_poli, nama_poli, lokasi) VALUES
('P001', 'Poli Umum', 'Lantai 1 - Gedung A'),
('P002', 'Poli Anak', 'Lantai 1 - Gedung A'),
('P003', 'Poli Kandungan', 'Lantai 2 - Gedung A'),
('P004', 'Poli Bedah', 'Lantai 2 - Gedung A'),
('P005', 'Poli Jantung', 'Lantai 3 - Gedung B');

-- Data dokter
INSERT INTO dokter (nip, nama, spesialisasi, no_telepon, email) VALUES
('D001', 'Dr. Ahmad Santoso', 'Umum', '081234567890', 'ahmad@rsudbalung.go.id'),
('D002', 'Dr. Siti Rahayu', 'Anak', '081234567891', 'siti@rsudbalung.go.id'),
('D003', 'Dr. Budi Wijaya', 'Kandungan', '081234567892', 'budi@rsudbalung.go.id'),
('D004', 'Dr. Rina Astuti', 'Bedah', '081234567893', 'rina@rsudbalung.go.id'),
('D005', 'Dr. Agus Prasetyo', 'Jantung', '081234567894', 'agus@rsudbalung.go.id');

-- Data tindakan medis
INSERT INTO tindakan_medis (kode_tindakan, nama_tindakan, tarif) VALUES
('T001', 'Konsultasi Dokter', 50000.00),
('T002', 'Pemeriksaan Fisik', 75000.00),
('T003', 'Pemeriksaan Laboratorium Darah', 120000.00),
('T004', 'Pemeriksaan USG', 250000.00),
('T005', 'EKG', 150000.00);

-- Data pasien
INSERT INTO pasien (no_rm, nik, nama, tempat_lahir, tanggal_lahir, jenis_kelamin, alamat, golongan_darah) VALUES
('RM001', '3511234567890001', 'Budi Santoso', 'Jember', '1990-05-15', 'Laki-laki', 'Jl. Merdeka No. 123', 'A'),
('RM002', '3511234567890002', 'Sari Indah', 'Jember', '1985-08-20', 'Perempuan', 'Jl. Diponegoro No. 45', 'B'),
('RM003', '3511234567890003', 'Ahmad Fauzi', 'Jember', '1978-12-10', 'Laki-laki', 'Jl. Sudirman No. 78', 'O'),
('RM004', '3511234567890004', 'Dewi Kusuma', 'Jember', '1995-03-25', 'Perempuan', 'Jl. Gatot Subroto No. 56', 'AB'),
('RM005', '3511234567890005', 'Joko Widodo', 'Jember', '1982-07-17', 'Laki-laki', 'Jl. Pahlawan No. 89', 'A');

-- Data kunjungan
INSERT INTO kunjungan (id_pasien, id_dokter, id_poli, no_registrasi, tgl_kunjungan, keluhan_utama, tekanan_darah, suhu_badan) VALUES
(1, 1, 1, 'REG20240001', '2024-01-15', 'Demam dan batuk', '120/80', 38.5),
(2, 2, 2, 'REG20240002', '2024-02-20', 'Pemeriksaan kehamilan', '110/70', 36.8),
(3, 3, 3, 'REG20240003', '2024-03-10', 'Nyeri perut', '130/85', 37.2),
(4, 4, 4, 'REG20240004', '2024-04-05', 'Kontrol pasca operasi', '125/80', 36.9),
(5, 5, 5, 'REG20240005', '2024-05-12', 'Nyeri dada', '140/90', 37.1);

-- Data diagnosis
INSERT INTO diagnosis (id_kunjungan, kode_icd, nama_diagnosis, jenis_diagnosis, catatan_dokter) VALUES
(1, 'J06.9', 'Infeksi Saluran Pernapasan Akut', 'Primer', 'Istirahat dan minum obat teratur'),
(2, 'Z34.0', 'Pemantauan Kehamilan Normal', 'Primer', 'Kondisi janin baik, kontrol rutin'),
(3, 'R10.4', 'Nyeri Perut yang Tidak Spesifik', 'Primer', 'Disarankan endoskopi'),
(4, 'Z48.0', 'Pemeriksaan Pascabedah', 'Primer', 'Luka operasi sembuh dengan baik'),
(5, 'I20.9', 'Angina Pektoris', 'Primer', 'Perlu pemeriksaan EKG lanjutan');

-- Data tindakan
INSERT INTO tindakan (id_kunjungan, kode_tindakan, nama_tindakan, hasil_tindakan) VALUES
(1, 'T001', 'Konsultasi Dokter', 'Pasien diberikan resep obat demam dan antibiotik'),
(2, 'T002', 'Pemeriksaan Fisik', 'Kehamilan trimester kedua, kondisi normal'),
(3, 'T004', 'Pemeriksaan USG', 'Terdapat indikasi radang usus buntu'),
(4, 'T002', 'Pemeriksaan Fisik', 'Luka operasi sudah kering, jahitan bisa dilepas'),
(5, 'T005', 'EKG', 'Terlihat adanya gangguan irama jantung ringan');

-- Data resep obat
INSERT INTO resep_obat (id_kunjungan, nama_obat, dosis, jumlah, aturan_pakai, status) VALUES
(1, 'Paracetamol', '500 mg', 10, '3x1 sehari setelah makan', 'Selesai'),
(1, 'Amoxicillin', '500 mg', 14, '2x1 sehari setelah makan', 'Selesai'),
(2, 'Asam Folat', '400 mcg', 30, '1x1 sehari', 'Selesai'),
(3, 'Antasida', '250 mg', 12, '3x1 sehari sebelum makan', 'Diproses'),
(5, 'Isosorbide Dinitrate', '5 mg', 20, '3x1 sehari', 'Baru');


-- Indeks untuk tabel pasien
CREATE INDEX idx_pasien_nik ON pasien(nik);
CREATE INDEX idx_pasien_no_rm ON pasien(no_rm);
CREATE INDEX idx_pasien_status ON pasien(status);

-- Indeks untuk tabel kunjungan
CREATE INDEX idx_kunjungan_tgl ON kunjungan(tgl_kunjungan);
CREATE INDEX idx_kunjungan_pasien ON kunjungan(id_pasien);
CREATE INDEX idx_kunjungan_dokter ON kunjungan(id_dokter);
CREATE INDEX idx_kunjungan_poli ON kunjungan(id_poli);

-- Indeks untuk tabel diagnosis
CREATE INDEX idx_diagnosis_kunjungan ON diagnosis(id_kunjungan);
CREATE INDEX idx_diagnosis_icd ON diagnosis(kode_icd);

-- Indeks untuk tabel tindakan
CREATE INDEX idx_tindakan_kunjungan ON tindakan(id_kunjungan);

-- Indeks untuk tabel resep_obat
CREATE INDEX idx_resep_kunjungan ON resep_obat(id_kunjungan);
CREATE INDEX idx_resep_status ON resep_obat(status);


-- View untuk melihat riwayat kunjungan pasien
CREATE VIEW view_riwayat_kunjungan AS
SELECT 
    p.no_rm,
    p.nama AS nama_pasien,
    k.no_registrasi,
    k.tgl_kunjungan,
    poli.nama_poli,
    d.nama AS nama_dokter,
    k.keluhan_utama,
    di.nama_diagnosis
FROM kunjungan k
JOIN pasien p ON k.id_pasien = p.id_pasien
JOIN poliklinik poli ON k.id_poli = poli.id_poli
JOIN dokter d ON k.id_dokter = d.id_dokter
LEFT JOIN diagnosis di ON k.id_kunjungan = di.id_kunjungan
ORDER BY k.tgl_kunjungan DESC;

-- View untuk melihat resep yang perlu diproses
CREATE VIEW view_resep_pending AS
SELECT 
    r.id_resep,
    k.no_registrasi,
    p.nama AS nama_pasien,
    r.nama_obat,
    r.dosis,
    r.jumlah,
    r.aturan_pakai,
    r.status,
    r.created_at
FROM resep_obat r
JOIN kunjungan k ON r.id_kunjungan = k.id_kunjungan
JOIN pasien p ON k.id_pasien = p.id_pasien
WHERE r.status IN ('Baru', 'Diproses')
ORDER BY r.created_at DESC;


-- Query untuk melihat data pasien aktif
SELECT * FROM pasien_aktif;

-- Query untuk melihat kunjungan tahun 2024
SELECT * FROM kunjungan_2024;

-- Query untuk melihat resep yang perlu diproses
SELECT * FROM resep_baru;

-- Query menggunakan view riwayat kunjungan
SELECT * FROM view_riwayat_kunjungan WHERE no_rm = 'RM001';

-- Query menggunakan view resep pending
SELECT * FROM view_resep_pending;

-- =============================================
-- INFORMASI PARTISI UNTUK MONITORING
-- =============================================
SELECT 
    nmsp_parent.nspname AS parent_schema,
    parent.relname AS parent,
    nmsp_child.nspname AS child_schema,
    child.relname AS child
FROM pg_inherits
JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
JOIN pg_class child ON pg_inherits.inhrelid = child.oid
JOIN pg_namespace nmsp_parent ON nmsp_parent.oid = parent.relnamespace
JOIN pg_namespace nmsp_child ON nmsp_child.oid = child.relnamespace
WHERE parent.relname = 'kunjungan'
ORDER BY parent, child;
