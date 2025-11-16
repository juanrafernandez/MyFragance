#!/usr/bin/env python3
"""
Script para añadir las nuevas preguntas de perfil olfativo a Firebase Firestore usando REST API
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

print(f"🔥 Conectando a Firebase proyecto: {PROJECT_ID}")

# Cargar preguntas desde el JSON
with open(os.path.join(script_dir, 'new_profile_questions.json'), 'r', encoding='utf-8') as f:
    questions = json.load(f)

print(f"📝 Total de preguntas a añadir: {len(questions)}\n")

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# Función para convertir datos a formato Firestore
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

# Añadir cada pregunta
for question in questions:
    question_id = question['id']
    print(f"📝 Añadiendo pregunta: {question_id}")

    # Añadir timestamps
    now = datetime.utcnow().isoformat() + "Z"
    question['createdAt'] = now
    question['updatedAt'] = now

    # Convertir a formato Firestore
    firestore_doc = {
        "fields": {k: to_firestore_value(v) for k, v in question.items()}
    }

    # URL para crear/actualizar el documento
    url = f"{base_url}/questions_es/{question_id}"

    try:
        # PATCH para crear o actualizar el documento
        response = requests.patch(
            url,
            json=firestore_doc,
            params={"key": API_KEY}
        )

        if response.status_code in [200, 201]:
            print(f"✅ Pregunta {question_id} añadida correctamente")
        else:
            print(f"❌ Error añadiendo {question_id}: {response.status_code}")
            print(f"   Respuesta: {response.text[:200]}")
    except Exception as e:
        print(f"❌ Error añadiendo {question_id}: {str(e)}")

print("\n✨ Proceso completado!")
print("🔄 Recuerda:")
print("   1. Incrementar la versión de caché en QuestionsService.swift")
print("   2. Ir a la app → Ajustes → Datos → Limpiar caché para cargar las nuevas preguntas")
