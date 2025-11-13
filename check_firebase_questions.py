#!/usr/bin/env python3
"""Script para verificar preguntas en Firebase"""

import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

# Inicializar Firebase
cred_path = Path("firebase-credentials.json")
if not cred_path.exists():
    print("❌ No se encontró firebase-credentials.json")
    exit(1)

if not firebase_admin._apps:
    cred = credentials.Certificate(str(cred_path))
    firebase_admin.initialize_app(cred)

db = firestore.client()

print("=" * 60)
print("🔍 VERIFICANDO PREGUNTAS EN FIREBASE")
print("=" * 60)
print()

# Verificar colección questions_es
print("📋 Preguntas en 'questions_es':")
print()

validFlowTypes = ["main", "A", "B1", "B2", "B3", "B4"]

# Intentar la consulta que hace la app
try:
    snapshot = db.collection("questions_es") \
        .where("flowType", "in", validFlowTypes) \
        .get()

    print(f"✅ Consulta exitosa: {len(snapshot)} documentos encontrados")
    print()

    if snapshot:
        print("📄 Primeros 5 documentos:")
        for i, doc in enumerate(snapshot[:5]):
            data = doc.to_dict()
            print(f"\n{i+1}. ID: {doc.id}")
            print(f"   flowType: {data.get('flowType')}")
            print(f"   question: {data.get('question', 'N/A')[:50]}...")
            print(f"   order: {data.get('order')}")
    else:
        print("⚠️  No se encontraron documentos")
        print("\n🔍 Buscando documentos sin filtro...")

        all_docs = db.collection("questions_es").limit(10).get()
        print(f"Total documentos en questions_es: {len(all_docs)}")

        if all_docs:
            print("\nPrimeros documentos (cualquier flowType):")
            for doc in all_docs[:5]:
                data = doc.to_dict()
                print(f"- {doc.id}: flowType={data.get('flowType')}")

except Exception as e:
    print(f"❌ Error en consulta: {e}")
    print("\n🔍 Intentando consulta simple...")

    try:
        all_docs = db.collection("questions_es").limit(10).get()
        print(f"✅ Documentos encontrados (sin filtro): {len(all_docs)}")

        for doc in all_docs[:5]:
            data = doc.to_dict()
            print(f"- {doc.id}: flowType={data.get('flowType', 'NO TIENE')}")
    except Exception as e2:
        print(f"❌ Error incluso sin filtro: {e2}")

print()
print("=" * 60)
