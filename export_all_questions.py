#!/usr/bin/env python3
"""
Script para exportar TODAS las preguntas desde Firebase Firestore
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

print(f"📝 Obteniendo TODAS las preguntas...\n")

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
        question_types = set()

        for doc in data['documents']:
            doc_id = doc['name'].split('/')[-1]
            fields = doc.get('fields', {})

            question = {
                'id': doc_id
            }

            for key, value in fields.items():
                question[key] = from_firestore_value(value)

            questions.append(question)

            # Recopilar tipos de preguntas
            if 'questionType' in question:
                question_types.add(question['questionType'])
            if 'flowType' in question:
                question_types.add(f"flowType: {question['flowType']}")

        print(f"✅ Se encontraron {len(questions)} preguntas en total\n")
        print(f"📊 Tipos de preguntas encontrados: {question_types}\n")

        # Agrupar por tipo
        by_type = {}
        for q in questions:
            qtype = q.get('questionType') or q.get('flowType', 'unknown')
            if qtype not in by_type:
                by_type[qtype] = []
            by_type[qtype].append(q)

        # Mostrar resumen
        print("📋 Resumen por tipo:")
        for qtype, qs in by_type.items():
            print(f"\n  {qtype}: {len(qs)} preguntas")
            for q in sorted(qs, key=lambda x: x.get('order', 0))[:3]:
                print(f"    - {q.get('id', 'sin-id')}: {q.get('question', q.get('text', 'sin-texto'))[:60]}...")

        # Guardar todo en JSON
        output_file = os.path.join(script_dir, 'all_questions.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(questions, f, ensure_ascii=False, indent=2)

        print(f"\n💾 Todas las preguntas guardadas en: {output_file}")

    else:
        print(f"❌ Error al obtener preguntas: {response.status_code}")
        print(f"   Respuesta: {response.text[:200]}")

except Exception as e:
    print(f"❌ Error: {str(e)}")
