import SwiftUI

struct ContentView: View {
    var body: some View {
        List {
            Label("订单", systemImage: "list.clipboard")
            Label("消息", systemImage: "message")
            Label("我的", systemImage: "person.circle")
        }
        .navigationTitle("PetFriendly")
    }
}

#Preview {
    ContentView()
}
