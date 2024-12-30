import SwiftUI

struct ProfilesListView: View {
    @EnvironmentObject var profileManager: OlfactiveProfileManager

    var body: some View {
        List {
            ForEach(profileManager.profiles) { profile in
                Text(profile.name)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    profileManager.profiles.remove(at: index)
                }
            }
            .onMove { indices, newOffset in
                profileManager.profiles.move(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .navigationTitle("Perfiles Guardados")
        .navigationBarItems(trailing: EditButton())
    }
}
