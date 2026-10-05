import CodexBarCore
import Foundation
import Testing

@Suite("DeepSeek status feed")
struct DeepSeekStatusTests {
    @Test("resolved newest incident reports operational")
    func resolvedIncident() throws {
        let status = try ProviderStatusFetcher.parseDeepSeekRSSStatus(data: Data(Self.resolvedFeed.utf8))

        #expect(status.indicator == .none)
        #expect(status.description == nil)
        #expect(status.updatedAt != nil)
    }

    @Test("active degraded incident reports a minor issue")
    func degradedIncident() throws {
        let status = try ProviderStatusFetcher.parseDeepSeekRSSStatus(data: Data(Self.degradedFeed.utf8))

        #expect(status.indicator == .minor)
        #expect(status.description == "DeepSeek API Degraded Performance")
    }

    @Test("active partial outage reports a major issue")
    func partialOutage() throws {
        let status = try ProviderStatusFetcher.parseDeepSeekRSSStatus(data: Data(Self.partialOutageFeed.utf8))

        #expect(status.indicator == .major)
        #expect(status.description == "DeepSeek Web/API Partially Unavailable")
    }

    @Test("empty feed reports operational")
    func emptyFeed() throws {
        let status = try ProviderStatusFetcher.parseDeepSeekRSSStatus(
            data: Data("<?xml version=\"1.0\"?><rss><channel></channel></rss>".utf8))

        #expect(status.indicator == .none)
    }

    private static let resolvedFeed = #"""
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0"><channel><item>
      <title>DeepSeek API Degraded Performance</title>
      <description>&lt;p&gt;&lt;strong&gt;Status:&lt;/strong&gt; resolved&lt;/p&gt;</description>
      <pubDate>Fri, 02 Oct 2026 03:40:05 +0800</pubDate>
    </item></channel></rss>
    """#

    private static let degradedFeed = #"""
    <rss><channel><item>
      <title>DeepSeek API Degraded Performance</title>
      <description>&lt;p&gt;&lt;strong&gt;Status:&lt;/strong&gt; investigating&lt;/p&gt;</description>
      <pubDate>Sun, 04 Oct 2026 10:00:00 +0800</pubDate>
    </item></channel></rss>
    """#

    private static let partialOutageFeed = #"""
    <rss><channel><item>
      <title>DeepSeek Web/API Partially Unavailable</title>
      <description>&lt;p&gt;&lt;strong&gt;Status:&lt;/strong&gt; identified&lt;/p&gt;</description>
      <pubDate>Sun, 04 Oct 2026 10:00:00 +0800</pubDate>
    </item></channel></rss>
    """#
}
