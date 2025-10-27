#!/bin/bash

echo "🚀 Compilando PerfBeta..."
echo ""

cd /Users/juanrafernandez/Documents/GitHub/MyFragance

# Usar xcodebuild de Xcode completo
XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"

# Limpiar build anterior
echo "🧹 Limpiando build anterior..."
$XCODEBUILD -project PerfBeta.xcodeproj -scheme PerfBeta -configuration Debug clean > /dev/null 2>&1

# Compilar
echo "🔨 Compilando proyecto..."
echo "   (Esto puede tardar 1-2 minutos)"
echo ""

$XCODEBUILD \
    -project PerfBeta.xcodeproj \
    -scheme PerfBeta \
    -configuration Debug \
    -sdk iphonesimulator \
    build \
    2>&1 | tee /tmp/build_output.log

# Verificar resultado
echo ""
echo "================================"

if grep -q "BUILD SUCCEEDED" /tmp/build_output.log; then
    echo "✅ ¡COMPILACIÓN EXITOSA!"
    echo "================================"
    echo ""
    echo "El proyecto compiló sin errores."
    echo ""
    echo "📱 Para ejecutar:"
    echo "   1. Abre Xcode: open PerfBeta.xcodeproj"
    echo "   2. Presiona ⌘+R"
    echo "   3. Ve a la tab 'Ajustes'"
    exit 0
else
    echo "❌ COMPILACIÓN FALLIDA"
    echo "================================"
    echo ""
    echo "Errores encontrados:"
    grep "error:" /tmp/build_output.log | head -15
    echo ""
    echo "Advertencias:"
    grep "warning:" /tmp/build_output.log | head -10
    echo ""
    echo "📄 Log completo en: /tmp/build_output.log"
    exit 1
fi
