//
//  GreetingSection.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

// MARK: - Sección de saludo - Refined Greeting (sin cambios)
struct GreetingSection: View {
    let userName: String

    var body: some View {
        let greetingMessage = getGreetingMessage(for: userName)
        Text(greetingMessage)
            .font(.system(size: 18, weight: .thin)) // Thinner, slightly larger font
            .foregroundColor(AppColor.textSecondary) // Use textoSecundario for subtlety
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    func getGreetingMessage(for name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour < 12 {
            return "Buenos días, \(name)".uppercased()
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(name)".uppercased()
        } else {
            return "Buenas noches, \(name)".uppercased()
        }
    }
}
