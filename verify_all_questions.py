#!/usr/bin/env python3
"""
Script para verificar todas las preguntas de perfil olfativo en Firebase
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

print(f"🔥 Verificando preguntas en Firebase proyecto: {PROJECT_ID}\n")

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
        questions = []
        for doc in data['documents']:
            fields = doc.get('fields', {})
            question = {k: from_firestore_value(v) for k, v in fields.items()}

            # Filtrar solo preguntas de perfil olfativo
            if question.get('questionType') in ['perfil_olfativo', 'autocomplete_multiple']:
                questions.append(question)

        # Ordenar por campo 'order'
        questions.sort(key=lambda q: q.get('order', 999))

        print(f"✅ Total de preguntas de perfil olfativo: {len(questions)}\n")
        print("=" * 80)

        for q in questions:
            order = q.get('order', 'N/A')
            qid = q.get('id', 'N/A')
            category = q.get('category', 'N/A')
            qtype = q.get('questionType', 'N/A')
            num_options = len(q.get('options', []))

            print(f"📝 Orden {order}: {qid}")
            print(f"   Categoría: {category}")
            print(f"   Tipo: {qtype}")
            print(f"   Pregunta: {q.get('text', 'N/A')[:60]}...")
            print(f"   Opciones: {num_options}")

            # Verificar image_assets
            if num_options > 0:
                assets = [opt.get('image_asset', 'N/A') for opt in q.get('options', [])]
                print(f"   Assets: {', '.join(assets)}")

            print()

        print("=" * 80)
        print(f"\n📊 Resumen:")
        print(f"   Serie A (Básicas): 6 preguntas (orden 0-5)")
        print(f"   Serie B (Intermedias): 5 preguntas (orden 6-10)")
        print(f"   Total: {len(questions)} preguntas")
    else:
        print("⚠️  No se encontraron preguntas en Firebase")
else:
    print(f"❌ Error al obtener preguntas: {response.status_code}")
    print(response.text[:200])
