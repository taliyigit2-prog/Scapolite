import Testing
@testable import CodexBar

struct ScapoliteTelegramCommandTests {
    @Test("parses supported commands and bot suffixes")
    func parsesCommands() {
        #expect(ScapoliteTelegramCommand.parse("/start") == .help)
        #expect(ScapoliteTelegramCommand.parse("/status@ScapoliteBot") == .status)
        #expect(ScapoliteTelegramCommand.parse("/usage now") == .usage)
        #expect(ScapoliteTelegramCommand.parse("/sessions") == .sessions)
        #expect(ScapoliteTelegramCommand.parse("/system") == .system)
        #expect(ScapoliteTelegramCommand.parse("/refresh") == .refresh)
    }

    @Test("ignores ordinary messages")
    func ignoresMessages() {
        #expect(ScapoliteTelegramCommand.parse("hello") == nil)
        #expect(ScapoliteTelegramCommand.parse(nil) == nil)
    }

    @Test("preserves unknown slash commands")
    func unknownCommands() {
        #expect(ScapoliteTelegramCommand.parse("/ping") == .unknown("/ping"))
    }
}
