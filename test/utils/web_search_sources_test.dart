import 'package:flutter_test/flutter_test.dart';
import 'package:lm_mini/models/chat_message.dart';
import 'package:lm_mini/utils/web_search_sources.dart';

void main() {
  group('WebSearchSources.parse', () {
    test('reads SearXNG numbered markdown', () {
      const text = '''
**Web Search Results (SearXNG) for "solana price":**

1. **Solana price today**
   SOL is trading at \$101.57
   🔗 https://coinmarketcap.com/currencies/solana/

2. **SOLUSD**
   Live chart
   🔗 https://www.tradingview.com/symbols/SOLUSD/

---
✨ Powered by SearXNG
''';
      final sources = WebSearchSources.parse(text);
      expect(sources, hasLength(2));
      expect(sources[0].siteName, 'Coinmarketcap');
      expect(sources[0].host, 'coinmarketcap.com');
      expect(sources[0].title, 'Solana price today');
      expect(sources[1].siteName, 'Tradingview');
      expect(sources[1].url, contains('tradingview.com'));
    });

    test('reads MCP JSON text parts', () {
      const text = '''
[{"type":"text","text":"1. **Bitcoin Price**\\n   BTC news\\n   🔗 https://www.coindesk.com/price/bitcoin\\n"}]
''';
      final sources = WebSearchSources.parse(text);
      expect(sources, isNotEmpty);
      expect(sources.first.host, 'coindesk.com');
      expect(sources.first.siteName, 'Coindesk');
    });

    test('reads Source: URL lines', () {
      const text = '''
Solana hits \$100
Source: https://www.theblock.co/post/solana
''';
      final sources = WebSearchSources.parse(text);
      expect(sources, hasLength(1));
      expect(sources.first.host, 'theblock.co');
      expect(sources.first.title, 'Solana hits \$100');
    });

    test('reads results JSON array', () {
      const text = '''
{"results":[{"title":"Wiki","url":"https://en.wikipedia.org/wiki/Solana","snippet":"A blockchain"}]}
''';
      final sources = WebSearchSources.parse(text);
      expect(sources, hasLength(1));
      expect(sources.first.siteName, 'Wikipedia');
      expect(sources.first.snippet, 'A blockchain');
    });

    test('strips MCP result prefix', () {
      const text =
          '✅ MCP result (web_search): 1. **Hello**\n   World\n   🔗 https://example.com/page\n';
      final sources = WebSearchSources.parse(text);
      expect(sources, hasLength(1));
      expect(sources.first.host, 'example.com');
      expect(sources.first.siteName, 'Example');
    });
  });

  group('WebSearchSources.fromMessages', () {
    test('pairs MCP call with result', () {
      final call = ChatMessage(
        id: '1',
        content: '🔧 MCP call: web_search@lmmini-search',
        role: 'assistant',
        timestamp: DateTime.now(),
      );
      final result = ChatMessage(
        id: '2',
        content:
            '✅ MCP result (web_search): 1. **Price**\n   note\n   🔗 https://www.binance.com/en/price/solana\n',
        role: 'tool',
        timestamp: DateTime.now(),
      );
      final sources = WebSearchSources.fromMessages([call, result]);
      expect(sources, hasLength(1));
      expect(sources.first.siteName, 'Binance');
    });

    test('dedupes the same host path', () {
      const text = '''
1. **A**
   x
   🔗 https://www.example.com/a
1. **B**
   y
   🔗 https://example.com/a
''';
      final sources = WebSearchSources.parse(text);
      expect(sources, hasLength(1));
    });
  });

  test('site name handles bbc.co.uk', () {
    final source = WebSearchSources.fromUrl('https://www.bbc.co.uk/news');
    expect(source?.siteName, 'Bbc');
    expect(source?.host, 'bbc.co.uk');
  });
}
