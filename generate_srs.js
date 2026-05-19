const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, LevelFormat,
  TableOfContents
} = require('docx');
const fs = require('fs');

// ── Color palette ──────────────────────────────────────────────
const BLUE_DARK  = "1F3A6E";
const BLUE_MID   = "2E5FAC";
const BLUE_LIGHT = "D6E4F7";
const BLUE_PALE  = "EEF4FB";
const GRAY_HEAD  = "4A4A4A";
const GRAY_LIGHT = "F5F5F5";
const WHITE      = "FFFFFF";

// ── Border helpers ─────────────────────────────────────────────
const borderNone = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const borderCell = { style: BorderStyle.SINGLE, size: 4, color: "CCCCCC" };
const borderHead = { style: BorderStyle.SINGLE, size: 4, color: BLUE_MID };
const allBorderNone = { top: borderNone, bottom: borderNone, left: borderNone, right: borderNone };

// ── Helpers ────────────────────────────────────────────────────
function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    children: [new TextRun({ text, bold: true, font: "Arial", size: 28, color: BLUE_DARK })],
    spacing: { before: 360, after: 160 },
    border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BLUE_MID, space: 4 } }
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    children: [new TextRun({ text, bold: true, font: "Arial", size: 24, color: BLUE_MID })],
    spacing: { before: 280, after: 120 }
  });
}

function h3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    children: [new TextRun({ text, bold: true, font: "Arial", size: 22, color: GRAY_HEAD })],
    spacing: { before: 200, after: 80 }
  });
}

function body(text, opts = {}) {
  return new Paragraph({
    alignment: opts.justify ? AlignmentType.JUSTIFIED : AlignmentType.LEFT,
    spacing: { before: 60, after: 80, line: 276 },
    children: [new TextRun({ text, font: "Arial", size: 22, color: "333333", ...opts.run })]
  });
}

function bodyJustify(text, runOpts = {}) {
  return body(text, { justify: true, run: runOpts });
}

function bullet(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "bullets", level },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, font: "Arial", size: 22, color: "333333" })]
  });
}

function numbered(text, level = 0) {
  return new Paragraph({
    numbering: { reference: "numbers", level },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, font: "Arial", size: 22, color: "333333" })]
  });
}

function spacer(lines = 1) {
  return new Paragraph({
    children: [new TextRun("")],
    spacing: { before: 0, after: lines * 80 }
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function infoRow(label, value) {
  return new TableRow({
    children: [
      new TableCell({
        width: { size: 3600, type: WidthType.DXA },
        shading: { fill: BLUE_LIGHT, type: ShadingType.CLEAR },
        borders: { top: borderCell, bottom: borderCell, left: borderCell, right: borderCell },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: label, bold: true, font: "Arial", size: 20, color: BLUE_DARK })] })]
      }),
      new TableCell({
        width: { size: 5760, type: WidthType.DXA },
        borders: { top: borderCell, bottom: borderCell, left: borderCell, right: borderCell },
        margins: { top: 80, bottom: 80, left: 120, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: value, font: "Arial", size: 20, color: "333333" })] })]
      })
    ]
  });
}

function headerRow(cells, widths) {
  return new TableRow({
    tableHeader: true,
    children: cells.map((c, i) => new TableCell({
      width: { size: widths[i], type: WidthType.DXA },
      shading: { fill: BLUE_MID, type: ShadingType.CLEAR },
      borders: { top: borderHead, bottom: borderHead, left: borderHead, right: borderHead },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: c, bold: true, font: "Arial", size: 20, color: WHITE })] })]
    }))
  });
}

function dataRow(cells, widths, shade = false) {
  return new TableRow({
    children: cells.map((c, i) => new TableCell({
      width: { size: widths[i], type: WidthType.DXA },
      shading: { fill: shade ? GRAY_LIGHT : WHITE, type: ShadingType.CLEAR },
      borders: { top: borderCell, bottom: borderCell, left: borderCell, right: borderCell },
      margins: { top: 80, bottom: 80, left: 120, right: 120 },
      children: [new Paragraph({ children: [new TextRun({ text: c, font: "Arial", size: 20, color: "333333" })] })]
    }))
  });
}

function sectionBox(title, items) {
  // A shaded box for important notes / definitions
  const rows = items.map((item, i) => new TableRow({
    children: [
      new TableCell({
        width: { size: 9360, type: WidthType.DXA },
        shading: { fill: i === 0 ? BLUE_LIGHT : BLUE_PALE, type: ShadingType.CLEAR },
        borders: { top: borderCell, bottom: borderCell, left: { style: BorderStyle.SINGLE, size: 12, color: BLUE_MID }, right: borderCell },
        margins: { top: 80, bottom: 80, left: 160, right: 120 },
        children: [new Paragraph({ children: [new TextRun({ text: item, font: "Arial", size: i === 0 ? 22 : 20, bold: i === 0, color: i === 0 ? BLUE_DARK : "444444" })] })]
      })
    ]
  }));
  return new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: [9360], rows });
}

