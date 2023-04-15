import 'package:hanasu_irc/irc/src/raw/message_codec.dart';
import 'package:test/test.dart';

void main() {
  test('test parameter decoding', () {
    final cases = {
      ":irc.example.com CAP * LIST :": ["*", "LIST", ""],
      "CAP * LS :multi-prefix sasl": ["*", "LS", "multi-prefix sasl"],
      "CAP REQ :sasl message-tags foo": ["REQ", "sasl message-tags foo"],
      ":dan!d@localhost PRIVMSG #chan :Hey!": ["#chan", "Hey!"],
      ":dan!d@localhost PRIVMSG #chan Hey!": ["#chan", "Hey!"],
      ":dan!d@localhost PRIVMSG #chan ::-)": ["#chan", ":-)"],
    };
    for (var testCase in cases.entries) {
      final expected = testCase.value;
      final actual = const IrcMessageDecoder().convert(testCase.key).parameters;
      expect(actual, orderedEquals(expected));
    }
  });
}
