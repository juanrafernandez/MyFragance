import SwiftUI

struct AddPerfumeStep4View: View {
    @Binding var projection: Projection?
    @Binding var onboardingStep: Int

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                ForEach(Projection.allCases, id: \.self) { projectionCase in
                    ProjectionRadioButtonRow(projection: projectionCase, selectedProjection: $projection, onboardingStep: $onboardingStep)
                }
            }
            .frame(height: geometry.size.height, alignment: .top)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
