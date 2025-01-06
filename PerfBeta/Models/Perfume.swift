import SwiftData
import Foundation

@Model
struct Perfume: Identifiable {
    @Attribute(.unique) var id: String
    var nombre: String
    var marca: String
    var familia: String
    var notasPrincipales: [String]
    var notasSalida: [String]
    var notasCorazon: [String]
    var notasFondo: [String]
    var proyeccion: String
    var duracion: String
    var anio: Int
    var perfumista: String
    var imagenURL: String
    var descripcion: String
    var genero: String
    
    init(
        id: String = UUID().uuidString,
        nombre: String,
        marca: String,
        familia: String,
        notasPrincipales: [String],
        notasSalida: [String],
        notasCorazon: [String],
        notasFondo: [String],
        proyeccion: String,
        duracion: String,
        anio: Int,
        perfumista: String,
        imagenURL: String,
        descripcion: String,
        genero: String
    ) {
        self.id = id
        self.nombre = nombre
        self.marca = marca
        self.familia = familia
        self.notasPrincipales = notasPrincipales
        self.notasSalida = notasSalida
        self.notasCorazon = notasCorazon
        self.notasFondo = notasFondo
        self.proyeccion = proyeccion
        self.duracion = duracion
        self.anio = anio
        self.perfumista = perfumista
        self.imagenURL = imagenURL
        self.descripcion = descripcion
        self.genero = genero
    }
    
    // Inicializador desde un diccionario (Firestore)
    init?(from data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let nombre = data["nombre"] as? String,
            let marca = data["marca"] as? String,
            let familia = data["familia"] as? String,
            let notasPrincipales = data["notasPrincipales"] as? [String],
            let notasSalida = data["notasSalida"] as? [String],
            let notasCorazon = data["notasCorazon"] as? [String],
            let notasFondo = data["notasFondo"] as? [String],
            let proyeccion = data["proyeccion"] as? String,
            let duracion = data["duracion"] as? String,
            let anio = data["anio"] as? Int,
            let perfumista = data["perfumista"] as? String,
            let imagenURL = data["imagenURL"] as? String,
            let descripcion = data["descripcion"] as? String,
            let genero = data["genero"] as? String
        else {
            return nil
        }
        
        self.id = id
        self.nombre = nombre
        self.marca = marca
        self.familia = familia
        self.notasPrincipales = notasPrincipales
        self.notasSalida = notasSalida
        self.notasCorazon = notasCorazon
        self.notasFondo = notasFondo
        self.proyeccion = proyeccion
        self.duracion = duracion
        self.anio = anio
        self.perfumista = perfumista
        self.imagenURL = imagenURL
        self.descripcion = descripcion
        self.genero = genero
    }
}
