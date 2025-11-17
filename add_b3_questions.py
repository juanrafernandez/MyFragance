#!/usr/bin/env python3
"""
Script para añadir las preguntas del flujo B3 a Firebase Firestore
Requiere: pip install firebase-admin
"""

import json
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Inicializar Firebase
cred = credentials.Certificate("GoogleService-Info.plist")
firebase_admin.initialize_app(cred)

db = firestore.client()

# Cargar preguntas desde el JSON
with open('flowB3_questions.json', 'r', encoding='utf-8') as f:
    questions = json.load(f)

print("🚀 Añadiendo preguntas del flujo B3 a Firebase...")
print(f"📝 Total de preguntas a añadir: {len(questions)}\n")

# Añadir cada pregunta
for question in questions:
    question_id = question['id']
    print(f"📝 Añadiendo pregunta: {question_id}")

    # Añadir timestamps
    question['createdAt'] = firestore.SERVER_TIMESTAMP
    question['updatedAt'] = firestore.SERVER_TIMESTAMP

    # Convertir null a None en filters
    if 'options' in question:
        for option in question['options']:
            if 'filters' in option:
                for key, value in option['filters'].items():
                    if value is None or (isinstance(value, str) and value.lower() == 'null'):
                        option['filters'][key] = None

    try:
        # Añadir a Firestore
        db.collection('questions_es').document(question_id).set(question)
        print(f"✅ Pregunta {question_id} añadida correctamente")
    except Exception as e:
        print(f"❌ Error añadiendo {question_id}: {str(e)}")

print("\n✨ Proceso completado!")
print("🔄 Recuerda invalidar el cache en la app para que se carguen las nuevas preguntas")
