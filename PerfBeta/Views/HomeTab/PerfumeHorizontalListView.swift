import SwiftUI

struct PerfumeHorizontalListView: View {
    // Data source
    let allPerfumes: [(perfume: Perfume, score: Double)]
    // Tap handler
    var onPerfumeTap: ((Perfume) -> Void)? = nil
    // Binding to show the full list view/sheet
    @Binding var showAllPerfumesSheet: Bool

    // Environment object needed by PerfumeCarouselItem
    @EnvironmentObject var brandViewModel: BrandViewModel

    // Helper to get the first 3 (or fewer) perfumes
    private var displayedPerfumes: [(perfume: Perfume, score: Double)] {
        Array(allPerfumes.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with title and "Ver todos" button
            HStack(alignment: .center) {
                Text("RECOMENDADOS PARA TI".uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal")) // Ensure Color("textoPrincipal") is defined

                Spacer()

                // Show "Ver todos" only if the original list has more than 3 items
                if allPerfumes.count > 3 {
                    Button {
                        showAllPerfumesSheet = true
                    } label: {
                        Text("Ver todos")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1)) // Ensure Color("champan") is defined
                            )
                    }
                }
            }
            .padding(.horizontal, 16)

            // Horizontal stack for the perfume items
            HStack(alignment: .top, spacing: 16) { // .top alignment might look better given the item structure
                // Loop through the perfumes to display (max 3)
                ForEach(displayedPerfumes, id: \.perfume.id) { perfumeTuple in // Use perfume.id if Perfume is Identifiable

                    PerfumeCard(
                        perfume: perfumeTuple.perfume,
                        brandName: brandViewModel.getBrand(byKey: perfumeTuple.perfume.brand)?.name ?? perfumeTuple.perfume.brand,
                        style: .carousel,
                        size: .small,
                        showsRating: true,
                        score: perfumeTuple.score
                    ) {
                        onPerfumeTap?(perfumeTuple.perfume)
                    }
                    .frame(maxWidth: .infinity) // *** Assign equal width to each item's container ***
                }

                // Add spacers to fill empty slots if fewer than 3 perfumes, ensuring left alignment
                if displayedPerfumes.count < 3 {
                    ForEach(0..<(3 - displayedPerfumes.count), id: \.self) { _ in
                        // Use Spacer with maxWidth: .infinity to take up equal remaining space
                        Spacer().frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16) // Padding for the HStack content
        }
        .padding(.top, 15) // Overall top padding for the VStack
    }
}
