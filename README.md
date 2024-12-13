# Flutter Admin Panel

Sebuah admin panel yang dibangun dengan Flutter Web untuk mengelola kategori dan banner. Proyek ini menggunakan Supabase untuk penyimpanan file dan Firebase Firestore untuk manajemen data.

## Fitur Utama

### Manajemen Kategori
- Upload gambar kategori ke Supabase Storage
- Penyimpanan metadata kategori di Firestore
- Tampilan daftar kategori real-time
- Fungsi pencarian kategori
- Hapus kategori (termasuk gambar dari storage)
- Penamaan file unik menggunakan timestamp

### Manajemen Banner
- Upload gambar banner ke Supabase Storage
- Penyimpanan metadata banner di Firestore
- Tampilan daftar banner real-time
- Fungsi pencarian banner
- Hapus banner (termasuk gambar dari storage)
- Dukungan aspek rasio 16:9

## Teknologi yang Digunakan

- Flutter Web
- Supabase Storage untuk penyimpanan file
- Firebase Firestore untuk database
- File Picker untuk pemilihan file
- UUID untuk generasi ID unik

## Struktur Penyimpanan

### Supabase Storage
- Bucket `categories`: Menyimpan gambar kategori
  - Path: `categories/[timestamp]_[nama_kategori].png`
- Bucket `banners`: Menyimpan gambar banner
  - Path: `banners/banner_[timestamp].png`

### Firebase Firestore
- Collection `categories`: Metadata kategori
- Collection `banners`: Metadata banner

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.8.1
  file_picker: ^6.1.1
  uuid: ^4.2.2
  firebase_core: ^3.8.1
  cloud_firestore: ^5.5.1
```

## Konfigurasi

1. Supabase
   - Buat bucket `categories` dan `banners`
   - Aktifkan public access untuk bucket
   - Konfigurasi RLS (Row Level Security)

2. Firebase
   - Setup Firebase project
   - Tambahkan Firebase config ke `web/index.html`
   - Enable Firestore

## Fitur Keamanan

- Validasi file sebelum upload
- Sanitasi nama file
- Penanganan error komprehensif
- Konfirmasi sebelum penghapusan
- Feedback user melalui SnackBar

## Error Handling

- Validasi input
- Pengecekan eksistensi file
- Penanganan error storage
- Penanganan error database
- Feedback visual untuk user

## Best Practices

- Penamaan file unik untuk mencegah konflik
- Pemisahan logika storage dan database
- Loading state untuk operasi async
- Feedback user yang informatif
- Konfirmasi untuk operasi destruktif

## Pengembangan Selanjutnya

- [ ] Implementasi edit kategori/banner
- [ ] Kompresi gambar
- [ ] Paginasi untuk daftar
- [ ] Filter dan sort lanjutan
- [ ] Manajemen permission
- [ ] Optimasi performa
- [ ] Unit testing

## Kontribusi

Silakan berkontribusi dengan membuat pull request atau melaporkan issues.

## Lisensi

MIT License - lihat file LICENSE untuk detail lengkap.
