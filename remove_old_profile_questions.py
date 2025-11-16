#!/usr/bin/env python3
"""
Script para eliminar las 7 preguntas antiguas del perfil olfativo de Firebase Firestore
Esto dejará solo las 6 nuevas preguntas con lenguaje cotidiano
"""

import requests
import plistlib
import os

# Leer configuración de Firebase del plist
script_dir = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(script_dir, 'PerfBeta', 'GoogleService-Info.plist'), 'rb') as f:
    plist = plistlib.load(f)

PROJECT_ID = plist['PROJECT_ID']
API_KEY = plist['API_KEY']

print(f"🔥 Conectando a Firebase proyecto: {PROJECT_ID}")

# IDs de las preguntas antiguas a eliminar (del 1 al 7)
old_question_ids = ["1", "2", "3", "4", "5", "6", "7"]

print(f"🗑️  Preparando para eliminar {len(old_question_ids)} preguntas antiguas\n")

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# Eliminar cada pregunta
for question_id in old_question_ids:
    print(f"🗑️  Eliminando pregunta: {question_id}")

    # URL para eliminar el documento
    url = f"{base_url}/questions_es/{question_id}"

    try:
        # DELETE request
        response = requests.delete(
            url,
            params={"key": API_KEY}
        )

        if response.status_code in [200, 204]:
            print(f"✅ Pregunta {question_id} eliminada correctamente")
        elif response.status_code == 404:
            print(f"⚠️  Pregunta {question_id} no encontrada (ya eliminada)")
        else:
            print(f"❌ Error eliminando {question_id}: {response.status_code}")
            print(f"   Respuesta: {response.text[:200]}")
    except Exception as e:
        print(f"❌ Error eliminando {question_id}: {str(e)}")

print("\n✨ Proceso completado!")
print("📊 Ahora solo quedan las 6 nuevas preguntas con lenguaje cotidiano:")
print("   - profile_00_classification (Nivel de Experiencia)")
print("   - profile_A1_simple_preference (Aromas Cotidianos)")
print("   - profile_A2_time_preference (Momento de Uso)")
print("   - profile_A3_desired_feeling (Sensación Deseada)")
print("   - profile_A4_intensity_simple (Intensidad Preferida)")
print("   - profile_A5_season_basic (Temporada Favorita)")
