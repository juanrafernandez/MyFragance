#!/usr/bin/env python3
"""
Script para exportar las preguntas de opinión y regalo desde Firebase
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

print(f"🔥 Exportando preguntas de opinión y regalo desde Firebase proyecto: {PROJECT_ID}\n")

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
        opinion_questions = []
        gift_questions = []

        for doc in data['documents']:
            fields = doc.get('fields', {})
            question = {k: from_firestore_value(v) for k, v in fields.items()}

            question_type = question.get('questionType', '')
            question_id = question.get('id', '')

            # Filtrar preguntas de opinión
            if question_type == 'mi_opinion':
                opinion_questions.append(question)

            # Filtrar preguntas de regalo (flows)
            if question_id.startswith('flow'):
                gift_questions.append(question)

        # Ordenar por orden
        opinion_questions.sort(key=lambda q: q.get('order', 999))
        gift_questions.sort(key=lambda q: (q.get('id', ''), q.get('order', 999)))

        # === PREGUNTAS DE OPINIÓN ===
        print(f"✅ Preguntas de opinión encontradas: {len(opinion_questions)}\n")
        print("=" * 80)
        print("PREGUNTAS DE OPINIÓN SOBRE PERFUMES")
        print("=" * 80)

        for q in opinion_questions:
            print(f"\n📝 {q.get('id')}")
            print(f"   Pregunta: {q.get('text', 'N/A')}")
            print(f"   Opciones: {len(q.get('options', []))}")

        # Guardar preguntas de opinión
        opinion_file = os.path.join(script_dir, 'opinion_questions.json')
        with open(opinion_file, 'w', encoding='utf-8') as f:
            json.dump(opinion_questions, f, indent=2, ensure_ascii=False)

        print(f"\n📁 Preguntas de opinión exportadas a: opinion_questions.json")

        # === PREGUNTAS DE REGALO ===
        print(f"\n\n✅ Preguntas de regalo encontradas: {len(gift_questions)}\n")
        print("=" * 80)
        print("PREGUNTAS DE REGALO (TODOS LOS FLUJOS)")
        print("=" * 80)

        # Agrupar por flow
        flows = {}
        for q in gift_questions:
            qid = q.get('id', '')
            flow_name = qid.split('_')[0] if '_' in qid else 'unknown'
            if flow_name not in flows:
                flows[flow_name] = []
            flows[flow_name].append(q)

        for flow_name in sorted(flows.keys()):
            print(f"\n🎁 {flow_name.upper()} ({len(flows[flow_name])} preguntas):")
            for q in sorted(flows[flow_name], key=lambda x: x.get('order', 999)):
                print(f"   - {q.get('id')}: {q.get('category', 'N/A')}")

        # Guardar preguntas de regalo
        gift_file = os.path.join(script_dir, 'gift_flow_questions.json')
        with open(gift_file, 'w', encoding='utf-8') as f:
            json.dump(gift_questions, f, indent=2, ensure_ascii=False)

        print(f"\n📁 Preguntas de regalo exportadas a: gift_flow_questions.json")

        print(f"\n" + "=" * 80)
        print(f"✨ RESUMEN COMPLETO")
        print(f"=" * 80)
        print(f"📊 Total de preguntas de opinión: {len(opinion_questions)}")
        print(f"🎁 Total de preguntas de regalo: {len(gift_questions)}")
        print(f"   Flujos identificados: {', '.join(sorted(flows.keys()))}")

    else:
        print("⚠️  No se encontraron preguntas en Firebase")
else:
    print(f"❌ Error al obtener preguntas: {response.status_code}")
    print(response.text[:200])
