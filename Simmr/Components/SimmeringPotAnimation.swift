//
//  SimmeringPotAnimation.swift
//  Simmr
//
//  A small looping "pot with rising steam" animation for the recipe
//  generation loader. Built natively in SwiftUI (no Lottie dependency)
//  so it needs no bundled asset and always matches the app's theme.
//

import SwiftUI

struct SimmeringPotAnimation: View {
    /// A lighter tint of the primary coral, used in place of the amber
    /// accent so the pot reads as one warm coral family instead of mixing
    /// in yellow.
    private static let lightCoral = Color(hex: "#FFAD9B")

    @State private var isBreathing = false

    var body: some View {
        ZStack {
            steam
                .offset(y: -46)

            pot
        }
        .onAppear { isBreathing = true }
    }

    /// Each wisp randomizes within its own lane rather than the full width,
    /// so positions vary puff to puff without ever overlapping.
    private static let steamLanes: [ClosedRange<CGFloat>] = [-42...(-16), -13...13, 16...42]

    private var steam: some View {
        ZStack {
            ForEach(0..<Self.steamLanes.count, id: \.self) { index in
                SteamWispView(color: Self.lightCoral, startDelay: Double(index) * 0.5, xRange: Self.steamLanes[index])
            }
        }
    }

    private var pot: some View {
        ZStack {
            HStack {
                Capsule()
                    .fill(Theme.Colors.coral)
                    .frame(width: 20, height: 10)
                Spacer()
                Capsule()
                    .fill(Theme.Colors.coral)
                    .frame(width: 20, height: 10)
            }
            .frame(width: 128)
            .offset(y: -4)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.Colors.coral, Self.lightCoral],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 104, height: 60)
                .scaleEffect(isBreathing ? 1.03 : 1)
                .animation(
                    .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: isBreathing
                )

            RattlingLid(lightCoral: Self.lightCoral)
                .offset(y: -28)
        }
    }
}

/// A single steam curl that fully fades away and reappears a moment later
/// at a new random spot above the lid — like fresh puffs of steam escaping
/// unevenly, rather than a fixed row of streams.
private struct SteamWispView: View {
    let color: Color
    let startDelay: Double
    let xRange: ClosedRange<CGFloat>

    @State private var riseAmount: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var xOffset: CGFloat = 0

    var body: some View {
        SteamWisp()
            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 12, height: 34)
            .opacity(opacity)
            .offset(x: xOffset, y: -20 * riseAmount)
            .task {
                try? await Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000))
                while !Task.isCancelled {
                    xOffset = CGFloat.random(in: xRange)

                    withAnimation(.easeOut(duration: 0.3)) { opacity = 0.85 }
                    withAnimation(.easeInOut(duration: 1.1)) { riseAmount = 1 }
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    if Task.isCancelled { return }

                    withAnimation(.easeIn(duration: 0.4)) { opacity = 0 }
                    try? await Task.sleep(nanoseconds: 450_000_000)
                    if Task.isCancelled { return }

                    riseAmount = 0
                    try? await Task.sleep(nanoseconds: UInt64.random(in: 250_000_000...550_000_000))
                    if Task.isCancelled { return }
                }
            }
    }
}

/// The lid rattles for a couple of beats, settles, then pauses before
/// rattling again — like a real lid jittering under steam pressure in
/// short bursts rather than shaking nonstop.
private struct RattlingLid: View {
    let lightCoral: Color

    @State private var rotation: Double = 0
    @State private var lift: Double = 0

    var body: some View {
        ZStack {
            Capsule()
                .fill(lightCoral)
                .frame(width: 112, height: 10)

            Circle()
                .fill(Theme.Colors.coral)
                .frame(width: 13, height: 13)
                .offset(y: -9)
        }
        .rotationEffect(.degrees(rotation))
        .offset(y: lift)
        .task {
            while !Task.isCancelled {
                for angle in [-3.0, 3.0, -2.5, 2.5, -1.5] {
                    withAnimation(.easeInOut(duration: 0.09)) {
                        rotation = angle
                        lift = -1.5
                    }
                    try? await Task.sleep(nanoseconds: 90_000_000)
                    if Task.isCancelled { return }
                }

                withAnimation(.easeInOut(duration: 0.12)) {
                    rotation = 0
                    lift = 0
                }
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                if Task.isCancelled { return }
            }
        }
    }
}

/// A single wavy steam curl.
private struct SteamWisp: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w / 2, y: h))
        path.addCurve(
            to: CGPoint(x: w / 2, y: h * 0.55),
            control1: CGPoint(x: 0, y: h * 0.85),
            control2: CGPoint(x: w, y: h * 0.7)
        )
        path.addCurve(
            to: CGPoint(x: w / 2, y: 0),
            control1: CGPoint(x: 0, y: h * 0.4),
            control2: CGPoint(x: w, y: h * 0.15)
        )
        return path
    }
}

#Preview {
    SimmeringPotAnimation()
        .frame(width: 160, height: 160)
        .padding()
        .background(Theme.Colors.creamBackground)
}
