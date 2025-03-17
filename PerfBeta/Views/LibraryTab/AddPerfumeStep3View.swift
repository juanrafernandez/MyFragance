//
//  AddPerfumeStep2View.swift
//  PerfBeta
//
//  Created by ES00571759 on 5/3/25.
//


import SwiftUI

// MARK: - AddPerfumeStep2View (Sin cambios)
struct AddPerfumeStep3View: View {
    @Binding var duration: Duration?
    @Binding var onboardingStep: Int

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Duration.allCases, id: \.self) { durationCase in
                DurationRadioButtonRow(duration: durationCase, selectedDuration: $duration, onboardingStep: $onboardingStep)
            }
        }
    }
}
