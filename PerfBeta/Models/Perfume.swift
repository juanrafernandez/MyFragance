import Foundation

struct Perfume: Identifiable, Equatable, Codable, Hashable {
    let id: String?
    let nombre: String
    let familia: String
    let popularidad: Double
    let image_name: String
    let notas: [String]
    let fabricante: String
    let descripcionOlfativa: String? // Breve descripción del perfume
    let notasSalida: [String]? // Notas de salida
    let notasCorazon: [String]? // Notas de corazón
    let notasFondo: [String]? // Notas de fondo
    let concentracion: String // Ejemplo: Eau de Parfum
    let genero: String // Masculino, Femenino, Unisex
    let recomendacionesUso: String? // Contexto sugerido para uso
}

struct MockPerfumes {
    static let perfumes: [Perfume] = [
        Perfume(
            id: "1",
            nombre: "Citrus Breeze",
            familia: "cítricos",
            popularidad: 8.5,
            image_name: "adolfo_dominguez_agua_tonka",
            notas: ["Limón", "Bergamota", "Mandarina", "Pomelo", "Naranja"],
            fabricante: "Adolfo Domínguez",
            descripcionOlfativa: "Una fragancia cítrica y vibrante, ideal para días soleados.",
            notasSalida: ["Limón", "Pomelo", "Mandarina"],
            notasCorazon: ["Jazmín", "Naranja", "Ylang-Ylang"],
            notasFondo: ["Vetiver", "Ámbar"],
            concentracion: "Eau de Toilette",
            genero: "Unisex",
            recomendacionesUso: "Perfecto para días cálidos y soleados."
        ),
        Perfume(
            id: "2",
            nombre: "Floral Bloom",
            familia: "florales",
            popularidad: 7.8,
            image_name: "aqua_di_gio_profondo",
            notas: ["Rosa", "Jazmín", "Lavanda", "Peonía", "Lirio"],
            fabricante: "Giorgio Armani",
            descripcionOlfativa: "Una fragancia floral y elegante que evoca jardines en primavera.",
            notasSalida: ["Bergamota", "Neroli"],
            notasCorazon: ["Rosa", "Jazmín", "Peonía"],
            notasFondo: ["Almizcle", "Madera de Cedro"],
            concentracion: "Eau de Parfum",
            genero: "Femenino",
            recomendacionesUso: "Ideal para eventos de día y cenas al aire libre."
        ),
        Perfume(
            id: "3",
            nombre: "Woody Warmth",
            familia: "amaderados",
            popularidad: 9.2,
            image_name: "armani_code",
            notas: ["Sándalo", "Cedro", "Patchouli", "Madera de Oud", "Vetiver"],
            fabricante: "Armani",
            descripcionOlfativa: "Un perfume amaderado y cálido con un toque exótico.",
            notasSalida: ["Pimienta Rosa", "Bergamota"],
            notasCorazon: ["Canela", "Madera de Oud"],
            notasFondo: ["Sándalo", "Vetiver"],
            concentracion: "Eau de Parfum",
            genero: "Masculino",
            recomendacionesUso: "Perfecto para noches de invierno y ocasiones especiales."
        ),
        Perfume(
            id: "4",
            nombre: "Sweet Delight",
            familia: "gourmand",
            popularidad: 8.0,
            image_name: "dolce_gabana_light_blue",
            notas: ["Vainilla", "Caramelo", "Canela", "Chocolate", "Miel"],
            fabricante: "Dolce & Gabbana",
            descripcionOlfativa: "Una fragancia dulce y seductora con notas gourmand.",
            notasSalida: ["Vainilla", "Canela"],
            notasCorazon: ["Caramelo", "Chocolate"],
            notasFondo: ["Miel", "Tonka"],
            concentracion: "Eau de Parfum",
            genero: "Femenino",
            recomendacionesUso: "Ideal para noches románticas y eventos elegantes."
        ),
        Perfume(
            id: "5",
            nombre: "Ocean Breeze",
            familia: "acuáticos",
            popularidad: 7.5,
            image_name: "givenchy_gentleman_Intense",
            notas: ["Sal Marina", "Alga Marina", "Cáscara de Limón", "Brisa Marina", "Cilantro"],
            fabricante: "Givenchy",
            descripcionOlfativa: "Un aroma fresco y marino que captura la esencia del océano.",
            notasSalida: ["Cáscara de Limón", "Brisa Marina"],
            notasCorazon: ["Cilantro", "Lavanda"],
            notasFondo: ["Madera de Cedro", "Almizcle"],
            concentracion: "Eau de Toilette",
            genero: "Unisex",
            recomendacionesUso: "Perfecto para días en la playa o paseos al aire libre."
        ),
        Perfume(
            id: "6",
            nombre: "Mystic Orient",
            familia: "orientales",
            popularidad: 8.7,
            image_name: "montblanc_legend_blue",
            notas: ["Ámbar", "Incienso", "Canela", "Cardamomo", "Clavo"],
            fabricante: "Montblanc",
            descripcionOlfativa: "Un perfume oriental con especias cálidas y un toque místico.",
            notasSalida: ["Incienso", "Canela"],
            notasCorazon: ["Clavo", "Cardamomo"],
            notasFondo: ["Ámbar", "Madera de Sándalo"],
            concentracion: "Eau de Parfum",
            genero: "Unisex",
            recomendacionesUso: "Perfecto para noches frescas y momentos íntimos."
        )
    ]
}
