import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:collection/collection.dart';

const ircEscape = IrcEscapeCodec();

const escapePrefix = r"\";
const escapedCharacters = {
  [";", ":"],
  [" ", "s"],
  [r"\", r"\"],
  ["\r", "r"],
  ["\n", "n"],
};

class IrcEscapeEncoder extends Converter<String, String> {
  const IrcEscapeEncoder();

  @override
  String convert(String input) {
    final buffer = StringBuffer();

    for (var i = 0; i < input.length; i++) {
      final character = input[i];

      final escaped =
          escapedCharacters.firstWhereOrNull((e) => e.first == character)?.last;

      if (escaped == null) {
        buffer.write(character);
        continue;
      }

      buffer.write(escapePrefix);
      buffer.write(escaped);
    }

    return buffer.toString();
  }
}

class IrcEscapeDecoder extends Converter<String, String> {
  const IrcEscapeDecoder();

  @override
  String convert(String input) {
    final buffer = StringBuffer();

    bool escaping = false;

    for (var character in input.characters) {
      if (escaping) {
        final escaped = escapedCharacters
            .firstWhereOrNull((e) => e.last == character)
            ?.first;

        escaping = false;

        if (escaped != null) {
          buffer.write(escaped);
          continue;
        }
      }

      if (character == escapePrefix) {
        escaping = true;
        continue;
      }

      buffer.write(character);
    }

    return buffer.toString();
  }
}

class IrcEscapeCodec extends Codec<String, String> {
  const IrcEscapeCodec();

  @override
  Converter<String, String> get decoder => const IrcEscapeDecoder();

  @override
  Converter<String, String> get encoder => const IrcEscapeEncoder();
}
