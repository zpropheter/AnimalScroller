// ContentView.swift

import SwiftUI
import Combine

// MARK: - Root View

struct ContentView: View {
    @StateObject private var viewModel = AnimalFeedViewModel()
    // scenePhase tells us whether the app is active, in the background, or inactive.
    // We use it to restore the idle timer when the user leaves the app.
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading && viewModel.currentPhoto == nil {
                InitialLoadingView()
            } else {
                PhotoDisplayView(viewModel: viewModel)
            }
        }
        .onAppear {
            // Disable the idle timer so the screen stays on while the app is open
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onChange(of: scenePhase) { newPhase in
            // Re-enable the idle timer when the app goes to background or becomes inactive,
            // so the screen can sleep normally when the user isn't using this app
            UIApplication.shared.isIdleTimerDisabled = (newPhase == .active)
        }
    }
}

// MARK: - Photo Display

struct PhotoDisplayView: View {
    @ObservedObject var viewModel: AnimalFeedViewModel

    var body: some View {
        ZStack {
            // Current photo
            if let photo = viewModel.currentPhoto {
                PhotoCardView(photo: photo)
                    .id(photo.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                    .ignoresSafeArea()
            }

            // Overlays — VStack sits inside the safe area automatically,
            // so these small pads just add breathing room beyond the
            // status bar / Dynamic Island / home indicator on any device.
            VStack {
                // Settings button — top right
                HStack {
                    Spacer()
                    SettingsMenuButton(viewModel: viewModel)
                }
                .padding(.top, 8)
                .padding(.trailing, 16)

                Spacer()

                // Animal name + attribution button — bottom center
                if let photo = viewModel.currentPhoto {
                    HStack(spacing: 8) {
                        AnimalNameLabel(name: photo.animalName)
                        AttributionButton(viewModel: viewModel)
                    }
                    .padding(.bottom, 16)
                }
            }
            .padding(.horizontal, 16)

            // Loading overlay while replenishing
            if viewModel.isLoading && viewModel.currentPhoto != nil {
                Color.black.opacity(0.45).ignoresSafeArea()
                ProgressView().tint(.white).scaleEffect(2)
            }
        }
    }
}

// MARK: - Photo Card (no long press)

struct PhotoCardView: View {
    let photo: AnimalPhoto

    var body: some View {
        AsyncImage(url: photo.imageURL) { phase in
            switch phase {
            case .success(let image):
                // .fit scales the image so the entire photo is always visible,
                // leaving black bars where the proportions don't match the screen.
                // This avoids cropping regardless of iPad orientation or photo aspect ratio.
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(bottomGradient)
            case .failure:
                Color.gray.overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "photo").font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.4))
                        Text("Image unavailable").foregroundColor(.white.opacity(0.4))
                    }
                )
            case .empty:
                Color.black.overlay(ProgressView().tint(.white))
            @unknown default:
                Color.black
            }
        }
    }

    private var bottomGradient: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.7)],
            startPoint: .center,
            endPoint: .bottom
        )
    }
}

// MARK: - Settings Button + Sheet

struct SettingsMenuButton: View {
    @ObservedObject var viewModel: AnimalFeedViewModel
    @State private var showSettings = false

    var body: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 4)
                .padding(12)
                .background(.black.opacity(0.4), in: Circle())
        }
        .sheet(isPresented: $showSettings) {
            SettingsPanelView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Settings Panel

struct SettingsPanelView: View {
    @ObservedObject var viewModel: AnimalFeedViewModel
    @Environment(\.dismiss) private var dismiss
    private let intervals: [Double] = [5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            List {
                // ── Timing ───────────────────────────────────────────
                Section("Time between photos") {
                    ForEach(intervals, id: \.self) { (seconds: Double) in
                        HStack {
                            Text("\(Int(seconds)) seconds")
                            Spacer()
                            if viewModel.photoInterval == seconds {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.photoInterval = seconds }
                    }
                }

                // ── Categories ───────────────────────────────────────
                Section("Categories") {
                    ForEach(AnimalCategory.allCases) { category in
                        HStack(spacing: 12) {
                            Image(systemName: category.icon)
                                .frame(width: 22)
                                .foregroundStyle(.secondary)
                            Text(category.rawValue)
                            Spacer()
                            Image(systemName: viewModel.enabledCategories.contains(category)
                                  ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(viewModel.enabledCategories.contains(category)
                                                 ? Color.accentColor : Color.secondary)
                                .font(.title3)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.toggleCategory(category) }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AnimalNameLabel: View {
    let name: String

    var body: some View {
        Text(name)
            // Dynamic Type: scales with the user's text size preference,
            // fits comfortably on iPhone SE through iPad Pro.
            .font(.system(.title2, design: .rounded).weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)   // shrinks gracefully for long names in landscape
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Attribution Button

struct AttributionButton: View {
    @ObservedObject var viewModel: AnimalFeedViewModel
    @State private var isPresented = false

    var body: some View {
        Button {
            viewModel.fetchAttribution()
            isPresented = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 4)
                .padding(10)
                .background(.black.opacity(0.4), in: Circle())
        }
        .sheet(isPresented: $isPresented, onDismiss: {
            viewModel.clearAttribution()
        }) {
            AttributionSheet(viewModel: viewModel)
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
        // Auto-dismiss if the photo advances while the sheet is open
        .onChange(of: viewModel.currentPhoto?.id) { _ in
            isPresented = false
        }
    }
}

// MARK: - Attribution Sheet

struct AttributionSheet: View {
    @ObservedObject var viewModel: AnimalFeedViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Photo Attribution")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.bottom, 16)

            Divider()

            if viewModel.isLoadingAttribution {
                Spacer()
                ProgressView("Fetching attribution…")
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if let attr = viewModel.currentAttribution {
                VStack(alignment: .leading, spacing: 16) {
                    AttributionRow(label: "Photographer", value: attr.author)
                    AttributionRow(label: "License", value: attr.license)

                    if let url = attr.licenseURL {
                        Link("View license →", destination: url)
                            .font(.footnote)
                    }
                    if let url = attr.filePageURL {
                        Link("View on Wikimedia Commons →", destination: url)
                            .font(.footnote)
                    }
                }
                .padding(20)
                Spacer()
            } else {
                Spacer()
                Text("Attribution not available for this image.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
                Spacer()
            }
        }
    }
}

struct AttributionRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
                .kerning(0.5)
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Initial Loading View

struct InitialLoadingView: View {
    var body: some View {
        VStack(spacing: 28) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.85))
            Text("Loading animals…")
                .font(.title2.weight(.medium))
                .foregroundStyle(.white)
            ProgressView().tint(.white).scaleEffect(1.5)
        }
    }
}

#Preview {
    ContentView()
}
