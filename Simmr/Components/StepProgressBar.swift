//
//  StepProgressBar.swift
//  Simmr
//

import SwiftUI

struct StepProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.border)

                Capsule()
                    .fill(Theme.Colors.coral)
                    .frame(width: proxy.size.width * progress)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    StepProgressBar(progress: 0.4)
        .padding()
        .background(Theme.Colors.creamBackground)
}
