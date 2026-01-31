import SwiftUI

struct WelcomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Hero Section with Animated Elements
                VStack(spacing: 0) {
                    Spacer()
                    
                    ZStack {
                        // Background circles with animation
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.08),
                                        Color.purple.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                            .opacity(isAnimating ? 1 : 0)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.12),
                                        Color.cyan.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                            .scaleEffect(isAnimating ? 1.0 : 0.85)
                            .opacity(isAnimating ? 1 : 0)
                        
                        // Main icon group
                        ZStack {
                            // Background task icon
                            if #available(iOS 18.0, *) {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 45, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.blue.opacity(0.4))
                                    .offset(x: -25, y: 15)
                                    .symbolEffect(.wiggle.down, options: .repeat(3).speed(0.5), value: isAnimating)
                            } else {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: 45, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.blue.opacity(0.4))
                                    .offset(x: -25, y: 15)
                            }
                            
                            // Main checkmark circle
                            if #available(iOS 18.0, *) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 70, weight: .light))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .blue)
                                    .symbolEffect(.bounce, options: .speed(0.8), value: isAnimating)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 70, weight: .light))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .blue)
                            }
                            
                            // Sparkle accent
                            if #available(iOS 18.0, *) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 24, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.yellow)
                                    .offset(x: 35, y: -35)
                                    .symbolEffect(.pulse.wholeSymbol, options: .repeat(4).speed(0.6), value: isAnimating)
                            } else {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 24, weight: .semibold))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.yellow)
                                    .offset(x: 35, y: -35)
                            }
                            
                            // Bell notification
                            if #available(iOS 18.0, *) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .orange, .red)
                                    .offset(x: 40, y: 20)
                                    .symbolEffect(.wiggle.clockwise, options: .repeat(3).speed(0.7), value: isAnimating)
                            } else {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .orange, .red)
                                    .offset(x: 40, y: 20)
                            }
                            
                            // Calendar element
                            if #available(iOS 18.0, *) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 32, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.green)
                                    .offset(x: -35, y: -25)
                                    .symbolEffect(.bounce, options: .repeat(2).speed(0.5), value: isAnimating)
                            } else {
                                Image(systemName: "calendar")
                                    .font(.system(size: 32, weight: .medium))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.green)
                                    .offset(x: -35, y: -25)
                            }
                        }
                        .opacity(isAnimating ? 1 : 0)
                    }
                    
                    Spacer()
                }
                
                // MARK: - Bottom Content Section
                VStack(spacing: 0) {
                    // Text content
                    VStack(spacing: 12) {
                        Text("Welcome to\nGrahak Tasks")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(primaryText)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                        
                        Text("Organize your tasks and stay focused\non what matters most.")
                            .font(.system(size: 17, weight: .regular))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(y: isAnimating ? 0 : 20)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                    
                    // Action button
                    VStack(spacing: 16) {
                        Button {
                            startTapped()
                        } label: {
                            Text("Get Started")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.blue)
                                )
                        }
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                        
                        Text("You can customize settings anytime")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.secondary.opacity(0.8))
                            .opacity(isAnimating ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(32, getSafeAreaBottom() + 8))
                }
                .background(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(bottomCardBackground)
                        .shadow(
                            color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.1),
                            radius: 30,
                            y: -10
                        )
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func startTapped() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        hasSeenWelcome = true
    }
    
    // MARK: - Helpers
    
    private func getSafeAreaBottom() -> CGFloat {
        #if canImport(UIKit)
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first else { return 0 }
        return window.safeAreaInsets.bottom
        #else
        return 0
        #endif
    }
    
    // MARK: - Styling
    
    private var background: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.05), Color.black]
                : [Color(red: 0.95, green: 0.96, blue: 0.98), Color.white],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var bottomCardBackground: Color {
        colorScheme == .dark
            ? Color(white: 0.12)
            : .white
    }
    
    private var primaryText: Color {
        colorScheme == .dark ? .white : .primary
    }
}
