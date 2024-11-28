import Foundation

struct MockPerfumes {
    static let perfumes: [Perfume] = [
        Perfume(
            id: "1",
            nombre: "Citrus Breeze",
            familia: "Cítrica",
            popularidad: 8.5,
            notas: ["Limón", "Bergamota", "Mandarina"]
        ),
        Perfume(
            id: "2",
            nombre: "Floral Bloom",
            familia: "Floral",
            popularidad: 7.8,
            notas: ["Rosa", "Jazmín", "Lavanda"]
        ),
        Perfume(
            id: "3",
            nombre: "Woody Warmth",
            familia: "Amaderada",
            popularidad: 9.2,
            notas: ["Sándalo", "Cedro", "Patchouli"]
        ),
        Perfume(
            id: "4",
            nombre: "Sweet Delight",
            familia: "Dulce",
            popularidad: 8.0,
            notas: ["Vainilla", "Caramelo", "Canela"]
        ),
        Perfume(
            id: "5",
            nombre: "Ocean Breeze",
            familia: "Acuática",
            popularidad: 7.5,
            notas: ["Sal Marina", "Alga Marina", "Cáscara de Limón"]
        )
    ]
}
