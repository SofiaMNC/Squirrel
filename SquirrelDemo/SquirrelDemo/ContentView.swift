import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SquirrelTab()
                .tag("Squirrel")
                .tabItem {
                    Label("Squirrel", systemImage: "star")
                }
            SquirrelUITabPhaseView()
                .tag("SquirrelUI")
                .tabItem {
                    Label("SquirrelUI (Phase)", systemImage: "star")
                }
            SquirrelUITabImageView()
                .tag("SquirrelUI (Placeholder)")
                .tabItem {
                    Label("SquirrelUI", systemImage: "star")
                }
        }
    }
}

#Preview {
    ContentView()
}