// ── Cover Page ─────────────────────────────────────────────────
function coverPage() {
  return [
    spacer(4),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 40 },
      children: [new TextRun({ text: "SOFTWARE REQUIREMENTS SPECIFICATION", font: "Arial", size: 44, bold: true, color: BLUE_DARK })]
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 0, after: 200 },
      children: [new TextRun({ text: "Aplikasi LineWork", font: "Arial", size: 36, color: BLUE_MID })]
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      border: { bottom: { style: BorderStyle.SINGLE, size: 12, color: BLUE_MID, space: 4 } },
      spacing: { before: 0, after: 160 },
      children: [new TextRun({ text: "Platform Kolaborasi Tenaga Masyarakat Berbasis Lokasi", font: "Arial", size: 26, italics: true, color: GRAY_HEAD })]
    }),
    spacer(2),
    new Table({
      width: { size: 7200, type: WidthType.DXA },
      columnWidths: [3000, 4200],
      rows: [
        infoRow("Versi Dokumen", "1.0"),
        infoRow("Tanggal", "2025"),
        infoRow("Status", "Draft Awal"),
        infoRow("Jenis Dokumen", "Software Requirements Specification (SRS)"),
        infoRow("Standar Referensi", "IEEE 830-1998"),
        infoRow("Platform Target", "Android (Google Play Store)"),
        infoRow("Tech Stack", "Flutter · Firebase · Firestore"),
      ]
    }),
    spacer(3),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: "Dokumen ini disusun sebagai bagian dari Tugas Akhir", font: "Arial", size: 20, italics: true, color: "888888" })]
    }),
    pageBreak()
  ];
}

