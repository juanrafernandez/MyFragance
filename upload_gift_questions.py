#!/usr/bin/env python3
"""
Script para subir las preguntas del sistema de recomendaciones de regalo a Firebase.
Usa Firebase Admin SDK para crear/actualizar documentos en la colección 'gift_questions'.
"""

import json
import os
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("❌ Error: Firebase Admin SDK no está instalado")
    print("   Instala con: pip3 install firebase-admin")
    exit(1)

# Directorio con los archivos JSON
QUESTIONS_DIR = Path("firebase_questions")

# Colección de Firestore (misma que las preguntas del test olfativo)
COLLECTION_NAME = "questions_es"

def initialize_firebase():
    """Inicializar Firebase Admin SDK"""

    # Buscar archivo de credenciales en varios lugares
    possible_cred_paths = [
        Path("firebase-credentials.json"),
        Path("perfbeta-firebase-adminsdk.json"),
        Path.home() / "Downloads" / "perfbeta-firebase-adminsdk.json"
    ]

    cred_path = None
    for path in possible_cred_paths:
        if path.exists():
            cred_path = path
            print(f"✅ Encontradas credenciales: {path}")
            break

    # Inicializar app si no está ya inicializada
    if not firebase_admin._apps:
        try:
            if cred_path:
                # Usar archivo de credenciales específico
                cred = credentials.Certificate(str(cred_path))
                firebase_admin.initialize_app(cred)
                print("✅ Firebase inicializado con archivo de credenciales")
            elif os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
                # Usar variable de entorno
                firebase_admin.initialize_app()
                print(f"✅ Firebase inicializado con GOOGLE_APPLICATION_CREDENTIALS")
            else:
                print("❌ Error: No se encontraron credenciales de Firebase")
                print("\n📝 Opciones:")
                print("   1. Descarga el archivo de credenciales desde:")
                print("      https://console.firebase.google.com/project/perfbeta/settings/serviceaccounts/adminsdk")
                print("   2. Guárdalo como 'firebase-credentials.json' en el directorio raíz")
                print("   3. O configura: export GOOGLE_APPLICATION_CREDENTIALS='/path/to/file.json'")
                exit(1)
        except Exception as e:
            print(f"❌ Error al inicializar Firebase: {e}")
            exit(1)

    return firestore.client()

def upload_question(db, question_data):
    """Subir una pregunta a Firestore"""
    doc_id = question_data.get("id")

    if not doc_id:
        print(f"⚠️  Pregunta sin ID, saltando...")
        return False

    try:
        doc_ref = db.collection(COLLECTION_NAME).document(doc_id)
        doc_ref.set(question_data)
        return True
    except Exception as e:
        print(f"❌ Error al subir {doc_id}: {e}")
        return False

def main():
    print("=" * 60)
    print("🎁 SUBIENDO PREGUNTAS DE REGALO A FIREBASE")
    print("=" * 60)
    print()

    # Verificar que el directorio existe
    if not QUESTIONS_DIR.exists():
        print(f"❌ Error: No se encontró el directorio '{QUESTIONS_DIR}'")
        exit(1)

    # Listar archivos JSON
    json_files = sorted(QUESTIONS_DIR.glob("*.json"))

    if not json_files:
        print(f"❌ No se encontraron archivos JSON en '{QUESTIONS_DIR}'")
        exit(1)

    print(f"📁 Encontrados {len(json_files)} archivos de preguntas")
    print()

    # Inicializar Firebase
    print("🔥 Inicializando Firebase...")
    try:
        db = initialize_firebase()
        print("✅ Firebase inicializado correctamente")
        print()
    except Exception as e:
        print(f"❌ Error: {e}")
        exit(1)

    # Subir cada pregunta
    success_count = 0
    error_count = 0

    for json_file in json_files:
        print(f"📤 Subiendo: {json_file.name}")

        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                question_data = json.load(f)

            if upload_question(db, question_data):
                print(f"   ✅ ID: {question_data.get('id')}")
                print(f"   📝 Pregunta: {question_data.get('question')[:50]}...")
                success_count += 1
            else:
                error_count += 1

        except json.JSONDecodeError as e:
            print(f"   ❌ Error JSON: {e}")
            error_count += 1
        except Exception as e:
            print(f"   ❌ Error: {e}")
            error_count += 1

        print()

    # Resumen
    print("=" * 60)
    print("📊 RESUMEN")
    print("=" * 60)
    print(f"✅ Preguntas subidas exitosamente: {success_count}")
    if error_count > 0:
        print(f"❌ Errores: {error_count}")
    print()
    print(f"🔗 Colección: {COLLECTION_NAME}")
    print(f"📍 Total documentos: {success_count}")
    print()

    # Mostrar estructura por flujo
    print("📋 ESTRUCTURA POR FLUJO:")
    print()

    flows = {
        "main": "Preguntas Principales",
        "A": "Flow A (Bajo Conocimiento)",
        "B1": "Flow B1 (Por Marcas)",
        "B2": "Flow B2 (Por Perfume)",
        "B3": "Flow B3 (Por Aromas)",
        "B4": "Flow B4 (Sin Referencias)"
    }

    for flow_key, flow_name in flows.items():
        flow_files = [f for f in json_files if flow_key in f.name]
        if flow_files:
            print(f"  • {flow_name}: {len(flow_files)} preguntas")

    print()
    print("🎉 ¡Listo! Puedes verificar en Firebase Console:")
    print("   https://console.firebase.google.com/project/perfbeta/firestore")
    print("=" * 60)

if __name__ == "__main__":
    main()
