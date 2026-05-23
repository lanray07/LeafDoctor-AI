import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    planCard(
                        title: "Free",
                        price: "£0",
                        features: ["5 scans/month", "3 plants", "Basic reminders", "Limited history"],
                        isCurrent: !subscriptionManager.isActive,
                        actionTitle: "Current plan"
                    )
                    planCard(
                        title: "Pro",
                        price: "£6.99 monthly / £49.99 yearly",
                        features: ["Unlimited scans", "Unlimited plants", "AI treatment plans", "Advanced reminders", "Plant health insights", "PDF reports", "Recovery tracking"],
                        isCurrent: subscriptionManager.plan == .pro,
                        actionTitle: "Choose Pro"
                    )
                    subscriptionTerms

                    if let error = subscriptionManager.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await subscriptionManager.restorePurchases() }
                    } label: {
                        Label("Restore purchases", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .background(.leafMint.opacity(0.12))
            .navigationTitle("LeafDoctor Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "leaf.arrow.triangle.circlepath")
                .font(.system(size: 42))
                .foregroundStyle(.leafPrimary)
            Text("Grow healthier plants with deeper care tools.")
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
            Text("LeafDoctor Pro unlocks unlimited scans, advanced reminders, treatment plans, insights, recovery tracking, and PDF reports.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(LinearGradient(colors: [.leafMint, .leafTeal.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var subscriptionTerms: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Subscription information")
                .font(.headline)
            Text("LeafDoctor Pro Monthly renews every month at £6.99. LeafDoctor Pro Yearly renews every year at £49.99. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Link("Privacy policy", destination: AppLegalLinks.privacy)
                Spacer()
                Link("Terms of Use (EULA)", destination: AppLegalLinks.terms)
            }
            .font(.footnote.weight(.semibold))
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func planCard(
        title: String,
        price: String,
        features: [String],
        isCurrent: Bool,
        actionTitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.bold))
                    Text(price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isCurrent {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.leafPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.leafMint, in: Capsule())
                }
            }

            ForEach(features, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await purchaseBestMatch(for: title) }
            } label: {
                Text(actionTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isCurrent ? .secondary : Color.leafPrimary)
            .disabled(isCurrent || title == "Free" || subscriptionManager.isLoading)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isCurrent ? .leafPrimary.opacity(0.5) : .secondary.opacity(0.12), lineWidth: 1)
        )
    }

    private func purchaseBestMatch(for title: String) async {
        guard !subscriptionManager.products.isEmpty else {
            subscriptionManager.errorMessage = "Unable to load subscription products. Please try again later."
            return
        }

        let preferredID: String
        switch title {
        case "Pro":
            preferredID = subscriptionManager.yearlyProductID
        default:
            return
        }

        if let product = subscriptionManager.products.first(where: { $0.id == preferredID }) {
            await subscriptionManager.purchase(product)
        }
    }
}
