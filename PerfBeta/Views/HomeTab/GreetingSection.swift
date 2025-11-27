//
//  GreetingSection.swift
//  PerfBeta
//
//  Created by ES00571759 on 13/11/23.
//

import SwiftUI

// MARK: - Sección de saludo (Diseño Editorial)
struct GreetingSection: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(getGreetingMessage(for: userName))
                .font(.custom("Georgia", size: 18))
                .foregroundColor(AppColor.textSecondary)

            // Separador elegante
            Rectangle()
                .fill(AppColor.textSecondary.opacity(0.15))
                .frame(height: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func getGreetingMessage(for name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let capitalizedName = name.capitalized
        if hour >= 6 && hour < 12 {
            return "Buenos días, \(capitalizedName)"
        } else if hour >= 12 && hour < 18 {
            return "Buenas tardes, \(capitalizedName)"
        } else {
            return "Buenas noches, \(capitalizedName)"
        }
    }
}
