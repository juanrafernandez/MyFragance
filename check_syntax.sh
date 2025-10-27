#!/bin/bash

echo "🔍 Verificando sintaxis de los archivos Swift nuevos..."
echo ""

FILES=(
    "PerfBeta/Views/SettingsTab/Components/SettingsRowView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsSectionView.swift"
    "PerfBeta/Views/SettingsTab/Components/SettingsHeaderView.swift"
    "PerfBeta/Views/SettingsTab/Components/EditProfileView.swift"
    "PerfBeta/Views/SettingsTab/SettingsViewNew.swift"
)

ALL_OK=true

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ No existe: $file"
        ALL_OK=false
        continue
    fi
    
    # Verificar que el archivo tenga contenido
    if [ ! -s "$file" ]; then
        echo "❌ Archivo vacío: $file"
        ALL_OK=false
        continue
    fi
    
    # Verificar sintaxis básica (imports, struct/class, etc)
    if ! grep -q "import SwiftUI" "$file"; then
        echo "⚠️  Sin 'import SwiftUI': $file"
    fi
    
    if grep -q "struct\|class\|enum" "$file"; then
        echo "✅ $file"
    else
        echo "❌ Sin struct/class: $file"
        ALL_OK=false
    fi
done

echo ""
if [ "$ALL_OK" = true ]; then
    echo "✅ Todos los archivos tienen sintaxis básica correcta"
    exit 0
else
    echo "❌ Algunos archivos tienen problemas"
    exit 1
fi
