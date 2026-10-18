#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rules"
CFG_FILE="$RULES_DIR/config.env"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   INTERACTIVE GUIDELINES & ARCHITECTURE SETUP WIZARD           ${NC}"
echo -e "${BLUE}================================================================${NC}"

echo -e "\n${CYAN}1. Pilih Framework / Stack Utama:${NC}"
echo "   1) auto    - Deteksi otomatis dari struktur proyek (Default)"
echo "   2) blade   - PHP Laravel (Blade Templates)"
echo "   3) react   - React.js (src/components)"
echo "   4) next    - Next.js (App / Pages Router)"
echo "   5) svelte  - Svelte / SvelteKit (\$lib/components)"
echo "   6) flutter - Dart / Flutter (lib/widgets)"
echo "   7) none    - Backend API Murni (Tanpa UI)"
read -rp "   Pilihan [1-7, default: 1]: " c_fw
case "${c_fw:-1}" in
    2) FW="blade" ;; 3) FW="react" ;; 4) FW="next" ;; 5) FW="svelte" ;; 6) FW="flutter" ;; 7) FW="none" ;; *) FW="auto" ;;
esac

echo -e "\n${CYAN}2. Pilih Arsitektur Komponen UI:${NC}"
echo "   1) auto            - Deteksi otomatis struktur folder komponen (Default)"
echo "   2) standard        - Component-Based Biasa"
echo "                        Contoh: resources/views/components/button.blade.php + layouts/app.blade.php"
echo "   3) admin-separated - Component-Based dengan Pemisahan Admin & Shared UI"
echo "                        Contoh: views/components/admin/stat-card.blade.php + views/components/navbar.blade.php"
echo "   4) atomic          - Strict Atomic Design (Brad Frost)"
echo "                        Contoh: views/components/atoms/button.blade.php + molecules/ + organisms/"
read -rp "   Pilihan [1-4, default: 1]: " c_comp
case "${c_comp:-1}" in
    2) COMP="standard" ;; 3) COMP="admin-separated" ;; 4) COMP="atomic" ;; *) COMP="auto" ;;
esac

echo -e "\n${CYAN}3. Pilih Tingkat Keketatan Tag HTML di Page Views (Strictness Level):${NC}"
echo "   1) standard - Hanya blokir form/tombol mentah (<input>, <select>, <textarea>, <button>)"
echo "   2) moderate - Blokir form, tombol, <table>, <svg>, dan tag HTML mentah berulang di dalam @foreach"
echo "   3) strict   - Blokir semua tag UI & teks mentah (<p>, <h1>..<h6>, <span>, <ul>, <table>) di Page Views"
read -rp "   Pilihan [1-3, default: 2]: " c_lvl
case "${c_lvl:-2}" in
    1) LVL="standard" ;; 3) LVL="strict" ;; *) LVL="moderate" ;;
esac

echo -e "\n${CYAN}4. Pilih Pola Arsitektur Backend:${NC}"
echo "   1) auto          - Deteksi otomatis (Default)"
echo "   2) mvc           - Model-View-Controller (Thin Controller, View bebas query DB)"
echo "   3) service-layer - Thin Controller + Service Layer (app/Services)"
echo "   4) modular       - Modular / Domain-Driven (Modules/ atau src/features/)"
echo "   5) microservices - Microservices (Dockerfile + /healthz)"
read -rp "   Pilihan [1-5, default: 1]: " c_arch
case "${c_arch:-1}" in
    2) ARCH="mvc" ;; 3) ARCH="service-layer" ;; 4) ARCH="modular" ;; 5) ARCH="microservices" ;; *) ARCH="auto" ;;
esac

echo -e "\n${CYAN}5. Apakah Menggunakan RTK (Rust Token Killer)?${NC}"
echo "   1) auto - Otomatis gunakan rtk jika terinstal (Default)"
echo "   2) yes  - Ya, wajib gunakan prefix 'rtk guidelines'"
echo "   3) no   - Tidak, gunakan perintah standar 'guidelines'"
read -rp "   Pilihan [1-3, default: 1]: " c_rtk
case "${c_rtk:-1}" in
    2) RTK="yes" ;; 3) RTK="no" ;; *) RTK="auto" ;;
esac

echo -e "\n${CYAN}6. Pilih Linter & Static Analysis yang Digunakan:${NC}"
echo "   1) auto        - Deteksi otomatis linter di proyek (Pint, PHPStan, ESLint, Svelte, Flutter)"
echo "   2) php-laravel - PHP Syntax (php -l) + Laravel Pint + PHPStan/Larastan"
echo "   3) js-ts       - ESLint + TypeScript (tsc --noEmit)"
echo "   4) svelte      - svelte-check + ESLint"
echo "   5) flutter     - flutter analyze / dart analyze"
echo "   6) syntax-only - Hanya cek syntax dasar (tanpa PHPStan/Pint/ESLint)"
echo "   7) none        - Matikan pemeriksaan linter"
read -rp "   Pilihan [1-7, default: 1]: " c_lint
case "${c_lint:-1}" in
    2) LINT="php-laravel" ;; 3) LINT="js-ts" ;; 4) LINT="svelte" ;; 5) LINT="flutter" ;; 6) LINT="syntax-only" ;; 7) LINT="none" ;; *) LINT="auto" ;;
esac

cat << EOF > "$CFG_FILE"
ENABLE_CORE=true; MAX_LINES=100; MAX_LAYOUT_LINES=250; STRICT_LINES=true
LINE_EXCLUDES="database/migrations|database/seeders|config/"
FRONTEND_APPROACH="$FW"; BLADE_APPROACH="$COMP"; STRICTNESS_LEVEL="$LVL"
ARCHITECTURE_APPROACH="$ARCH"; USE_RTK="$RTK"; LINTER_TOOL="$LINT"
CHECK_COLOR_TOKENS=true; CHECK_TRAIN_TRACK=true; CHECK_CLASS_CONFLICTS=true
CHECK_CANONICAL_CLASSES=true; MAX_CLASS_CHARS=100; MAX_CLASS_WORDS=10; ENABLE_SECURITY=true
EOF

echo -e "\n${GREEN}[OK]${NC} Konfigurasi berhasil disimpan: FW=$FW | COMP=$COMP | LEVEL=$LVL | ARCH=$ARCH | RTK=$RTK | LINT=$LINT"
