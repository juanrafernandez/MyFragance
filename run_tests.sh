#!/bin/bash

# 🧪 Script de Ejecución de Tests - PerfBeta
# Ejecuta los tests unitarios en el simulador

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo -e "${BLUE}🧪 PerfBeta - Test Runner${NC}"
echo "=================================="
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "PerfBeta.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Verificar que xcodebuild está disponible
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Error: xcodebuild no está disponible${NC}"
    echo "   Instala Xcode desde el App Store"
    exit 1
fi

# Función para ejecutar tests
run_tests() {
    local test_suite=$1
    local description=$2

    echo -e "${YELLOW}▶️  Ejecutando: ${description}${NC}"
    echo ""

    if [ -z "$test_suite" ]; then
        # Ejecutar todos los tests
        xcodebuild test \
            -scheme PerfBeta \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
            -only-testing:PerfBetaTests 2>&1 | \
            grep -E "(Test Case|Test Suite|TEST SUCCEEDED|TEST FAILED|passed|failed)" || true
    else
        # Ejecutar suite específica
        xcodebuild test \
            -scheme PerfBeta \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
            -only-testing:PerfBetaTests/$test_suite 2>&1 | \
            grep -E "(Test Case|Test Suite|TEST SUCCEEDED|TEST FAILED|passed|failed)" || true
    fi

    local exit_code=${PIPESTATUS[0]}

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ Tests pasaron correctamente${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Tests fallaron${NC}"
        return 1
    fi
}

# Menú de opciones
echo "Selecciona qué tests ejecutar:"
echo ""
echo "1) Todos los tests (24 tests - ~2 segundos)"
echo "2) CacheManagerTests (16 tests - ~1 segundo)"
echo "3) MetadataIndexManagerTests (8 tests - ~0.5 segundos)"
echo "4) Test único (verificación rápida)"
echo "5) Ver simuladores disponibles"
echo "6) Limpiar y ejecutar todos los tests"
echo ""
read -p "Opción (1-6): " option

case $option in
    1)
        echo ""
        run_tests "" "Todos los tests"
        ;;
    2)
        echo ""
        run_tests "CacheManagerTests" "CacheManager Tests"
        ;;
    3)
        echo ""
        run_tests "MetadataIndexManagerTests" "MetadataIndexManager Tests"
        ;;
    4)
        echo ""
        echo -e "${YELLOW}▶️  Ejecutando test de verificación rápida${NC}"
        xcodebuild test \
            -scheme PerfBeta \
            -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
            -only-testing:PerfBetaTests/CacheManagerTests/testSaveAndLoadSimpleModel 2>&1 | \
            grep -E "(Test Case|TEST SUCCEEDED|TEST FAILED)" || true

        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo ""
            echo -e "${GREEN}✅ Verificación exitosa - El sistema de tests funciona correctamente${NC}"
        else
            echo ""
            echo -e "${RED}❌ Verificación falló${NC}"
        fi
        ;;
    5)
        echo ""
        echo -e "${BLUE}📱 Simuladores disponibles:${NC}"
        echo ""
        xcrun simctl list devices available | grep -E "(iPhone|iPad)" | grep -v "unavailable"
        echo ""
        ;;
    6)
        echo ""
        echo -e "${YELLOW}🧹 Limpiando build cache...${NC}"
        xcodebuild clean -scheme PerfBeta
        echo ""
        echo -e "${GREEN}✅ Cache limpiado${NC}"
        echo ""
        run_tests "" "Todos los tests (después de limpiar)"
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo "=================================="
echo -e "${BLUE}✨ Ejecución completada${NC}"
echo ""
