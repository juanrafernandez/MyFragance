#!/usr/bin/env python3
"""
Script para subir las nuevas preguntas ponderadas del camino B del perfil olfativo a Firebase
"""

import requests
import plistlib
import os
import json

# Leer configuración de Firebase del plist
script_dir = os.path.dirname(os.path.abspath(__file__))

with open(os.path.join(script_dir, 'PerfBeta', 'GoogleService-Info.plist'), 'rb') as f:
    plist = plistlib.load(f)

PROJECT_ID = plist['PROJECT_ID']
API_KEY = plist['API_KEY']

print(f"🔥 Subiendo preguntas ponderadas del Perfil B a Firebase proyecto: {PROJECT_ID}\n")

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def to_firestore_value(value):
    """Convierte valores Python a formato Firestore"""
    if isinstance(value, str):
        return {"stringValue": value}
    elif isinstance(value, int):
        return {"integerValue": value}
    elif isinstance(value, bool):
        return {"booleanValue": value}
    elif isinstance(value, float):
        return {"doubleValue": value}
    elif isinstance(value, list):
        return {"arrayValue": {"values": [to_firestore_value(v) for v in value]}}
    elif isinstance(value, dict):
        return {"mapValue": {"fields": {k: to_firestore_value(v) for k, v in value.items()}}}
    elif value is None:
        return {"nullValue": None}
    return value

# Leer las preguntas del archivo JSON
questions_file = os.path.join(script_dir, 'new_profile_B_weighted.json')
with open(questions_file, 'r', encoding='utf-8') as f:
    questions = json.load(f)

print(f"📝 Preguntas a subir: {len(questions)}\n")

# Subir cada pregunta a Firebase
for question in questions:
    question_id = question['id']

    # Convertir la pregunta a formato Firestore
    firestore_fields = {k: to_firestore_value(v) for k, v in question.items()}

    # Crear el documento en Firestore
    url = f"{base_url}/questions_es/{question_id}"

    payload = {
        "fields": firestore_fields
    }

    # Usar PATCH para crear o actualizar
    response = requests.patch(url, params={"key": API_KEY}, json=payload)

    if response.status_code in [200, 201]:
        print(f"✅ {question_id}")
        print(f"   Pregunta: {question['text']}")
        print(f"   Categoría: {question['category']}")
        print(f"   Peso: {question['weight']}")
        print(f"   Tipo: {question['questionType']}")

        # Mostrar info especial para autocomplete
        if question['questionType'] == 'autocomplete_multiple':
            print(f"   Max selecciones: {question.get('max_selections', 'N/A')}")
            print(f"   Data source: {question.get('data_source', 'N/A')}")
        else:
            print(f"   Opciones: {len(question.get('options', []))}")
    else:
        print(f"❌ Error al subir {question_id}: {response.status_code}")
        print(response.text[:200])

    print()

print("=" * 80)
print("🎉 Proceso de subida completado!")
print("=" * 80)

# Verificar que las preguntas se subieron correctamente
print("\n🔍 Verificando preguntas subidas...\n")

verify_url = f"{base_url}/questions_es"
response = requests.get(verify_url, params={"key": API_KEY})

if response.status_code == 200:
    data = response.json()
    if 'documents' in data:
        uploaded_questions = []
        for doc in data['documents']:
            fields = doc.get('fields', {})
            q_id = fields.get('id', {}).get('stringValue', '')
            if q_id.startswith('profile_B'):
                order = fields.get('order', {}).get('integerValue', 0)
                text = fields.get('text', {}).get('stringValue', '')
                weight = fields.get('weight', {}).get('integerValue', 0)
                uploaded_questions.append((int(order), q_id, text, weight))

        uploaded_questions.sort()
        print(f"✅ Preguntas del Profile B encontradas en Firebase: {len(uploaded_questions)}")
        for order, q_id, text, weight in uploaded_questions:
            print(f"{order}. {q_id} (peso: {weight})")
            print(f"   {text}\n")
    else:
        print("⚠️ No se encontraron documentos en la verificación")
else:
    print(f"⚠️ Error al verificar: {response.status_code}")

print("\n✨ Script completado!")
