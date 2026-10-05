# Deploy tanpa Composer atau SSH

Script `scripts/Build-SharedHostingRelease.ps1` menyalin dependensi Composer yang sudah tersedia di folder `vendor/`. Hosting tidak perlu menyediakan Composer ataupun SSH.

## Prasyarat hosting

- PHP 8.2 atau lebih baru. Aplikasi ini menolak PHP yang lebih lama di front controller.
- MySQL/MariaDB serta ekstensi PHP `intl`, `mbstring`, `mysqli`/`mysqlnd`, `xml`, `curl`, dan `fileinfo`.
- Apache dengan `mod_rewrite`, atau fasilitas pengaturan document root.
- Izin tulis untuk `writable/`.
- Batas memori dan upload yang sesuai dengan file koleksi perpustakaan.

## Buat paket rilis

Jalankan di komputer pengembangan, dari root proyek:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-SharedHostingRelease.ps1 -Layout Standard
```

Paket muncul di `artifacts/shared-hosting-release/`. File `.env` lokal tidak pernah disalin, sehingga kredensial tidak ikut terunggah secara tidak sengaja.

### Layout Standard (disarankan)

Pilih ini jika control panel dapat mengarahkan domain/subdomain ke suatu folder.

1. Unggah `inlislite-core` sebagai folder saudara di luar `public_html` jika memungkinkan.
2. Unggah isi folder `public` ke document root domain, atau atur document root ke folder `public` tersebut. Folder `public` dan `inlislite-core` harus tetap sejajar.
3. Ganti nama `inlislite-core/.env.production.template` menjadi `.env`, lalu isi URL, database, dan rahasia aplikasi.
4. Buat database dan impor dump database melalui phpMyAdmin.
5. Pastikan `inlislite-core/writable` dapat ditulis oleh PHP.

Jika `inlislite-core` dipindahkan ke lokasi lain, sesuaikan baris `require` pada `public/index.php` agar menunjuk ke `app/Config/Paths.php` di lokasi tersebut.

### Layout WebrootFallback

Pakai hanya jika hosting tidak memperbolehkan pengaturan document root, tetapi mengizinkan `.env`, CodeIgniter, dan aturan `.htaccess`.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Build-SharedHostingRelease.ps1 -Layout WebrootFallback -OutputDirectory .\artifacts\shared-hosting-fallback
```

Unggah isi paket langsung ke `public_html`/`htdocs`. Kode aplikasi berada di `__inlislite` dan mendapat aturan Apache yang memblokir akses web langsung. Ganti nama `__inlislite/.env.production.template` menjadi `.env` dan isi nilainya sebelum membuka situs.

## Jangan gunakan InfinityFree gratis untuk produksi

InfinityFree gratis bukan hanya tidak menyediakan Composer/SSH. Dokumentasi forum mereka menyatakan aplikasi CodeIgniter yang memakai `.env` tidak dapat digunakan pada server tersebut, tidak menyediakan cron job, dan menerapkan batas ukuran berkas 1 MB untuk PHP/HTML, 10 KB untuk `.htaccess`, serta 10 MB untuk berkas lain. Ini juga tidak cocok untuk pengunggahan koleksi digital.

Proyek ini sendiri memiliki `vendor/endroid/qr-code/assets/noto_sans.otf` sekitar 15.7 MB, jadi akan dihapus oleh batas 10 MB tersebut. Pilih shared hosting berbayar yang memenuhi prasyarat di atas, atau VPS. Fitur auto-return pinjaman digital juga membutuhkan cron job.

Sumber: [batas ukuran berkas InfinityFree](https://forum.infinityfree.com/t/what-is-the-file-upload-size-limit/49308), [batas CodeIgniter/.env](https://forum.infinityfree.com/t/add-a-php-extension/38332/8), dan [dukungan cron job](https://forum.infinityfree.com/t/how-to-run-a-cronjob-manually-external-in-a-url-link/93299).
