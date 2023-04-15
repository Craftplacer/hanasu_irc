import 'package:test/test.dart';

import '../src/raw/escape_codec.dart';

void main() {
  test('test decode invalid backslash', () {
    expect(
      ircEscape.decode(r"\d\"),
      equals("d"),
    );
  });
  test('test escape values', () {
    const escaped = r"\:\s\\\r\na";
    const unescaped = "; \\\r\na";

    final encoded = ircEscape.encode(unescaped);
    expect(encoded, equals(escaped));

    final decoded = ircEscape.decode(escaped);
    expect(decoded, equals(unescaped));
  });
}
