import Foundation

struct Perfume: Identifiable {
    let id: String?
    let nombre: String
    let familia: String
    let popularidad: Double
    let image_name: String
    let notas: [String]
}

struct MockPerfumes {
    static let perfumes: [Perfume] = [
        Perfume(
            id: "1",
            nombre: "Citrus Breeze",
            familia: "citricos", // Normalizamos a minúsculas y sin acentos
            popularidad: 8.5,
            image_name: "adolfo_dominguez_agua_tonka",
            notas: ["Limón", "Bergamota", "Mandarina", "Pomelo", "Naranja"]
        ),
        Perfume(
            id: "2",
            nombre: "Floral Bloom",
            familia: "florales", // Normalizamos a plural y minúsculas
            popularidad: 7.8,
            image_name: "aqua_di_gio_profondo",
            notas: ["Rosa", "Jazmín", "Lavanda", "Peonía", "Lirio"]
        ),
        Perfume(
            id: "3",
            nombre: "Woody Warmth",
            familia: "amaderados",
            popularidad: 9.2,
            image_name: "armani_code",
            notas: ["Sándalo", "Cedro", "Patchouli", "Madera de Oud", "Vetiver"]
        ),
        Perfume(
            id: "4",
            nombre: "Sweet Delight",
            familia: "gourmand", // Normalizamos a minúsculas
            popularidad: 8.0,
            image_name: "dolce_gabana_light_blue",
            notas: ["Vainilla", "Caramelo", "Canela", "Chocolate", "Miel"]
        ),
        Perfume(
            id: "5",
            nombre: "Ocean Breeze",
            familia: "acuaticos",
            popularidad: 7.5,
            image_name: "givenchy_gentleman_Intense",
            notas: ["Sal Marina", "Alga Marina", "Cáscara de Limón", "Brisa Marina", "Cilantro"]
        ),
        Perfume(
            id: "6",
            nombre: "Mystic Orient",
            familia: "orientales",
            popularidad: 8.7,
            image_name: "montblanc_legend_blue",
            notas: ["Ámbar", "Incienso", "Canela", "Cardamomo", "Clavo"]
        ),
        Perfume(
            id: "7",
            nombre: "Fresh Meadow",
            familia: "verdes",
            popularidad: 7.2,
            image_name: "rabane_invictus",
            notas: ["Hierba fresca", "Menta", "Manzana", "Té Verde", "Albahaca"]
        ),
        Perfume(
            id: "8",
            nombre: "Woody Warmth",
            familia: "amaderados",
            popularidad: 9.2,
            image_name: "rabane_million_gold",
            notas: ["Sándalo", "Cedro", "Patchouli", "Madera de Ébano", "Musgo de Roble"]
        )
    ]
}
