import CodexBarCore
import Foundation
import Testing

@Suite("Google AI Studio status feed")
struct AIStudioStatusTests {
    @Test("extracts the rotating public status key")
    func parsesPublicKey() throws {
        let page = Data(#"<script>{"WIu0Nc":"AIza-test-public-key"}</script>"#.utf8)
        #expect(try ProviderStatusFetcher.parseAIStudioPublicAPIKey(data: page) == "AIza-test-public-key")
    }

    @Test("resolved incident history reports operational")
    func resolvedHistory() throws {
        let payload = #"""
        [[[ ["incident-1", "Resolved incident", 2,
            [[1, "date", ["100"], "Investigating"], [4, "date", ["200"], "Resolved"]]] ]]]
        """#
        let data = Data(payload.utf8)
        let status = try ProviderStatusFetcher.parseAIStudioIncidentHistory(data: data)
        #expect(status.indicator == .none)
        #expect(status.description == nil)
    }

    @Test("active major incident includes the newest update")
    func activeMajorIncident() throws {
        let payload = #"""
        [[[ ["incident-1", "AI Studio outage", 2,
            [[1, "date", ["100"], "Investigating"], [2, "date", ["200"], "Root cause identified"]]] ]]]
        """#
        let data = Data(payload.utf8)
        let status = try ProviderStatusFetcher.parseAIStudioIncidentHistory(data: data)
        #expect(status.indicator == .major)
        #expect(status.description == "Root cause identified")
        #expect(status.updatedAt == Date(timeIntervalSince1970: 200))
    }

    @Test("active minor incident reports degradation")
    func activeMinorIncident() throws {
        let data = Data(#"[[[["incident-1","Elevated errors",1,[[1,"date",["100"],"Investigation is underway"]]]]]]"#
            .utf8)
        let status = try ProviderStatusFetcher.parseAIStudioIncidentHistory(data: data)
        #expect(status.indicator == .minor)
    }
}
