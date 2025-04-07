import SwiftUI

struct TestResultFullScreenView: View {
    let profile: OlfactiveProfile
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            TestResultContentView(profile: profile)
                .navigationTitle(profile.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.black)
                        }
                    }
                }
        }
    }
}
