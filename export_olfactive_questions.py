#!/usr/bin/env python3
"""
Script para exportar las preguntas del test olfativo desde Firebase Firestore
"""

import json
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

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

# URL para obtener todas las preguntas
collection_url = f"{base_url}/questions_es"

print(f"📝 Obteniendo preguntas del test olfativo...\n")

try:
    response = requests.get(
        collection_url,
        params={"key": API_KEY}
    )

    if response.status_code == 200:
        data = response.json()

        if 'documents' not in data:
            print("❌ No se encontraron preguntas")
            exit(1)

        # Convertir de formato Firestore a formato normal
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

        questions = []
        for doc in data['documents']:
            doc_id = doc['name'].split('/')[-1]
            fields = doc.get('fields', {})

            question = {
                'id': doc_id
            }

            for key, value in fields.items():
                question[key] = from_firestore_value(value)

            # Filtrar solo preguntas del test olfativo
            if question.get('questionType') == 'perfilOlfativo':
                questions.append(question)

        # Ordenar por order
        questions.sort(key=lambda q: q.get('order', 0))

        print(f"✅ Se encontraron {len(questions)} preguntas del test olfativo\n")

        # Guardar en archivo JSON
        output_file = os.path.join(script_dir, 'olfactive_profile_questions.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(questions, f, ensure_ascii=False, indent=2)

        print(f"💾 Preguntas guardadas en: {output_file}")

        # Mostrar resumen
        print("\n📋 Resumen de preguntas:")
        for q in questions:
            print(f"  {q.get('order', '?')}. {q.get('key', 'sin-key')} - {q.get('text', 'sin-texto')[:50]}...")

    else:
        print(f"❌ Error al obtener preguntas: {response.status_code}")
        print(f"   Respuesta: {response.text[:200]}")

except Exception as e:
    print(f"❌ Error: {str(e)}")
