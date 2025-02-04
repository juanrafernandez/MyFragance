import SwiftUI

struct ProfilesListView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel

    var body: some View {
        List {
            ForEach(olfactiveProfileViewModel.profiles) { profile in
                Text(profile.name)
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        let profile = olfactiveProfileViewModel.profiles[index]
                        await olfactiveProfileViewModel.deleteProfile(profile)
                    }
                }
            }
            .onMove { indices, newOffset in
                olfactiveProfileViewModel.profiles.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .navigationTitle("Perfiles Guardados")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
}
