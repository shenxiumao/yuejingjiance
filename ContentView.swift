import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var cycleManager = CycleManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 主页面
            HomeView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            // 记录页面
            RecordView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("记录")
                }
                .tag(1)
            
            // 日历页面
            CalendarView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(2)
            
            // 设置页面
            SettingsView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(.pink)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}