import SwiftUI
import Kingfisher

struct TriedPerfumesListView: View {
    @StateObject var userViewModel = UserViewModel()
    @State private var searchText = ""
    //@State private var triedPerfumes: [TriedPerfumeRecord] = []
    
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan
    @EnvironmentObject var brandViewModel: BrandViewModel

    //let userId = "testUserId"
    let userId : String
    var triedPerfumes : [TriedPerfumeRecord]
    
    var body: some View {
        ZStack {
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack {
                searchBar

                if triedPerfumes.isEmpty {
                    emptyListView
                } else {
                    perfumeListView
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Perfumes Probados")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
    }


//    internal func convertTriedPerfumeRecordsToPerfumes(_ records: [TriedPerfumeRecord]) async -> [TriedPerfumeRecord] {
//        var triedPerfume: [TriedPerfumeRecord] = []
//
//        for record in records {
//            do {
//                if let perfume = try await userViewModel.userService.fetchPerfume(by: record.perfumeId, brandId: record.brandId, perfumeKey: record.perfumeKey) {
//                    let brand = brandViewModel.getBrand(byKey: perfume.brand)
//                    let perfumeWithRecord = PerfumeWithRecord(perfume: perfume, record: record, brand: brand)
//                    perfumesWithRecords.append(perfumeWithRecord)
//                } else {
//                    print("convertTriedPerfumeRecordsToPerfumes - fetchPerfume returned nil for perfumeId: \(record.perfumeId)")
//                }
//            } catch {
//                print("convertTriedPerfumeRecordsToPerfumes - ERROR fetching perfumeId: \(record.perfumeId) - Error: \(error)")
//            }
//        }
//
//        return perfumesWithRecords.sorted(by: { a, b in
//            let ratingA = a.record.rating ?? 0
//            let ratingB = b.record.rating ?? 0
//            return ratingA > ratingB
//        })
//    }


    // private var headerView: some View {  <- REMOVE headerView definition ENTIRELY
    //     HStack {
    //         Button(action: { dismiss() }) {
    //             Image(systemName: "chevron.backward")
    //         }
    //         .buttonStyle(PlainButtonStyle())
    //         Text("Perfumes Probados".uppercased())
    //             .font(.system(size: 18, weight: .light))
    //             .foregroundColor(Color("textoPrincipal"))
    //         Spacer()
    //         // Add Edit Button or similar functionality if needed in the header
    //     }
    //     .padding(.top, 16)
    // }

    private var searchBar: some View {
        TextField("Buscar perfume o marca", text: $searchText)
            .padding(8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            .foregroundColor(Color("textoPrincipal"))
    }


    private var emptyListView: some View {
        VStack {
            Spacer()
            Text("No hay perfumes en esta lista aún.")
                .font(.title3)
                .foregroundColor(Color.gray)
            Spacer()
        }
    }

    private var perfumeListView: some View {
        List {
            ForEach(filteredPerfumes, id: \.id) { triedPerfume in
                TriedPerfumeRowView(triedPerfume: triedPerfume)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deletePerfume)
        }
        .listStyle(.plain)
        .background(Color.clear)
    }

    private func loadTriedPerfumes() {
        Task {
            await userViewModel.loadTriedPerfumes(userId: userId)
            //self.triedPerfumes = userViewModel.triedPerfumes
            //perfumes = await convertTriedPerfumeRecordsToPerfumes(userViewModel.triedPerfumesRecords)
        }
    }
    
    private var filteredPerfumes: [TriedPerfumeRecord] {
        if searchText.isEmpty {
            return triedPerfumes
        } else {
            return triedPerfumes.filter { perfume in
                perfume.perfumeKey.localizedCaseInsensitiveContains(searchText) ||
                perfume.brandId.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func deletePerfume(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let perfumeToDelete = filteredPerfumes[index]

        if let recordId = perfumeToDelete.id {
            Task {
                let success = await userViewModel.deleteTriedPerfume(userId: userId, recordId: recordId)
                if success {
                    loadTriedPerfumes()
                } else {
                    print("Error deleting perfume")
                }
            }
        } else {
            print("Error: record.id is nil for perfumeToDelete: \(perfumeToDelete.perfumeKey)")
        }
    }
}
