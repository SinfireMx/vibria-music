import SwiftUI

// GlobalOverlayManager.swift
class GlobalOverlayManager: ObservableObject {
    static let shared = GlobalOverlayManager()

    @Published var visible: Bool = false
    private var showTime: Date?
    private var minVisibleTime: TimeInterval = 1.0

    // NEW:
    private var inFlight: Int = 0

    func show() {
        inFlight += 1                      // <— ważne
        showTime = Date()
        if !visible { visible = true }
    }

    func hide() {
        // Jeśli coś jeszcze zapisuje – nie gaś bannera
        if inFlight > 0 { inFlight -= 1 }
        guard inFlight == 0 else { return }

        guard let showTime = showTime else { visible = false; return }
        let elapsed = Date().timeIntervalSince(showTime)
        if elapsed < minVisibleTime {
            DispatchQueue.main.asyncAfter(deadline: .now() + (minVisibleTime - elapsed)) { [weak self] in
                // Zgaś tylko, gdy wciąż nic nie zapisuje
                if self?.inFlight == 0 { self?.visible = false }
            }
        } else {
            visible = false
        }
    }
}

