#!/usr/bin/env bash
set -euo pipefail

ERRORS=0
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

echo "==> [ARCH-MICROSERVICES] Enforcing Microservices Architecture Standards..."

HAS_DOCKER=false
for f in "Dockerfile" "docker-compose.yml" "docker-compose.yaml" "compose.yaml" "Containerfile"; do
    [ -f "$f" ] && HAS_DOCKER=true
done

if [ "$HAS_DOCKER" = false ]; then
    echo -e "${RED}[FAIL]${NC} Microservice must include containerization configuration ('Dockerfile' or 'compose.yaml')!"
    ERRORS=$((ERRORS + 1))
fi

HAS_HEALTH_CHECK=false
for route_file in routes/api.php routes/web.php src/routes/*.ts src/app/api/health/route.ts server.js app.py main.go; do
    if [ -f "$route_file" ] && grep -qE "(/health|/healthz|/ping)" "$route_file" 2>/dev/null; then
        HAS_HEALTH_CHECK=true
        break
    fi
done

if [ "$HAS_HEALTH_CHECK" = false ]; then
    echo -e "${RED}[FAIL]${NC} Microservice must expose a Health Check endpoint (/health or /healthz) for orchestrators!"
    ERRORS=$((ERRORS + 1))
fi

if [ ! -f ".env.example" ] && [ ! -f "config.example.json" ]; then
    echo -e "${YELLOW}[WARNING]${NC} Microservice is recommended to maintain an independent .env.example."
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}[OK]${NC} Microservices architecture standards validated (Container & Health Probe verified)."
    exit 0
else
    echo -e "${RED}[ERROR]${NC} Found $ERRORS microservice architecture violation(s)!"
    exit 1
fi
