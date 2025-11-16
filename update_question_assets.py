#!/usr/bin/env python3
"""
Script para actualizar los image_assets de las nuevas preguntas
para usar assets existentes en el proyecto
"""

import json
import requests
from datetime import datetime
import plistlib
import os

# Leer configuración de Firebase del plist
script_dir = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(script_dir, 'PerfBeta', 'GoogleService-Info.plist'), 'rb') as f:
    plist = plistlib.load(f)

PROJECT_ID = plist['PROJECT_ID']
API_KEY = plist['API_KEY']

print(f"🔥 Conectando a Firebase proyecto: {PROJECT_ID}\n")

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# Mapeo de assets antiguos a existentes
asset_mapping = {
    # profile_00_classification (Nivel de Experiencia)
    "experience_beginner": "personality_relaxed",
    "experience_intermediate": "personality_confident",
    "experience_expert": "personality_elegant",

    # profile_A1_simple_preference (Aromas Cotidianos)
    "scent_coffee": "family_gourmand",
    "scent_clean": "family_aquatic",
    "scent_flowers": "family_floral",
    "scent_bakery": "family_gourmand",
    "scent_ocean": "family_aquatic",
    "scent_forest": "family_woody",

    # profile_A2_time_preference (Momento de Uso)
    "time_morning": "occasion_sports",
    "time_work": "occasion_office",
    "time_night": "occasion_nights",
    "time_weekend": "occasion_social_events",

    # profile_A3_desired_feeling (Sensación Deseada)
    "feeling_fresh": "family_aquatic",
    "feeling_elegant": "personality_elegant",
    "feeling_cozy": "family_gourmand",
    "feeling_mysterious": "personality_romantic",
    "feeling_natural": "green",

    # profile_A4_intensity_simple (Intensidad Preferida)
    "intensity_intimate": "intensity_low",
    "intensity_soft": "intensity_low",
    "intensity_moderate": "intensity_medium",
    "intensity_notable": "intensity_high",
}

# IDs de preguntas a actualizar
question_ids = [
    "profile_00_classification",
    "profile_A1_simple_preference",
    "profile_A2_time_preference",
    "profile_A3_desired_feeling",
    "profile_A4_intensity_simple",
]

def to_firestore_value(value):
    if value is None:
        return {"nullValue": None}
    elif isinstance(value, bool):
        return {"booleanValue": value}
    elif isinstance(value, int):
        return {"integerValue": str(value)}
    elif isinstance(value, float):
        return {"doubleValue": value}
    elif isinstance(value, str):
        return {"stringValue": value}
    elif isinstance(value, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in value]}}
    elif isinstance(value, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in value.items()}}}
    else:
        return {"stringValue": str(value)}

def from_firestore_value(value):
    if 'stringValue' in value:
        return value['stringValue']
    elif 'integerValue' in value:
        return int(value['integerValue'])
    elif 'booleanValue' in value:
        return value['booleanValue']
    elif 'doubleValue' in value:
        return value['doubleValue']
    elif 'arrayValue' in value:
        if 'values' in value['arrayValue']:
            return [from_firestore_value(v) for v in value['arrayValue']['values']]
        return []
    elif 'mapValue' in value:
        if 'fields' in value['mapValue']:
            return {k: from_firestore_value(v) for k, v in value['mapValue']['fields'].items()}
        return {}
    elif 'nullValue' in value:
        return None
    return value

# Actualizar cada pregunta
for question_id in question_ids:
    print(f"🔄 Actualizando pregunta: {question_id}")

    # Obtener la pregunta actual
    url = f"{base_url}/questions_es/{question_id}"

    try:
        response = requests.get(url, params={"key": API_KEY})

        if response.status_code != 200:
            print(f"❌ Error obteniendo {question_id}: {response.status_code}")
            continue

        doc = response.json()
        fields = doc.get('fields', {})

        # Convertir de formato Firestore a Python
        question = {k: from_firestore_value(v) for k, v in fields.items()}

        # Actualizar image_assets en las opciones
        updated = False
        for option in question.get('options', []):
            old_asset = option.get('image_asset', '')
            if old_asset in asset_mapping:
                new_asset = asset_mapping[old_asset]
                option['image_asset'] = new_asset
                updated = True
                print(f"  ✓ Actualizado: {old_asset} → {new_asset}")

        if not updated:
            print(f"  ⚠️  No se encontraron assets para actualizar")
            continue

        # Actualizar timestamp
        now = datetime.utcnow().isoformat() + "Z"
        question['updatedAt'] = now

        # Convertir de vuelta a formato Firestore
        firestore_doc = {
            "fields": {k: to_firestore_value(v) for k, v in question.items()}
        }

        # Actualizar en Firebase
        response = requests.patch(
            url,
            json=firestore_doc,
            params={"key": API_KEY}
        )

        if response.status_code in [200, 201]:
            print(f"✅ Pregunta {question_id} actualizada correctamente\n")
        else:
            print(f"❌ Error actualizando {question_id}: {response.status_code}\n")

    except Exception as e:
        print(f"❌ Error procesando {question_id}: {str(e)}\n")

print("\n✨ Proceso completado!")
print("🎨 Los assets han sido actualizados para usar imágenes existentes")
print("📱 La app ahora cargará correctamente las nuevas preguntas con imágenes")
