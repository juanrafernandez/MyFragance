#!/bin/bash

echo "🚀 ============================================"
echo "   VERIFICACIÓN DE COMPILACIÓN - PerfBeta"
echo "============================================"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "PerfBeta.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: No se encontró PerfBeta.xcodeproj"
    echo "   Ejecuta este script desde: /Users/juanrafernandez/Documents/GitHub/MyFragance/"
    exit 1
fi

echo "📂 Directorio correcto: $(pwd)"
echo ""

# Verificar que los archivos existan
echo "📋 Verificando archivos..."
FILES=(
    "PerfBeta/Views/SettingsTab/Components/SettingsRowView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsSectionView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsHeaderView.swift"
    "PerfBeta/Views/SettingsTab/Components/EditProfileView.swift"
    "PerfBeta/Views/SettingsTab/SettingsViewNew.swift"
)

ALL_FILES_EXIST=true
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ FALTA: $file"
        ALL_FILES_EXIST=false
    fi
done
echo ""

if [ "$ALL_FILES_EXIST" = false ]; then
    echo "❌ Faltan archivos. No se puede continuar."
    exit 1
fi

# Verificar que los archivos estén en el proyecto
echo "🔍 Verificando si los archivos están en el proyecto Xcode..."
FILES_IN_PROJECT=$(grep -c "SettingsViewNew.swift\|SettingsRowView.swift\|SettingsSectionView.swift\|SettingsHeaderView.swift\|EditProfileView.swift" PerfBeta.xcodeproj/project.pbxproj)

if [ "$FILES_IN_PROJECT" -eq 0 ]; then
    echo "   ⚠️  Los archivos NO están agregados al proyecto Xcode"
    echo ""
    echo "   Por favor, sigue las instrucciones en:"
    echo "   📄 AGREGAR_ARCHIVOS_PASO_A_PASO.md"
    echo ""
    echo "   Luego ejecuta este script de nuevo."
    exit 1
else
    echo "   ✅ Archivos encontrados en el proyecto ($FILES_IN_PROJECT referencias)"
fi
echo ""

# Verificar Xcode path
echo "🔧 Verificando herramientas de compilación..."
if command -v xcodebuild &> /dev/null; then
    XCODE_PATH=$(xcode-select -p 2>/dev/null)
    echo "   ✅ xcodebuild encontrado"
    echo "   📍 Xcode path: $XCODE_PATH"
else
    echo "   ⚠️  xcodebuild no disponible (usando Command Line Tools)"
    echo "   💡 La compilación debe hacerse desde Xcode GUI"
    echo ""
    echo "   Para compilar:"
    echo "   1. Abre Xcode: open PerfBeta.xcodeproj"
    echo "   2. Presiona ⌘+B para compilar"
    echo "   3. Presiona ⌘+R para ejecutar"
    exit 0
fi
echo ""

# Intentar compilar
echo "🔨 Intentando compilar el proyecto..."
echo "   (Esto puede tardar 30-60 segundos)"
echo ""

xcodebuild \
    -project PerfBeta.xcodeproj \
    -scheme PerfBeta \
    -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    clean build \
    2>&1 | tee /tmp/xcodebuild.log | grep --line-buffered -E "(error:|warning:|Build succeeded|BUILD FAILED|Compiling|Linking)" | head -50

# Verificar resultado
if grep -q "BUILD SUCCEEDED" /tmp/xcodebuild.log; then
    echo ""
    echo "✅ ============================================"
    echo "   ¡COMPILACIÓN EXITOSA!"
    echo "============================================"
    echo ""
    echo "🎉 El proyecto compila correctamente"
    echo ""
    echo "📱 Para ejecutar la app:"
    echo "   1. Abre Xcode: open PerfBeta.xcodeproj"
    echo "   2. Presiona ⌘+R"
    echo "   3. Ve a la tab 'Ajustes' ⚙️"
    echo ""
    echo "📊 Log completo en: /tmp/xcodebuild.log"
    exit 0
elif grep -q "BUILD FAILED" /tmp/xcodebuild.log; then
    echo ""
    echo "❌ ============================================"
    echo "   COMPILACIÓN FALLIDA"
    echo "============================================"
    echo ""
    echo "🔍 Errores encontrados:"
    grep "error:" /tmp/xcodebuild.log | head -10
    echo ""
    echo "📊 Log completo en: /tmp/xcodebuild.log"
    echo ""
    echo "💡 Soluciones comunes:"
    echo "   1. Verifica que todos los archivos estén en Xcode (azules, no rojos)"
    echo "   2. Limpia el build: Product > Clean Build Folder (⌘+Shift+K)"
    echo "   3. Verifica que DesignTokens.swift esté en el proyecto"
    echo "   4. Verifica que GradientBackgroundView.swift esté en el proyecto"
    exit 1
else
    echo ""
    echo "⚠️  No se pudo determinar el resultado de la compilación"
    echo "📊 Revisa el log en: /tmp/xcodebuild.log"
    exit 1
fi
