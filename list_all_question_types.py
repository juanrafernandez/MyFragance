#!/usr/bin/env python3
"""
Script para listar todos los tipos de preguntas en Firebase
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

print(f"🔥 Listando todas las preguntas en Firebase proyecto: {PROJECT_ID}\n")

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
        all_questions = []
        question_types = set()
        categories = set()

        for doc in data['documents']:
            fields = doc.get('fields', {})
            question = {k: from_firestore_value(v) for k, v in fields.items()}
            all_questions.append(question)

            # Recopilar tipos y categorías
            qtype = question.get('questionType', 'N/A')
            category = question.get('category', 'N/A')
            question_types.add(qtype)
            categories.add(category)

        print(f"✅ Total de preguntas: {len(all_questions)}")
        print(f"\n📊 Tipos de preguntas encontrados:")
        for qt in sorted(question_types):
            count = sum(1 for q in all_questions if q.get('questionType') == qt)
            print(f"   - {qt}: {count} preguntas")

        print(f"\n📋 Categorías encontradas:")
        for cat in sorted(categories):
            count = sum(1 for q in all_questions if q.get('category') == cat)
            print(f"   - {cat}: {count} preguntas")

        print(f"\n📝 Lista completa de preguntas:")
        print("=" * 100)

        # Ordenar por ID
        all_questions.sort(key=lambda q: q.get('id', ''))

        for q in all_questions:
            qid = q.get('id', 'N/A')
            qtype = q.get('questionType', 'N/A')
            category = q.get('category', 'N/A')
            order = q.get('order', 'N/A')
            text = q.get('text', 'N/A')

            print(f"ID: {qid}")
            print(f"   Tipo: {qtype}")
            print(f"   Categoría: {category}")
            print(f"   Orden: {order}")
            print(f"   Pregunta: {text[:80]}...")
            print()

        # Guardar todas las preguntas
        output_file = os.path.join(script_dir, 'all_questions_complete.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(all_questions, f, indent=2, ensure_ascii=False)

        print(f"📁 Todas las preguntas exportadas a: all_questions_complete.json")

    else:
        print("⚠️  No se encontraron preguntas en Firebase")
else:
    print(f"❌ Error al obtener preguntas: {response.status_code}")
    print(response.text[:200])
