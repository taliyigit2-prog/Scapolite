import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct ScapoliteServiceTransitionTests {
    private let service = ScapoliteMonitoredService(
        id: "test",
        name: "Test AI",
        statusURL: URL(string: "https://status.example.com")!,
        source: .statuspage(URL(string: "https://status.example.com")!))

    @Test("initial status establishes a baseline without alerting")
    func initialBaseline() {
        let current = self.health(.major)
        #expect(ScapoliteServiceTransitionPolicy.transition(previous: nil, current: current) == nil)
    }

    @Test("unchanged status does not alert")
    func unchangedStatus() {
        let previous = self.health(.minor)
        let current = self.health(.minor)
        #expect(ScapoliteServiceTransitionPolicy.transition(previous: previous, current: current) == nil)
    }

    @Test("unknown states never produce outage or recovery alerts")
    func unknownStates() {
        #expect(ScapoliteServiceTransitionPolicy.transition(
            previous: self.health(.unknown),
            current: self.health(.none)) == nil)
        #expect(ScapoliteServiceTransitionPolicy.transition(
            previous: self.health(.none),
            current: self.health(.unknown)) == nil)
    }

    @Test("outage and recovery changes alert")
    func changesAlert() throws {
        let healthy = self.health(.none)
        let outage = self.health(.critical)
        let outageTransition = try #require(
            ScapoliteServiceTransitionPolicy.transition(previous: healthy, current: outage))
        #expect(outageTransition.previous.indicator == .none)
        #expect(outageTransition.current.indicator == .critical)

        let recoveryTransition = try #require(
            ScapoliteServiceTransitionPolicy.transition(previous: outage, current: healthy))
        #expect(recoveryTransition.previous.indicator == .critical)
        #expect(recoveryTransition.current.indicator == .none)
    }

    private func health(_ indicator: ProviderStatusIndicator) -> ScapoliteServiceHealth {
        ScapoliteServiceHealth(
            service: self.service,
            indicator: indicator,
            detail: nil,
            updatedAt: Date(timeIntervalSince1970: 100))
    }
}
