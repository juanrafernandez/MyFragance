#!/usr/bin/env python3
"""
Script para exportar las preguntas del flujo de regalos desde Firebase
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

print(f"🔥 Exportando preguntas de regalo desde Firebase proyecto: {PROJECT_ID}\n")

# Base URL para Firestore REST API
base_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

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

# Obtener todas las preguntas
url = f"{base_url}/questions_es"
response = requests.get(url, params={"key": API_KEY})

if response.status_code == 200:
    data = response.json()

    if 'documents' in data:
        gift_questions = []
        for doc in data['documents']:
            fields = doc.get('fields', {})
            question = {k: from_firestore_value(v) for k, v in fields.items()}

            # Filtrar preguntas de regalo (gift)
            question_type = question.get('questionType', '')
            question_id = question.get('id', '')

            # Buscar preguntas que sean de tipo gift o contengan 'gift' en el ID
            if 'gift' in question_type.lower() or 'gift' in question_id.lower():
                gift_questions.append(question)

        # Ordenar por campo 'order' si existe
        gift_questions.sort(key=lambda q: q.get('order', 999))

        print(f"✅ Total de preguntas de regalo encontradas: {len(gift_questions)}\n")

        # Guardar en archivo JSON
        output_file = os.path.join(script_dir, 'gift_questions.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(gift_questions, f, indent=2, ensure_ascii=False)

        print(f"📁 Preguntas exportadas a: gift_questions.json\n")

        # Mostrar resumen
        print("=" * 80)
        for q in gift_questions:
            order = q.get('order', 'N/A')
            qid = q.get('id', 'N/A')
            category = q.get('category', 'N/A')
            qtype = q.get('questionType', 'N/A')

            print(f"📝 {qid}")
            print(f"   Orden: {order}")
            print(f"   Categoría: {category}")
            print(f"   Tipo: {qtype}")
            print(f"   Pregunta: {q.get('text', 'N/A')[:60]}...")
            print()
    else:
        print("⚠️  No se encontraron preguntas en Firebase")
else:
    print(f"❌ Error al obtener preguntas: {response.status_code}")
    print(response.text[:200])
