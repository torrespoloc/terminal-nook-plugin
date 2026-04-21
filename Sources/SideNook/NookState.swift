// Sources/SideNook/NookState.swift
import Observation

@MainActor
@Observable
final class NookState {
    var isExpanded: Bool = false

    func expand()   { isExpanded = true }
    func collapse() { isExpanded = false }
    func toggle()   { isExpanded.toggle() }
}
