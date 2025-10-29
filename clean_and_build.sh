#!/bin/bash

echo "🧹 Limpiando y reinstalando PerfBeta..."

# 1. Limpiar build
echo "🗑️  Limpiando build folder..."
cd /Users/juanrafernandez/Documents/GitHub/MyFragance
rm -rf ~/Library/Developer/Xcode/DerivedData/PerfBeta-*

# 2. Encontrar el simulador iPhone 16 Pro
echo "📱 Detectando simulador..."
SIMULATOR_UDID="E5A04791-5468-459B-BE72-E8429D6301A8"

# 3. Desinstalar la app del simulador
echo "🗑️  Desinstalando app del simulador..."
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl uninstall "$SIMULATOR_UDID" com.testjr.perfBeta 2>/dev/null || echo "   App no estaba instalada"

# 4. Boot simulator si no está running
echo "🔌 Iniciando simulador..."
/Applications/Xcode.app/Contents/Developer/usr/bin/simctl boot "$SIMULATOR_UDID" 2>/dev/null || echo "   Simulador ya estaba iniciado"

# 5. Esperar a que el simulador esté listo
echo "⏳ Esperando a que el simulador esté listo..."
sleep 3

echo "✅ Limpieza completada!"
echo ""
echo "📋 Próximos pasos:"
echo "1. Abre Xcode"
echo "2. Product → Clean Build Folder (⌘+Shift+K)"
echo "3. Product → Build (⌘+B)"
echo "4. Product → Run (⌘+R)"
echo ""
echo "Esto instalará la app con cache limpia."
