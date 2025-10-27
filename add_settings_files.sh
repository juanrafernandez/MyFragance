#!/bin/bash

# Script para agregar archivos de Settings al proyecto Xcode
# Ejecutar desde el directorio raíz del proyecto

echo "🚀 Agregando archivos de Settings al proyecto..."

# Verificar que estamos en el directorio correcto
if [ ! -f "PerfBeta.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: No se encontró PerfBeta.xcodeproj"
    echo "   Ejecuta este script desde el directorio raíz del proyecto"
    exit 1
fi

# Lista de archivos a agregar
FILES=(
    "PerfBeta/Views/SettingsTab/Components/SettingsRowView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsSectionView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsHeaderView.swift"
    "PerfBeta/Views/SettingsTab/Components/EditProfileView.swift"
    "PerfBeta/Views/SettingsTab/SettingsViewNew.swift"
)

echo ""
echo "📋 Archivos a agregar:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file (NO EXISTE)"
    fi
done

echo ""
echo "⚠️  INSTRUCCIONES MANUALES:"
echo ""
echo "No puedo modificar project.pbxproj automáticamente de forma segura."
echo "Por favor, sigue estos pasos en Xcode:"
echo ""
echo "1. Abre Xcode (ya debería estar abierto)"
echo "2. En el Project Navigator (panel izquierdo), haz clic derecho en:"
echo "   PerfBeta > Views > SettingsTab"
echo ""
echo "3. Selecciona 'New Group' y nómbralo 'Components'"
echo ""
echo "4. Haz clic derecho en la carpeta 'Components' recién creada"
echo "   Selecciona 'Add Files to PerfBeta...'"
echo ""
echo "5. Navega a: PerfBeta/Views/SettingsTab/Components/"
echo "   Selecciona TODOS estos archivos (Cmd+A):"
echo "   - SettingsRowView.swift"
echo "   - SettingsSectionView.swift"
echo "   - SettingsHeaderView.swift"
echo "   - EditProfileView.swift"
echo ""
echo "6. Asegúrate de marcar:"
echo "   ✅ 'Copy items if needed' (NO marcar, ya están en la ubicación correcta)"
echo "   ✅ 'Create groups' (seleccionado)"
echo "   ✅ 'Add to targets: PerfBeta' (marcado)"
echo ""
echo "7. Haz clic en 'Add'"
echo ""
echo "8. Ahora haz clic derecho en: PerfBeta > Views > SettingsTab"
echo "   Selecciona 'Add Files to PerfBeta...'"
echo ""
echo "9. Selecciona el archivo:"
echo "   - SettingsViewNew.swift"
echo ""
echo "10. Haz clic en 'Add'"
echo ""
echo "11. Verifica que todos los archivos aparezcan en el Project Navigator"
echo ""
echo "12. Presiona ⌘B para compilar"
echo ""
echo "✨ Alternativa más rápida:"
echo "   Simplemente arrastra los archivos desde Finder al Project Navigator"
echo "   en Xcode, asegurándote de marcar 'Add to targets: PerfBeta'"
echo ""
