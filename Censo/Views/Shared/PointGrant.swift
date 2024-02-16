//
//  PointGrant.swift
//  Censo
//
//  Created by Ben Holzman on 2/15/24.
//

import SwiftUI
import Lottie

struct PointGrant: View {
    var startingPoints: Int
    var deltaPoints: Int
    @State private var xpos: CGFloat = 0
    @State private var ypos: CGFloat = 0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var pointsShown: Int = 0
    @State private var startDate = Date.now
    @State private var showDelta = true
    private let deltaFlyDuration = 1.5
    private let pointChangeDuration = 1.5
    private let overlap = 0.08
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                LottieView()
                VStack {
                    HStack(spacing: 0) {
                        VStack {
                            Text("\(pointsShown)")
                                .font(.title.bold())
                                .foregroundStyle(.red)
                                .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16.0)
                                .foregroundStyle(Color.yellow)
                        )
                    }
                }
                .background(Color.white)
                if (showDelta) {
                    VStack {
                        Text("+\(deltaPoints)")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.red)
                    }
                    .position(x: xpos, y: ypos)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                xpos = geometry.size.width / 2
                pointsShown = startingPoints
                startDate = Date.now
                withAnimation(.easeIn(duration: deltaFlyDuration)) {
                    ypos = geometry.size.height - 40
                }
            }
            .onReceive(timer) { firedDate in
                let delta = firedDate.timeIntervalSince(startDate)
                if (delta >= deltaFlyDuration + pointChangeDuration - overlap) {
                    pointsShown = startingPoints + deltaPoints
                    timer.upstream.connect().cancel()
                } else if (delta > deltaFlyDuration - overlap) {
                    pointsShown = Int(Double(startingPoints) + (((delta + overlap - deltaFlyDuration) / pointChangeDuration) * Double(deltaPoints)))
                    if (delta > deltaFlyDuration) {
                        showDelta = false
                    }
                }
            }
        }
    }
}

struct LottieView: UIViewRepresentable {
    var name = "success"
    var loopMode: LottieLoopMode = .playOnce

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(name)
        animationView.animation = animation
        animationView.contentMode = .scaleAspectFill
        animationView.loopMode = loopMode
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}

#if DEBUG
#Preview {
    ZStack {
        OperationCompletedView(
            successText: "Thanks for helping someone keep their crypto safe.",
            onSuccess: {}
        ).foregroundColor(Color.Censo.primaryForeground)
        PointGrant(startingPoints: 150, deltaPoints: 100)
    }
}
#endif
