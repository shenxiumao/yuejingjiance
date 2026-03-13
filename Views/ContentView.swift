//
//  ContentView.swift
//  YueJingJiance
//
//  主内容视图 - 保留旧版本兼容性
//

import SwiftUI

// 标记此文件为已弃用，使用新的 YueJingJianceApp.swift
@available(*, deprecated, message: "请使用新的 YueJingJianceApp.swift 入口文件")
struct ContentView: View {
    @StateObject private var cycleManager = CycleManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首页")
                }
                .tag(0)
            
            RecordView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("记录")
                }
                .tag(1)
            
            CalendarView(cycleManager: cycleManager)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("日历")
                }
                .tag(2)
            
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
