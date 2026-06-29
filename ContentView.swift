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

            // Overlays
            VStack {
                // Settings button — top right
                HStack {
                    Spacer()
                    SettingsMenuButton(viewModel: viewModel)
                }
                .padding(.top, 56)
                .padding(.trailing, 20)

                Spacer()

                // Animal name — bottom center
                if let photo = viewModel.currentPhoto {
                    AnimalNameLabel(name: photo.animalName)
                        .padding(.bottom, 48)
                }
            }
            .padding(.horizontal, 20)

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

// MARK: - Settings Menu

struct SettingsMenuButton: View {
    @ObservedObject var viewModel: AnimalFeedViewModel

    private let intervals: [Double] = [5, 10, 15, 20, 30]

    var body: some View {
        Menu {
            Text("Time between photos")
            Divider()
            ForEach(intervals, id: \.self) { seconds in
                Button {
                    viewModel.photoInterval = seconds
                } label: {
                    if viewModel.photoInterval == seconds {
                        Label("\(Int(seconds)) seconds", systemImage: "checkmark")
                    } else {
                        Text("\(Int(seconds)) seconds")
                    }
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title2)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 4)
                .padding(12)
                .background(.black.opacity(0.4), in: Circle())
        }
    }
}

// MARK: - Supporting Views

struct AnimalNameLabel: View {
    let name: String

    var body: some View {
        Text(name)
            .font(.system(size: 30, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

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
