#!/usr/bin/env bash
set -euo pipefail

RULES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/rules"
CFG_FILE="$RULES_DIR/config.env"
BLUE='\033[0;34m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}   INTERACTIVE GUIDELINES & ARCHITECTURE SETUP WIZARD           ${NC}"
echo -e "${BLUE}================================================================${NC}"

echo -e "\n${CYAN}1. Pilih Framework / Stack Utama:${NC}"
echo "   1) auto (Default)  2) blade (Laravel)  3) react  4) next  5) svelte  6) flutter  7) none (API)"
read -rp "   Pilihan [1-7, default: 1]: " c_fw
case "${c_fw:-1}" in
    2) FW="blade" ;; 3) FW="react" ;; 4) FW="next" ;; 5) FW="svelte" ;; 6) FW="flutter" ;; 7) FW="none" ;; *) FW="auto" ;;
esac

echo -e "\n${CYAN}2. Pilih Arsitektur Komponen UI:${NC}"
echo "   1) auto (Default)  2) standard (components/ + layouts/)  3) admin-separated  4) atomic (Brad Frost)"
read -rp "   Pilihan [1-4, default: 1]: " c_comp
case "${c_comp:-1}" in
    2) COMP="standard" ;; 3) COMP="admin-separated" ;; 4) COMP="atomic" ;; *) COMP="auto" ;;
esac

echo -e "\n${CYAN}3. Pilih Tingkat Keketatan Tag HTML di Page Views (Strictness Level):${NC}"
echo "   1) standard (blokir form/tombol)  2) moderate (blokir form, table, svg)  3) strict (pure <x-...>)"
read -rp "   Pilihan [1-3, default: 2]: " c_lvl
case "${c_lvl:-2}" in
    1) LVL="standard" ;; 3) LVL="strict" ;; *) LVL="moderate" ;;
esac

echo -e "\n${CYAN}4. Pilih Pola Arsitektur Backend:${NC}"
echo "   1) auto (Default)  2) mvc  3) service-layer  4) modular  5) microservices"
read -rp "   Pilihan [1-5, default: 1]: " c_arch
case "${c_arch:-1}" in
    2) ARCH="mvc" ;; 3) ARCH="service-layer" ;; 4) ARCH="modular" ;; 5) ARCH="microservices" ;; *) ARCH="auto" ;;
esac

echo -e "\n${CYAN}5. Apakah Menggunakan RTK (Rust Token Killer)?${NC}"
echo "   1) auto (Default)  2) yes (rtk guidelines)  3) no (guidelines biasa)"
read -rp "   Pilihan [1-3, default: 1]: " c_rtk
case "${c_rtk:-1}" in
    2) RTK="yes" ;; 3) RTK="no" ;; *) RTK="auto" ;;
esac

echo -e "\n${CYAN}6. Pilih Linter & Static Analysis:${NC}"
echo "   1) auto  2) php-laravel (Pint/PHPStan)  3) js-ts (ESLint/tsc)  4) svelte  5) flutter  6) syntax-only  7) none"
read -rp "   Pilihan [1-7, default: 1]: " c_lint
case "${c_lint:-1}" in
    2) LINT="php-laravel" ;; 3) LINT="js-ts" ;; 4) LINT="svelte" ;; 5) LINT="flutter" ;; 6) LINT="syntax-only" ;; 7) LINT="none" ;; *) LINT="auto" ;;
esac

sel_1=1; sel_2=1; sel_3=0; sel_4=0
while true; do
    echo -e "\n${CYAN}7. Checklist Metode Pengujian (Ketik 1-4 untuk toggle centang, Enter jika selesai):${NC}"
    [ "$sel_1" -eq 1 ] && echo -e "   ${GREEN}[*]${NC} 1. Laravel Pest / PHPUnit (Data Flow & End-User Flow)" || echo "   [ ] 1. Laravel Pest / PHPUnit (Data Flow & End-User Flow)"
    [ "$sel_2" -eq 1 ] && echo -e "   ${GREEN}[*]${NC} 2. Grafana k6 (Performance & Load Testing) [Universal Semua Stack]" || echo "   [ ] 2. Grafana k6 (Performance & Load Testing) [Universal Semua Stack]"
    [ "$sel_3" -eq 1 ] && echo -e "   ${GREEN}[*]${NC} 3. Frontend JS/TS Test (Vitest / Playwright / Jest)" || echo "   [ ] 3. Frontend JS/TS Test (Vitest / Playwright / Jest)"
    [ "$sel_4" -eq 1 ] && echo -e "   ${GREEN}[*]${NC} 4. Flutter Test (Dart / Widget Test)" || echo "   [ ] 4. Flutter Test (Dart / Widget Test)"
    read -rp "   Toggle nomor [1-4], atau tekan Enter jika selesai: " pick
    [ -z "$pick" ] && break
    [[ "$pick" =~ 1 ]] && sel_1=$((1 - sel_1))
    [[ "$pick" =~ 2 ]] && sel_2=$((1 - sel_2))
    [[ "$pick" =~ 3 ]] && sel_3=$((1 - sel_3))
    [[ "$pick" =~ 4 ]] && sel_4=$((1 - sel_4))
done

TEST_SUITES=""
[ "$sel_1" -eq 1 ] && TEST_SUITES="${TEST_SUITES}laravel,"
[ "$sel_2" -eq 1 ] && TEST_SUITES="${TEST_SUITES}k6,"
[ "$sel_3" -eq 1 ] && TEST_SUITES="${TEST_SUITES}frontend,"
[ "$sel_4" -eq 1 ] && TEST_SUITES="${TEST_SUITES}flutter,"
TEST_SUITES="${TEST_SUITES%,}"
[ -z "$TEST_SUITES" ] && TEST_SUITES="none"

cat << EOF > "$CFG_FILE"
ENABLE_CORE=true; MAX_LINES=100; MAX_LAYOUT_LINES=250; STRICT_LINES=true
LINE_EXCLUDES="database/migrations|database/seeders|config/"
FRONTEND_APPROACH="$FW"; BLADE_APPROACH="$COMP"; STRICTNESS_LEVEL="$LVL"
ARCHITECTURE_APPROACH="$ARCH"; USE_RTK="$RTK"; LINTER_TOOL="$LINT"; TEST_SUITES="$TEST_SUITES"
CHECK_COLOR_TOKENS=true; CHECK_TRAIN_TRACK=true; CHECK_CLASS_CONFLICTS=true
CHECK_CANONICAL_CLASSES=true; MAX_CLASS_CHARS=100; MAX_CLASS_WORDS=10; ENABLE_SECURITY=true
EOF

echo -e "\n${GREEN}[OK]${NC} Konfigurasi tersimpan: FW=$FW | COMP=$COMP | LEVEL=$LVL | ARCH=$ARCH | RTK=$RTK | LINT=$LINT | TESTS=[$TEST_SUITES]"
