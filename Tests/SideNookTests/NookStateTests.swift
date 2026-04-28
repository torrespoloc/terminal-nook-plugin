// Tests/SideNookTests/NookStateTests.swift
import Testing
@testable import SideNook

@Suite("NookState")
@MainActor
struct NookStateTests {

    @Test("starts collapsed")
    func startsCollapsed() {
        let state = NookState()
        #expect(state.isExpanded == false)
    }

    @Test("expand sets isExpanded true")
    func expandSetsTrue() {
        let state = NookState()
        state.expand()
        #expect(state.isExpanded == true)
    }

    @Test("collapse sets isExpanded false")
    func collapseSetsTrue() {
        let state = NookState()
        state.expand()
        state.collapse()
        #expect(state.isExpanded == false)
    }

    @Test("toggle flips state")
    func toggleFlips() {
        let state = NookState()
        state.toggle()
        #expect(state.isExpanded == true)
        state.toggle()
        #expect(state.isExpanded == false)
    }
}
