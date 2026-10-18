#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/bin"
mkdir -p "$OUT_DIR"

TMP_BUILD="$(mktemp -d /dev/shm/.gr_build_XXXXXX 2>/dev/null || mktemp -d /tmp/.gr_build_XXXXXX)"
trap 'rm -rf "$TMP_BUILD"' EXIT

tar -czf "$TMP_BUILD/bundle.tar.gz" -C "$ROOT_DIR" scripts/guidelines.sh scripts/install.sh scripts/rules templates/AGENTS.md

python3 - "$TMP_BUILD/bundle.tar.gz" "$TMP_BUILD/payload.h" << 'PYEOF'
import sys
data = open(sys.argv[1], "rb").read()
enc = [str(b ^ ((0x5A + (i * 31)) & 0xFF)) for i, b in enumerate(data)]
with open(sys.argv[2], "w") as f:
    f.write(f"static const unsigned char PAYLOAD[] = {{{','.join(enc)}}};\n")
    f.write(f"static const unsigned int PAYLOAD_LEN = {len(data)};\n")
PYEOF

cat << 'CEOF' > "$TMP_BUILD/runner.c"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include "payload.h"

static void cleanup(const char *dir) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "rm -rf '%s'", dir);
    int r = system(cmd);
    (void)r;
}

int main(int argc, char **argv) {
    char shm_tpl[] = "/dev/shm/.gr_rt_XXXXXX";
    char tmp_tpl[] = "/tmp/.gr_rt_XXXXXX";
    char *work_dir = mkdtemp(shm_tpl);
    if (!work_dir) work_dir = mkdtemp(tmp_tpl);
    if (!work_dir) return 1;
    chmod(work_dir, 0700);

    char tar_path[512];
    snprintf(tar_path, sizeof(tar_path), "%s/b.tgz", work_dir);
    FILE *fp = fopen(tar_path, "wb");
    if (!fp) { cleanup(work_dir); return 1; }
    for (unsigned int i = 0; i < PAYLOAD_LEN; i++) {
        unsigned char b = PAYLOAD[i] ^ ((0x5A + (i * 31)) & 0xFF);
        fputc(b, fp);
    }
    fclose(fp);

    char extract_cmd[2048];
    snprintf(extract_cmd, sizeof(extract_cmd), "tar -xzf '%s' -C '%s' && rm -f '%s'", tar_path, work_dir, tar_path);
    if (system(extract_cmd) != 0) { cleanup(work_dir); return 1; }

    pid_t pid = fork();
    if (pid == 0) {
        char script_path[512];
        snprintf(script_path, sizeof(script_path), "%s/scripts/guidelines.sh", work_dir);
        char **new_argv = calloc((size_t)argc + 2, sizeof(char *));
        new_argv[0] = "bash";
        new_argv[1] = script_path;
        for (int i = 1; i < argc; i++) new_argv[i + 1] = argv[i];
        new_argv[argc + 1] = NULL;
        setenv("GUIDE_RULES_RUNTIME", work_dir, 1);
        execvp("bash", new_argv);
        _exit(127);
    }
    int status = 0;
    waitpid(pid, &status, 0);
    cleanup(work_dir);
    return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
CEOF

gcc -O2 -s -I"$TMP_BUILD" "$TMP_BUILD/runner.c" -o "$OUT_DIR/guidelines"
chmod 755 "$OUT_DIR/guidelines"
echo "==> [BUILD] Compiled encrypted ELF binary: $OUT_DIR/guidelines ($(du -h "$OUT_DIR/guidelines" | awk '{print $1}'))"
