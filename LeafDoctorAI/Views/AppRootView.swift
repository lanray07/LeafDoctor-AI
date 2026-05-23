import SwiftUI

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case collection = "Plants"
    case scanner = "Scan"
    case schedule = "Care"
    case insights = "Insights"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .collection: return "leaf.fill"
        case .scanner: return "camera.viewfinder"
        case .schedule: return "calendar.badge.clock"
        case .insights: return "chart.xyaxis.line"
        }
    }
}

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var showingPaywall = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tabContent(for: tab)
                        .navigationTitle(tab.rawValue)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    showingPaywall = true
                                } label: {
                                    Image(systemName: "sparkles")
                                }
                                .accessibilityLabel("Upgrade")
                            }
                        }
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(selectedTab: $selectedTab)
        case .collection:
            PlantCollectionView()
        case .scanner:
            PlantScannerView()
        case .schedule:
            SmartCareScheduleView()
        case .insights:
            InsightsDashboardView()
        }
    }
}