// ══════════════════════════════════════════════════════════════════
// MAIN DOCUMENT BUILD
// ══════════════════════════════════════════════════════════════════
const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 1, format: LevelFormat.BULLET, text: "\u25E6", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 1080, hanging: 360 } } } }
        ]
      },
      {
        reference: "numbers",
        levels: [
          { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 1, format: LevelFormat.LOWER_LETTER, text: "%2.", alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 1080, hanging: 360 } } } }
        ]
      }
    ]
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: BLUE_DARK },
        paragraph: { spacing: { before: 360, after: 160 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: BLUE_MID },
        paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 22, bold: true, font: "Arial", color: GRAY_HEAD },
        paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 } },
    ]
  },
  sections: [{
    properties: {
      page: {
        size: { width: 11906, height: 16838 },
        margin: { top: 1440, right: 1260, bottom: 1440, left: 1440 }
      }
    },
    headers: {
      default: new Header({
        children: [
          new Paragraph({
            alignment: AlignmentType.RIGHT,
            border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: BLUE_MID, space: 4 } },
            spacing: { before: 0, after: 80 },
            children: [
              new TextRun({ text: "LineWork — Software Requirements Specification  |  v1.0", font: "Arial", size: 18, color: "888888" })
            ]
          })
        ]
      })
    },
    footers: {
      default: new Footer({
        children: [
          new Paragraph({
            alignment: AlignmentType.CENTER,
            border: { top: { style: BorderStyle.SINGLE, size: 4, color: BLUE_MID, space: 4 } },
            spacing: { before: 80, after: 0 },
            children: [
              new TextRun({ text: "Halaman ", font: "Arial", size: 18, color: "888888" }),
              PageNumber.CURRENT,
              new TextRun({ text: "  |  Dokumen Tugas Akhir — Aplikasi LineWork", font: "Arial", size: 18, color: "888888" })
            ]
          })
        ]
      })
    },
    children: [
      // ── Cover ────────────────────────────────────────────────
      ...coverPage(),

      // ── Daftar Isi ───────────────────────────────────────────
      h1("Daftar Isi"),
      new TableOfContents("Daftar Isi", {
        hyperlink: true,
        headingStyleRange: "1-3",
        stylesWithLevels: [
          { styleName: "Heading1", level: 1 },
          { styleName: "Heading2", level: 2 },
          { styleName: "Heading3", level: 3 },
        ]
      }),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 1 — PENDAHULUAN
      // ══════════════════════════════════════════════════════════
      h1("1. Pendahuluan"),

      h2("1.1 Tujuan Dokumen"),
      bodyJustify("Dokumen Software Requirements Specification (SRS) ini menjelaskan secara lengkap semua kebutuhan fungsional dan non-fungsional untuk aplikasi LineWork. Dokumen ini ditujukan kepada pengembang, pembimbing tugas akhir, serta pemangku kepentingan lainnya yang terlibat dalam proses perancangan dan pengembangan sistem."),
      spacer(),

      h2("1.2 Ruang Lingkup"),
      bodyJustify("LineWork adalah aplikasi mobile berbasis Android yang berfungsi sebagai platform marketplace jasa mikro berbasis lokasi. Aplikasi ini mempertemukan dua jenis pengguna:"),
      bullet("Pemohon — individu yang membutuhkan bantuan tenaga fisik untuk suatu pekerjaan."),
      bullet("Penyedia Jasa — individu yang bersedia membantu dan mendapatkan imbalan atas jasa yang diberikan."),
      spacer(),
      bodyJustify("Fitur utama yang akan dikembangkan meliputi sistem posting pekerjaan, peta interaktif berbasis GPS, sistem lelang terbalik (bidding), verifikasi identitas, rating dua arah, dan notifikasi real-time berdasarkan radius lokasi."),
      spacer(),

      h2("1.3 Definisi, Akronim, dan Singkatan"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2800, 6560],
        rows: [
          headerRow(["Istilah / Akronim", "Definisi"], [2800, 6560]),
          dataRow(["SRS", "Software Requirements Specification — dokumen spesifikasi kebutuhan perangkat lunak"], [2800, 6560], false),
          dataRow(["Pemohon", "Pengguna yang memposting pekerjaan dan mencari bantuan tenaga"], [2800, 6560], true),
          dataRow(["Penyedia Jasa", "Pengguna yang menawarkan tenaga dan menerima pekerjaan"], [2800, 6560], false),
          dataRow(["Bidding", "Sistem lelang terbalik di mana pemohon menetapkan harga, penyedia memilih"], [2800, 6560], true),
          dataRow(["COD", "Cash On Delivery — pembayaran tunai di lokasi setelah pekerjaan selesai"], [2800, 6560], false),
          dataRow(["GPS", "Global Positioning System — sistem penentuan posisi berbasis satelit"], [2800, 6560], true),
          dataRow(["Haversine", "Algoritma perhitungan jarak dua titik koordinat di permukaan bumi"], [2800, 6560], false),
          dataRow(["NIK", "Nomor Induk Kependudukan — nomor identitas warga Indonesia pada KTP"], [2800, 6560], true),
          dataRow(["KTP", "Kartu Tanda Penduduk — kartu identitas resmi warga negara Indonesia"], [2800, 6560], false),
          dataRow(["Firebase", "Platform backend dari Google untuk autentikasi, database, dan penyimpanan"], [2800, 6560], true),
          dataRow(["Firestore", "Cloud NoSQL database milik Firebase untuk data real-time"], [2800, 6560], false),
          dataRow(["Flutter", "Framework UI cross-platform dari Google berbasis bahasa Dart"], [2800, 6560], true),
          dataRow(["UI", "User Interface — antarmuka pengguna"], [2800, 6560], false),
          dataRow(["UX", "User Experience — pengalaman pengguna dalam berinteraksi dengan sistem"], [2800, 6560], true),
          dataRow(["API", "Application Programming Interface — antarmuka pemrograman aplikasi"], [2800, 6560], false),
        ]
      }),
      spacer(),

      h2("1.4 Referensi"),
      bullet("IEEE Std 830-1998, IEEE Recommended Practice for Software Requirements Specifications."),
      bullet("Google Firebase Documentation — https://firebase.google.com/docs"),
      bullet("Flutter Documentation — https://flutter.dev/docs"),
      bullet("Peraturan Pemerintah terkait perlindungan data pribadi (UU ITE No. 19 Tahun 2016)."),
      spacer(),

      h2("1.5 Gambaran Umum Dokumen"),
      bodyJustify("Dokumen ini terdiri dari lima bab utama. Bab 1 berisi pendahuluan dan konteks sistem. Bab 2 menjelaskan deskripsi umum produk. Bab 3 merinci semua kebutuhan fungsional sistem. Bab 4 menjelaskan kebutuhan non-fungsional. Bab 5 memuat batasan dan asumsi pengembangan."),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 2 — DESKRIPSI UMUM
      // ══════════════════════════════════════════════════════════
      h1("2. Deskripsi Umum Produk"),

      h2("2.1 Perspektif Produk"),
      bodyJustify("LineWork merupakan aplikasi mobile baru yang berdiri sendiri (standalone) dan tidak merupakan bagian dari sistem yang lebih besar. Aplikasi ini dibangun dengan pendekatan client-server, di mana aplikasi Flutter di perangkat pengguna berkomunikasi dengan layanan Firebase di cloud. Nama \"LineWork\" dipilih karena melambangkan garis koneksi (line) yang efisien antara masalah dan solusi, sesuai tagline: Beresin urusan jadi ringan."),
      spacer(),

      h2("2.2 Fungsi Utama Produk"),
      bodyJustify("Berikut adalah fungsi-fungsi utama yang akan disediakan oleh aplikasi LineWork:"),
      spacer(0),
      numbered("Registrasi dan verifikasi pengguna dengan NIK dan foto KTP."),
      numbered("Posting pekerjaan oleh Pemohon dengan deskripsi, lokasi GPS, dan tarif yang ditawarkan."),
      numbered("Penjelajahan pekerjaan melalui peta interaktif real-time oleh Penyedia Jasa."),
      numbered("Sistem bidding terbalik: Pemohon menetapkan harga, Penyedia Jasa memilih pekerjaan yang sesuai."),
      numbered("Manajemen status pekerjaan secara real-time (Open, In-Progress, Completed, Cancelled)."),
      numbered("Sistem pembayaran COD (Cash on Delivery) setelah pekerjaan selesai."),
      numbered("Rating dan ulasan dua arah antara Pemohon dan Penyedia Jasa."),
      numbered("Notifikasi push otomatis berdasarkan radius lokasi pengguna."),
      spacer(),

      h2("2.3 Karakteristik Pengguna"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2200, 3580, 3580],
        rows: [
          headerRow(["Karakteristik", "Pemohon", "Penyedia Jasa"], [2200, 3580, 3580]),
          dataRow(["Usia", "18 tahun ke atas", "18 tahun ke atas"], [2200, 3580, 3580], false),
          dataRow(["Kemampuan teknis", "Pengguna smartphone dasar", "Pengguna smartphone dasar"], [2200, 3580, 3580], true),
          dataRow(["Motivasi", "Butuh bantuan tenaga fisik", "Mencari penghasilan tambahan"], [2200, 3580, 3580], false),
          dataRow(["Frekuensi penggunaan", "Situasional / tidak rutin", "Rutin / harian"], [2200, 3580, 3580], true),
          dataRow(["Persyaratan khusus", "Memiliki NIK valid", "Memiliki NIK + KTP valid"], [2200, 3580, 3580], false),
        ]
      }),
      spacer(),

      h2("2.4 Batasan Umum"),
      bullet("Aplikasi hanya tersedia di platform Android pada tahap awal pengembangan."),
      bullet("Metode pembayaran yang didukung hanya COD (tunai di tempat); tidak ada integrasi payment gateway pada versi 1.0."),
      bullet("Sistem memerlukan koneksi internet aktif untuk seluruh fitur utama."),
      bullet("Lokasi GPS perangkat harus diaktifkan untuk menggunakan fitur peta dan notifikasi radius."),
      bullet("Penyedia Jasa wajib mengunggah foto KTP yang valid sebelum dapat menerima pekerjaan."),
      spacer(),

      h2("2.5 Asumsi dan Ketergantungan"),
      bullet("Pengguna memiliki smartphone Android versi 8.0 (API Level 26) atau lebih baru."),
      bullet("Layanan Firebase (Authentication, Firestore, Storage, Cloud Messaging) tersedia dan aktif."),
      bullet("Google Maps API tersedia dan memiliki kuota yang memadai untuk kebutuhan aplikasi."),
      bullet("Pengguna memberikan izin akses lokasi, kamera, dan notifikasi kepada aplikasi."),
      bullet("Data NIK yang dimasukkan dianggap valid secara format; validasi ke Dukcapil tidak dilakukan pada versi 1.0."),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 3 — KEBUTUHAN FUNGSIONAL
      // ══════════════════════════════════════════════════════════
      h1("3. Kebutuhan Fungsional"),
      bodyJustify("Kebutuhan fungsional dikelompokkan berdasarkan modul utama sistem. Setiap kebutuhan diberi kode unik untuk kemudahan penelusuran (traceability)."),
      spacer(),

      // Auth
      h2("3.1 Modul Autentikasi dan Manajemen Akun"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2400, 5560],
        rows: [
          headerRow(["Kode", "Nama Fitur", "Deskripsi"], [1400, 2400, 5560]),
          dataRow(["FR-AUTH-01", "Registrasi akun", "Pengguna dapat mendaftar menggunakan nomor telepon atau email, lalu memasukkan nama lengkap, NIK, dan memilih peran (Pemohon / Penyedia Jasa)."], [1400, 2400, 5560], false),
          dataRow(["FR-AUTH-02", "Verifikasi OTP", "Sistem mengirim kode OTP ke nomor telepon yang didaftarkan via Firebase Phone Auth untuk memverifikasi kepemilikan nomor."], [1400, 2400, 5560], true),
          dataRow(["FR-AUTH-03", "Login", "Pengguna dapat masuk ke akun menggunakan nomor telepon / email yang telah terverifikasi."], [1400, 2400, 5560], false),
          dataRow(["FR-AUTH-04", "Logout", "Pengguna dapat keluar dari sesi aktif kapan saja."], [1400, 2400, 5560], true),
          dataRow(["FR-AUTH-05", "Unggah foto KTP", "Khusus Penyedia Jasa: wajib mengunggah foto KTP melalui kamera atau galeri. Foto disimpan di Firebase Storage."], [1400, 2400, 5560], false),
          dataRow(["FR-AUTH-06", "Status verifikasi", "Sistem menampilkan status verifikasi akun (Belum Terverifikasi / Terverifikasi) pada profil pengguna."], [1400, 2400, 5560], true),
          dataRow(["FR-AUTH-07", "Edit profil", "Pengguna dapat mengubah nama tampilan dan foto profil. NIK tidak dapat diubah setelah registrasi."], [1400, 2400, 5560], false),
        ]
      }),
      spacer(),

      h2("3.2 Modul Posting dan Manajemen Pekerjaan"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2400, 5560],
        rows: [
          headerRow(["Kode", "Nama Fitur", "Deskripsi"], [1400, 2400, 5560]),
          dataRow(["FR-TASK-01", "Buat postingan", "Pemohon mengisi formulir: judul pekerjaan, deskripsi detail, kategori, tarif yang ditawarkan, estimasi durasi, dan jumlah tenaga yang dibutuhkan."], [1400, 2400, 5560], false),
          dataRow(["FR-TASK-02", "Penentuan lokasi", "Sistem secara otomatis mengambil koordinat GPS perangkat Pemohon sebagai lokasi pekerjaan. Pemohon dapat menyesuaikan pin lokasi secara manual di peta."], [1400, 2400, 5560], true),
          dataRow(["FR-TASK-03", "Tampilkan pekerjaan di peta", "Penyedia Jasa dapat melihat semua pekerjaan berstatus Open di sekitar lokasi mereka dalam bentuk pin pada peta interaktif Google Maps."], [1400, 2400, 5560], false),
          dataRow(["FR-TASK-04", "Filter pekerjaan", "Penyedia Jasa dapat memfilter daftar pekerjaan berdasarkan: radius jarak (km), kategori pekerjaan, dan rentang tarif minimum."], [1400, 2400, 5560], true),
          dataRow(["FR-TASK-05", "Perhitungan jarak", "Sistem menghitung dan menampilkan jarak antara posisi Penyedia Jasa dengan lokasi pekerjaan menggunakan algoritma Haversine."], [1400, 2400, 5560], false),
          dataRow(["FR-TASK-06", "Detail pekerjaan", "Setiap pekerjaan memiliki halaman detail yang menampilkan: deskripsi, tarif, lokasi di peta, estimasi durasi, dan profil Pemohon (nama + rating)."], [1400, 2400, 5560], true),
          dataRow(["FR-TASK-07", "Terima pekerjaan", "Penyedia Jasa yang memenuhi syarat (KTP terverifikasi) dapat menekan tombol \"Ambil Pekerjaan\" untuk mengambil pekerjaan berstatus Open."], [1400, 2400, 5560], false),
          dataRow(["FR-TASK-08", "Manajemen status", "Status pekerjaan berubah otomatis: Open → In-Progress (setelah diambil) → Completed (setelah dikonfirmasi kedua pihak) / Cancelled (dibatalkan)."], [1400, 2400, 5560], true),
          dataRow(["FR-TASK-09", "Riwayat pekerjaan", "Pengguna dapat melihat seluruh riwayat pekerjaan yang pernah diposting (Pemohon) atau dikerjakan (Penyedia Jasa), beserta statusnya."], [1400, 2400, 5560], false),
          dataRow(["FR-TASK-10", "Batalkan pekerjaan", "Pemohon dapat membatalkan pekerjaan berstatus Open. Pekerjaan berstatus In-Progress hanya dapat dibatalkan dengan persetujuan kedua pihak."], [1400, 2400, 5560], true),
        ]
      }),
      spacer(),

      h2("3.3 Modul Rating dan Ulasan"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2400, 5560],
        rows: [
          headerRow(["Kode", "Nama Fitur", "Deskripsi"], [1400, 2400, 5560]),
          dataRow(["FR-RATE-01", "Rating dua arah", "Setelah pekerjaan berstatus Completed, sistem meminta kedua pihak (Pemohon dan Penyedia Jasa) untuk memberikan rating bintang (1–5) kepada satu sama lain."], [1400, 2400, 5560], false),
          dataRow(["FR-RATE-02", "Ulasan teks", "Pengguna dapat menambahkan ulasan teks opsional (maks. 300 karakter) bersama dengan pemberian rating."], [1400, 2400, 5560], true),
          dataRow(["FR-RATE-03", "Tampil rating profil", "Profil pengguna menampilkan rata-rata rating keseluruhan dan jumlah ulasan yang diterima."], [1400, 2400, 5560], false),
          dataRow(["FR-RATE-04", "Satu rating per transaksi", "Setiap transaksi hanya menghasilkan satu kesempatan rating per pihak. Rating tidak dapat diubah setelah dikirimkan."], [1400, 2400, 5560], true),
        ]
      }),
      spacer(),

      h2("3.4 Modul Notifikasi"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2400, 5560],
        rows: [
          headerRow(["Kode", "Nama Fitur", "Deskripsi"], [1400, 2400, 5560]),
          dataRow(["FR-NOTIF-01", "Notifikasi pekerjaan baru", "Penyedia Jasa menerima push notification ketika ada pekerjaan baru yang diposting dalam radius yang telah mereka tetapkan."], [1400, 2400, 5560], false),
          dataRow(["FR-NOTIF-02", "Notifikasi status berubah", "Pemohon menerima notifikasi ketika pekerjaan mereka diambil oleh Penyedia Jasa. Penyedia Jasa menerima notifikasi ketika Pemohon mengkonfirmasi selesai."], [1400, 2400, 5560], true),
          dataRow(["FR-NOTIF-03", "Notifikasi rating", "Pengguna menerima notifikasi ketika mendapat rating baru dari transaksi yang telah selesai."], [1400, 2400, 5560], false),
          dataRow(["FR-NOTIF-04", "Pengaturan notifikasi", "Pengguna dapat mengaktifkan atau menonaktifkan notifikasi dari halaman pengaturan aplikasi."], [1400, 2400, 5560], true),
        ]
      }),
      spacer(),

      h2("3.5 Modul Peta dan Geospatial"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2400, 5560],
        rows: [
          headerRow(["Kode", "Nama Fitur", "Deskripsi"], [1400, 2400, 5560]),
          dataRow(["FR-GEO-01", "Tampilan peta real-time", "Aplikasi menampilkan peta interaktif (Google Maps) dengan posisi pengguna saat ini dan pin lokasi pekerjaan yang tersedia."], [1400, 2400, 5560], false),
          dataRow(["FR-GEO-02", "Izin lokasi", "Aplikasi meminta izin akses lokasi saat pertama kali dijalankan. Jika ditolak, fitur peta dan notifikasi radius tidak tersedia."], [1400, 2400, 5560], true),
          dataRow(["FR-GEO-03", "Algoritma Haversine", "Sistem menghitung jarak akurat antara dua koordinat GPS menggunakan formula Haversine untuk menentukan apakah suatu pekerjaan berada dalam radius pengguna."], [1400, 2400, 5560], false),
          dataRow(["FR-GEO-04", "Pengaturan radius", "Penyedia Jasa dapat mengatur radius pencarian pekerjaan (1 km – 50 km) dari halaman pengaturan."], [1400, 2400, 5560], true),
          dataRow(["FR-GEO-05", "Navigasi ke lokasi", "Dari halaman detail pekerjaan, Penyedia Jasa dapat membuka navigasi ke lokasi pekerjaan melalui Google Maps atau aplikasi peta lainnya."], [1400, 2400, 5560], false),
        ]
      }),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 4 — KEBUTUHAN NON-FUNGSIONAL
      // ══════════════════════════════════════════════════════════
      h1("4. Kebutuhan Non-Fungsional"),

      h2("4.1 Kebutuhan Performa"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2800, 5160],
        rows: [
          headerRow(["Kode", "Aspek", "Spesifikasi"], [1400, 2800, 5160]),
          dataRow(["NFR-PF-01", "Waktu respons API", "Respons dari Firebase/Firestore untuk operasi baca/tulis standar tidak melebihi 2 detik pada koneksi 4G stabil."], [1400, 2800, 5160], false),
          dataRow(["NFR-PF-02", "Pemuatan peta", "Peta interaktif beserta pin pekerjaan di sekitar pengguna harus selesai dimuat dalam waktu kurang dari 3 detik."], [1400, 2800, 5160], true),
          dataRow(["NFR-PF-03", "Pembaruan status real-time", "Perubahan status pekerjaan harus tersinkronisasi dan tampil di aplikasi kedua pihak dalam waktu kurang dari 1 detik (via Firestore Realtime Listener)."], [1400, 2800, 5160], false),
          dataRow(["NFR-PF-04", "Ukuran aplikasi", "Ukuran file instalasi (.apk) tidak melebihi 50 MB agar dapat diunduh pada koneksi data seluler yang terbatas."], [1400, 2800, 5160], true),
          dataRow(["NFR-PF-05", "Penggunaan baterai", "Aplikasi dioptimalkan agar tidak menguras baterai secara berlebihan; fitur location tracking hanya aktif saat aplikasi berada di foreground."], [1400, 2800, 5160], false),
        ]
      }),
      spacer(),

      h2("4.2 Kebutuhan Keamanan"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1400, 2800, 5160],
        rows: [
          headerRow(["Kode", "Aspek", "Spesifikasi"], [1400, 2800, 5160]),
          dataRow(["NFR-SEC-01", "Autentikasi pengguna", "Semua akses ke fitur aplikasi memerlukan sesi autentikasi yang valid melalui Firebase Authentication."], [1400, 2800, 5160], false),
          dataRow(["NFR-SEC-02", "Enkripsi data transmisi", "Semua komunikasi antara aplikasi dan Firebase menggunakan protokol HTTPS/TLS."], [1400, 2800, 5160], true),
          dataRow(["NFR-SEC-03", "Keamanan penyimpanan KTP", "Foto KTP disimpan di Firebase Storage dengan aturan akses (Security Rules) yang hanya mengizinkan pemilik akun dan admin mengaksesnya."], [1400, 2800, 5160], false),
          dataRow(["NFR-SEC-04", "Firestore Security Rules", "Semua operasi baca/tulis ke database Firestore dilindungi dengan Security Rules yang memverifikasi identitas dan peran pengguna sebelum mengizinkan akses."], [1400, 2800, 5160], true),
          dataRow(["NFR-SEC-05", "Validasi input", "Semua input dari pengguna divalidasi di sisi klien dan server untuk mencegah injeksi data yang tidak valid atau berbahaya."], [1400, 2800, 5160], false),
          dataRow(["NFR-SEC-06", "Proteksi data pribadi", "NIK dan data identitas pengguna tidak ditampilkan secara publik. Hanya data profil yang relevan (nama, foto, rating) yang dapat dilihat pengguna lain."], [1400, 2800, 5160], true),
        ]
      }),
      spacer(),

      h2("4.3 Kebutuhan Kegunaan (Usability)"),
      bullet("NFR-USE-01: Antarmuka menggunakan Bahasa Indonesia dan mengikuti pedoman Material Design 3 dari Google untuk konsistensi visual."),
      bullet("NFR-USE-02: Proses registrasi dapat diselesaikan oleh pengguna baru dalam waktu kurang dari 5 menit."),
      bullet("NFR-USE-03: Proses posting pekerjaan baru dapat diselesaikan dalam maksimal 4 langkah dari halaman utama."),
      bullet("NFR-USE-04: Teks, ikon, dan tombol dirancang dengan ukuran yang memenuhi standar aksesibilitas (touch target minimal 48x48 dp)."),
      spacer(),

      h2("4.4 Kebutuhan Keandalan (Reliability)"),
      bullet("NFR-REL-01: Sistem menerapkan mekanisme penanganan error yang informatif; jika koneksi terputus, aplikasi menampilkan pesan yang jelas dan mengantri operasi untuk diulang saat koneksi pulih."),
      bullet("NFR-REL-02: Data pekerjaan yang sudah terposting tidak akan hilang meski pengguna menutup aplikasi atau kehilangan koneksi sementara (Firestore offline persistence)."),
      bullet("NFR-REL-03: Ketersediaan layanan bergantung pada SLA Firebase (99.95% uptime) yang dijamin oleh Google."),
      spacer(),

      h2("4.5 Kebutuhan Pemeliharaan (Maintainability)"),
      bullet("NFR-MNT-01: Kode sumber diorganisasi menggunakan arsitektur yang jelas (disarankan Clean Architecture atau BLoC Pattern untuk Flutter)."),
      bullet("NFR-MNT-02: Setiap fungsi dan modul utama dilengkapi dengan komentar kode yang menjelaskan tujuan dan cara penggunaannya."),
      bullet("NFR-MNT-03: Skema database Firestore didokumentasikan dan dapat diperbarui tanpa mengubah seluruh struktur koleksi yang ada."),
      spacer(),

      h2("4.6 Kebutuhan Portabilitas"),
      bullet("NFR-PORT-01: Aplikasi kompatibel dengan Android versi 8.0 (API Level 26) ke atas, mencakup lebih dari 95% perangkat Android aktif."),
      bullet("NFR-PORT-02: Antarmuka responsif dan dapat menyesuaikan berbagai ukuran layar smartphone (dari 5 inci hingga tablet 10 inci)."),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 5 — BATASAN SISTEM & ANTARMUKA EKSTERNAL
      // ══════════════════════════════════════════════════════════
      h1("5. Batasan Sistem dan Antarmuka Eksternal"),

      h2("5.1 Batasan Pengembangan"),
      bullet("Versi 1.0 hanya menargetkan platform Android; versi iOS akan dipertimbangkan pada pengembangan selanjutnya."),
      bullet("Sistem tidak menyediakan mekanisme penyelesaian sengketa (dispute resolution) secara otomatis; sengketa diselesaikan di luar platform."),
      bullet("Verifikasi NIK dilakukan hanya validasi format (16 digit angka), bukan verifikasi ke sistem Dukcapil secara langsung."),
      bullet("Tidak ada fitur chat/pesan langsung antar pengguna pada versi 1.0; komunikasi diasumsikan terjadi melalui saluran di luar aplikasi."),
      spacer(),

      h2("5.2 Antarmuka Pengguna"),
      bodyJustify("Aplikasi menggunakan Flutter dengan Material Design 3 sebagai panduan antarmuka. Layar-layar utama yang akan dikembangkan adalah:"),
      bullet("Splash screen dan onboarding (3 halaman pengenalan fitur)."),
      bullet("Halaman registrasi dan login."),
      bullet("Halaman utama / beranda dengan peta interaktif."),
      bullet("Formulir posting pekerjaan baru."),
      bullet("Halaman detail pekerjaan."),
      bullet("Halaman riwayat pekerjaan."),
      bullet("Halaman profil dan pengaturan."),
      bullet("Halaman pemberian rating."),
      spacer(),

      h2("5.3 Antarmuka Perangkat Keras"),
      bullet("Kamera perangkat: digunakan untuk pengambilan foto KTP saat registrasi."),
      bullet("GPS / Location Services: digunakan untuk mendeteksi posisi pengguna secara real-time."),
      bullet("Penyimpanan internal: digunakan untuk cache peta dan data Firestore offline."),
      bullet("Koneksi internet (WiFi / Data Seluler): diperlukan untuk sinkronisasi data real-time."),
      spacer(),

      h2("5.4 Antarmuka Perangkat Lunak (Layanan Eksternal)"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2600, 2600, 4160],
        rows: [
          headerRow(["Layanan", "Penyedia", "Fungsi dalam Sistem"], [2600, 2600, 4160]),
          dataRow(["Firebase Authentication", "Google Firebase", "Autentikasi pengguna via OTP nomor telepon / email"], [2600, 2600, 4160], false),
          dataRow(["Cloud Firestore", "Google Firebase", "Database NoSQL real-time untuk semua data aplikasi"], [2600, 2600, 4160], true),
          dataRow(["Firebase Storage", "Google Firebase", "Penyimpanan foto KTP dan foto profil pengguna"], [2600, 2600, 4160], false),
          dataRow(["Firebase Cloud Messaging", "Google Firebase", "Pengiriman push notification ke perangkat pengguna"], [2600, 2600, 4160], true),
          dataRow(["Google Maps SDK", "Google Maps Platform", "Rendering peta interaktif dan penanda lokasi (pin)"], [2600, 2600, 4160], false),
          dataRow(["Google Maps Geocoding API", "Google Maps Platform", "Konversi koordinat GPS menjadi nama alamat yang dapat dibaca"], [2600, 2600, 4160], true),
        ]
      }),
      spacer(),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 6 — USE CASE RINGKAS
      // ══════════════════════════════════════════════════════════
      h1("6. Ringkasan Use Case"),
      bodyJustify("Berikut adalah daftar use case utama yang merepresentasikan seluruh interaksi aktor dengan sistem LineWork."),
      spacer(),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1200, 2800, 2200, 3160],
        rows: [
          headerRow(["Kode UC", "Nama Use Case", "Aktor", "Kebutuhan Terkait"], [1200, 2800, 2200, 3160]),
          dataRow(["UC-01", "Registrasi akun baru", "Pemohon / Penyedia Jasa", "FR-AUTH-01, FR-AUTH-02"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-02", "Login ke aplikasi", "Pemohon / Penyedia Jasa", "FR-AUTH-03"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-03", "Unggah dan verifikasi KTP", "Penyedia Jasa", "FR-AUTH-05, FR-AUTH-06"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-04", "Posting pekerjaan baru", "Pemohon", "FR-TASK-01, FR-TASK-02, FR-GEO-01"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-05", "Jelajah pekerjaan di peta", "Penyedia Jasa", "FR-TASK-03, FR-TASK-04, FR-GEO-01, FR-GEO-03"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-06", "Lihat detail pekerjaan", "Penyedia Jasa", "FR-TASK-06, FR-GEO-05"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-07", "Ambil pekerjaan (bidding)", "Penyedia Jasa", "FR-TASK-07, FR-TASK-08"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-08", "Konfirmasi pekerjaan selesai", "Pemohon / Penyedia Jasa", "FR-TASK-08"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-09", "Berikan rating dan ulasan", "Pemohon / Penyedia Jasa", "FR-RATE-01, FR-RATE-02"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-10", "Terima notifikasi pekerjaan baru", "Penyedia Jasa", "FR-NOTIF-01, FR-GEO-03, FR-GEO-04"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-11", "Lihat riwayat pekerjaan", "Pemohon / Penyedia Jasa", "FR-TASK-09"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-12", "Batalkan pekerjaan", "Pemohon", "FR-TASK-10"], [1200, 2800, 2200, 3160], true),
          dataRow(["UC-13", "Edit profil pengguna", "Pemohon / Penyedia Jasa", "FR-AUTH-07"], [1200, 2800, 2200, 3160], false),
          dataRow(["UC-14", "Atur radius notifikasi", "Penyedia Jasa", "FR-NOTIF-04, FR-GEO-04"], [1200, 2800, 2200, 3160], true),
        ]
      }),
      spacer(),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 7 — SKEMA DATABASE (FIRESTORE)
      // ══════════════════════════════════════════════════════════
      h1("7. Skema Database Firestore"),
      bodyJustify("Berikut adalah rancangan struktur koleksi dan dokumen pada Cloud Firestore yang digunakan oleh aplikasi LineWork. Firestore menggunakan model NoSQL berbasis dokumen."),
      spacer(),

      h2("7.1 Koleksi users"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2600, 1800, 4960],
        rows: [
          headerRow(["Field", "Tipe Data", "Keterangan"], [2600, 1800, 4960]),
          dataRow(["uid", "String (PK)", "ID unik dari Firebase Authentication"], [2600, 1800, 4960], false),
          dataRow(["fullName", "String", "Nama lengkap pengguna"], [2600, 1800, 4960], true),
          dataRow(["phoneNumber", "String", "Nomor telepon terverifikasi"], [2600, 1800, 4960], false),
          dataRow(["nik", "String", "Nomor Induk Kependudukan (16 digit, terenkripsi)"], [2600, 1800, 4960], true),
          dataRow(["role", "String", "Nilai: 'pemohon' atau 'penyedia'"], [2600, 1800, 4960], false),
          dataRow(["ktpUrl", "String", "URL foto KTP di Firebase Storage (hanya penyedia)"], [2600, 1800, 4960], true),
          dataRow(["isVerified", "Boolean", "Status verifikasi KTP oleh admin"], [2600, 1800, 4960], false),
          dataRow(["photoUrl", "String", "URL foto profil pengguna"], [2600, 1800, 4960], true),
          dataRow(["rating", "Number", "Rata-rata rating yang diterima (0.0 – 5.0)"], [2600, 1800, 4960], false),
          dataRow(["ratingCount", "Number", "Jumlah total rating yang diterima"], [2600, 1800, 4960], true),
          dataRow(["createdAt", "Timestamp", "Waktu registrasi akun"], [2600, 1800, 4960], false),
          dataRow(["fcmToken", "String", "Token Firebase Cloud Messaging untuk push notifikasi"], [2600, 1800, 4960], true),
          dataRow(["searchRadius", "Number", "Radius pencarian pekerjaan dalam kilometer (khusus penyedia)"], [2600, 1800, 4960], false),
        ]
      }),
      spacer(),

      h2("7.2 Koleksi tasks"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2600, 1800, 4960],
        rows: [
          headerRow(["Field", "Tipe Data", "Keterangan"], [2600, 1800, 4960]),
          dataRow(["taskId", "String (PK)", "ID unik dokumen (auto-generated Firestore)"], [2600, 1800, 4960], false),
          dataRow(["requesterId", "String (FK)", "UID pengguna yang memposting pekerjaan"], [2600, 1800, 4960], true),
          dataRow(["title", "String", "Judul singkat pekerjaan (maks. 100 karakter)"], [2600, 1800, 4960], false),
          dataRow(["description", "String", "Deskripsi lengkap pekerjaan (maks. 500 karakter)"], [2600, 1800, 4960], true),
          dataRow(["category", "String", "Kategori pekerjaan (mis. angkat barang, menemani, dll.)"], [2600, 1800, 4960], false),
          dataRow(["offeredPrice", "Number", "Tarif yang ditawarkan oleh Pemohon (dalam Rupiah)"], [2600, 1800, 4960], true),
          dataRow(["estimatedDuration", "Number", "Estimasi durasi pekerjaan (dalam menit)"], [2600, 1800, 4960], false),
          dataRow(["location", "GeoPoint", "Koordinat GPS lokasi pekerjaan (latitude, longitude)"], [2600, 1800, 4960], true),
          dataRow(["locationAddress", "String", "Alamat lokasi dalam format teks (hasil geocoding)"], [2600, 1800, 4960], false),
          dataRow(["status", "String", "Status: 'open', 'in_progress', 'completed', 'cancelled'"], [2600, 1800, 4960], true),
          dataRow(["providerId", "String (FK)", "UID Penyedia Jasa yang mengambil pekerjaan (null jika Open)"], [2600, 1800, 4960], false),
          dataRow(["createdAt", "Timestamp", "Waktu pekerjaan diposting"], [2600, 1800, 4960], true),
          dataRow(["updatedAt", "Timestamp", "Waktu terakhir status pekerjaan diperbarui"], [2600, 1800, 4960], false),
        ]
      }),
      spacer(),

      h2("7.3 Koleksi ratings"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [2600, 1800, 4960],
        rows: [
          headerRow(["Field", "Tipe Data", "Keterangan"], [2600, 1800, 4960]),
          dataRow(["ratingId", "String (PK)", "ID unik dokumen rating"], [2600, 1800, 4960], false),
          dataRow(["taskId", "String (FK)", "ID pekerjaan yang menjadi dasar rating ini"], [2600, 1800, 4960], true),
          dataRow(["raterId", "String (FK)", "UID pengguna yang memberikan rating"], [2600, 1800, 4960], false),
          dataRow(["ratedUserId", "String (FK)", "UID pengguna yang menerima rating"], [2600, 1800, 4960], true),
          dataRow(["score", "Number", "Nilai rating (1 – 5 bintang)"], [2600, 1800, 4960], false),
          dataRow(["review", "String", "Teks ulasan opsional (maks. 300 karakter)"], [2600, 1800, 4960], true),
          dataRow(["createdAt", "Timestamp", "Waktu rating diberikan"], [2600, 1800, 4960], false),
        ]
      }),
      spacer(),
      pageBreak(),

      // ══════════════════════════════════════════════════════════
      // BAB 8 — RIWAYAT REVISI
      // ══════════════════════════════════════════════════════════
      h1("8. Riwayat Revisi Dokumen"),
      spacer(0),
      new Table({
        width: { size: 9360, type: WidthType.DXA },
        columnWidths: [1200, 1800, 2800, 3560],
        rows: [
          headerRow(["Versi", "Tanggal", "Penulis", "Keterangan Perubahan"], [1200, 1800, 2800, 3560]),
          dataRow(["1.0", "2025", "[Nama Penulis]", "Dokumen awal SRS — seluruh bagian dibuat pertama kali"], [1200, 1800, 2800, 3560], false),
          dataRow(["1.1", "-", "[Nama Penulis]", "Revisi berdasarkan masukan pembimbing pertama"], [1200, 1800, 2800, 3560], true),
          dataRow(["1.2", "-", "[Nama Penulis]", "Revisi setelah seminar proposal"], [1200, 1800, 2800, 3560], false),
        ]
      }),
      spacer(2),

      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 160, after: 80 },
        children: [new TextRun({ text: "— Akhir Dokumen SRS LineWork v1.0 —", font: "Arial", size: 20, italics: true, color: "999999" })]
      }),
    ]
  }]
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('SRS_LineWork_v1.0.docx', buffer);
  console.log("SRS document generated successfully.");
});