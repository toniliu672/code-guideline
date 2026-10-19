# Panduan Testing: Data Flow & End-User Flow Testing

Repositori ini menyediakan standarisasi pengujian otomatis (*automated testing*) yang dibagi menjadi dua tingkat pengujian utama:

---

## 1. Tipe 1: Data Flow & Business Logic Testing (Unit / Integration Test)

### Tujuan
Menguji kebenaran alur pemrosesan data di lapisan **Service Layer** dan **Repository Layer** tanpa harus melewati antarmuka HTTP/browser.

### Tanggung Jawab Pengujian
- Memastikan kalkulasi dan manipulasi data di `Service` berjalan akurat.
- Memastikan integritas data di database melalui asersi data (`assertDatabaseHas`, `assertDatabaseMissing`).
- Memastikan transaksi database di-*rollback* jika terjadi kegagalan (`DB::rollBack()`).
- Menguji isolasi penyimpanan berkas (`Storage::fake('private')`).

### Contoh Implementasi (Laravel Service Test):
```php
namespace Tests\Unit\Services;

use Tests\TestCase;
use App\Models\User;
use App\Services\DocumentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class DocumentServiceTest extends TestCase
{
    use RefreshDatabase;

    private DocumentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = app(DocumentService::class);
        Storage::fake('private');
    }

    public function test_data_flow_berhasil_menyimpan_dokumen_ke_db_dan_disk(): void
    {
        $user = User::factory()->create();
        $file = UploadedFile::fake()->create('laporan.pdf', 300, 'application/pdf');

        $doc = $this->service->createDocument($user->id, [
            'title' => 'Laporan Tahunan',
            'file' => $file,
            'category' => 'annual'
        ]);

        $this->assertDatabaseHas('documents', [
            'id' => $doc->id,
            'user_id' => $user->id,
            'title' => 'Laporan Tahunan',
            'status' => 'pending'
        ]);

        Storage::disk('private')->assertExists($doc->file_path);
    }
}
```

---

## 2. Tipe 2: End-User Frontend Flow Testing (Feature / HTTP Simulation Test)

### Tujuan
Mensimulasikan seluruh tahapan perjalanan pengguna nyata (*end-user journey*) dari sisi frontend/HTTP.

### Tanggung Jawab Pengujian
- Mensimulasikan pengguna terautentikasi (`$this->actingAs($user)`).
- Mengakses rute HTTP (`GET`, `POST`, `PUT`, `DELETE`).
- Memverifikasi tampilan UI Blade/komponen (`assertSeeText`, `assertDontSeeText`).
- Memverifikasi alur validasi form dan pesan error (`assertSessionHasErrors`).
- Memverifikasi pengalihan halaman (*redirect*) dan notifikasi pesan sukses (*flash message*).

### Contoh Implementasi (Laravel Feature User Flow):
```php
namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

class DocumentUserFlowTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_dapat_melihat_form_submit_dan_melihat_hasil_di_ui(): void
    {
        Storage::fake('private');
        $user = User::factory()->create();

        // 1. User membuka form upload (UI Check)
        $formPage = $this->actingAs($user)->get(route('documents.create'));
        $formPage->assertStatus(200);
        $formPage->assertSeeText('Upload Dokumen');

        // 2. User mengisi form & submit
        $file = UploadedFile::fake()->create('berkas.pdf', 250, 'application/pdf');
        $submit = $this->actingAs($user)->post(route('documents.store'), [
            'title' => 'Dokumen Legalitas',
            'file' => $file,
            'category' => 'legal'
        ]);

        // 3. Verifikasi redirect & flash message
        $submit->assertRedirect(route('documents.index'));
        $submit->assertSessionHas('success', 'Dokumen berhasil diunggah.');

        // 4. User melihat dokumen baru di tabel/list daftar dokumen
        $listPage = $this->actingAs($user)->get(route('documents.index'));
        $listPage->assertSeeText('Dokumen Legalitas');
    }

    public function test_user_melihat_pesan_validasi_jika_input_kosong(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post(route('documents.store'), []);

        $response->assertSessionHasErrors(['title', 'file']);
    }
}
```

---

## 3. Tipe 3: Performance & Load Testing dengan Grafana k6 (Simulasi Beban Konkurensi End-User)

### Tujuan
Menguji ketahanan sistem saat diserbu oleh puluhan hingga ribuan pengguna nyata secara bersamaan (*concurrent virtual users*). Memastikan SLO (Service Level Objective), latensi respon (*response time*), dan batas ambang kegagalan (*failure rate*).

### Tanggung Jawab Pengujian
- Menguji *concurrency spike* (misal saat pendaftaran serentak dibuka).
- Menetapkan ambang batas performa (*Thresholds*), misal 95% request harus selesai di bawah 500ms (`p(95) < 500ms`).
- Memastikan rasio error di bawah 1% (`http_req_failed < 0.01`).
- Memverifikasi respon halaman tetap valid di bawah beban berat.

### Contoh Implementasi Script k6 (`tests/k6/load-test.js`):
```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

// 1. Konfigurasi Beban Virtual Users & Ambang Batas (SLO)
export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up ke 20 pengguna dalam 30 detik
    { duration: '1m',  target: 50 },  // Naik ke 50 pengguna konstan selama 1 menit
    { duration: '20s', target: 0 },   // Ramp-down ke 0
  ],
  thresholds: {
    // 95% permintaan harus direspon di bawah 500ms
    http_req_duration: ['p(95)<500'],
    // Tingkat kegagalan request harus kurang dari 1%
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';

export default function () {
  // Langkah 1: User mengunjungi halaman utama / landing page
  const resHome = http.get(`${BASE_URL}/`);
  check(resHome, {
    'landing page status 200': (r) => r.status === 200,
    'landing page response time < 400ms': (r) => r.timings.duration < 400,
  });

  sleep(1);

  // Langkah 2: User mengunjungi halaman dokumen publik
  const resDocs = http.get(`${BASE_URL}/documents`);
  check(resDocs, {
    'documents page status 200': (r) => r.status === 200,
    'contains document keyword': (r) => r.body.includes('Dokumen'),
  });

  sleep(2);
}
```

### Menjalankan Test k6:
```bash
# Menjalankan uji beban lokal (1 virtual user smoke test):
k6 run --vus 1 --duration 5s tests/k6/load-test.js

# Menjalankan load test dengan target URL produksi/staging:
k6 run -e BASE_URL=https://staging.permikomnas.or.id tests/k6/load-test.js
```

---

## 4. Eksekusi Audit Testing Melalui Guidelines

Jalankan test suite menggunakan perintah:
```bash
# Menjalankan modul testing (Unit, Feature, & k6):
guidelines test
# atau dengan RTK:
rtk guidelines test

# Menjalankan seluruh audit termasuk testing:
guidelines all
```
