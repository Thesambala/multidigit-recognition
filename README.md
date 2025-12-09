# multidigit_recognition

A Flutter-driven mobile experience for mendeteksi tulisan tangan multidigit.

## Gambaran Proyek

- **Tujuan**: mempermudah pengguna memindai angka berurutan (meteran listrik, tiket, dsb) lewat kamera atau unggah galeri, kemudian mengirimkan hasil crop ke backend untuk dikenali oleh model SVM.
- **Lingkup saat ini**: kode hanya berisi lapisan UI/UX (welcome page, onboarding deteksi, mock camera preview, hasil, dan riwayat). Belum ada koneksi ke backend maupun pipeline ML.
- **Model AI**: backend nantinya memuat model SVM di file `.joblib`, menjalankan preprocessing (grayscale, threshold, resize), lalu mengembalikan output string beserta akurasi.

## Alur Pengguna

1. Aplikasi dibuka dan menampilkan halaman home berisi penjelasan proyek serta tombol "Mulai Deteksi Multidigit".
2. Tombol memindahkan pengguna ke layar kamera dengan guide overlay hijau berformat persegi panjang. Pengguna dapat menekan tombol capture atau memilih ikon galeri.
3. Setelah foto dipilih/capture, gambar dipreview dan pengguna melakukan crop agar hanya area angka yang terpilih yang akan dikirimkan ke backend.
4. Backend menerima hasil crop, menjalankan preprocessing + model SVM, lalu mengembalikan string prediksi serta skor akurasi.
5. Aplikasi menampilkan halaman "Hasil Pengenalan Multidigit" yang berisi gambar, teks hasil prediksi, akurasi, serta tombol "Kembali ke Home".
6. Riwayat deteksi dapat ditampilkan untuk melihat hasil sebelumnya begitu penyimpanan lokal atau sinkronisasi backend tersedia.

## Integrasi Backend (Rencana)

- Endpoint utama: `POST /recognitions` (multipart image) -> respons JSON `{ prediction, accuracy, steps }`.
- Backend bertugas menyimpan berkas hasil capture/crop, menjalankan notebook/python preprocessing, memuat model `.joblib`, dan mengirimkan hasil akhir ke aplikasi.
- Frontend perlu menyediakan state loading, error handling, serta penyimpanan riwayat (mis. `hive` atau `sqflite`).

## Getting Started

Pastikan Flutter SDK telah terpasang, kemudian jalankan:

```bash
flutter pub get
flutter run
```

Referensi Flutter:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

Dokumentasi lengkap tersedia di [Flutter docs](https://docs.flutter.dev/) untuk tutorial, panduan, dan API reference.
