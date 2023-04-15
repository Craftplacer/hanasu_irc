import 'dart:convert';

import 'package:characters/characters.dart';

import 'message.dart';

const tagCharacter = '@';
const sourceCharacter = ':';

class IrcMessageDecoder extends Converter<String, RawIrcMessage> {
  const IrcMessageDecoder();

  @override
  RawIrcMessage convert(String input) {
    var characters = input.characters;

    Map<IrcTagKey, String?> tags = const {};
    IrcSource? source;

    if (characters.startsWith(tagCharacter.characters)) {
      characters = characters.skip(1);

      final range = characters.findFirst(" ".characters)!;

      final rawTags = range.charactersBefore.split(";".characters);

      final entries = rawTags.map((e) {
        final kv = e.split("=".characters);
        assert(kv.length == 2);
        return MapEntry(
          IrcTagKey.fromString(kv.first.toString()),
          kv.last.toString(),
        );
      });
      tags = Map.fromEntries(entries);

      characters = range.charactersAfter;
    }

    if (characters.startsWith(sourceCharacter.characters)) {
      characters = characters.skip(1);

      final range = characters.findFirst(" ".characters)!;
      source = IrcSource.fromString(range.charactersBefore.string);

      characters = range.charactersAfter;
    }

    final commandRange = characters.findFirst(" ".characters)!;
    String command = commandRange.stringBefore;
    characters = commandRange.charactersAfter;

    final parameters = _parseParameters(characters).toList();

    return RawIrcMessage(
      command,
      tags: tags,
      source: source,
      parameters: parameters,
    );
  }

  Iterable<String> _parseParameters(Characters input) sync* {
    bool trailing = false;
    final buffer = StringBuffer();

    var i = 0;
    while (true) {
      String? char;

      if (i < input.length) char = input.elementAt(i);

      if (char == ':' && !trailing) {
        trailing = true;
      } else if (char == null || (char == ' ' && !trailing)) {
        yield buffer.toString();
        buffer.clear();
      } else {
        buffer.write(char);
      }

      // no char was provided, index out of bounds
      if (char == null) break;

      i++;
    }
  }
}

class IrcMessageEncoder extends Converter<RawIrcMessage, String> {
  const IrcMessageEncoder();

  @override
  String convert(RawIrcMessage input) {
    final buffer = StringBuffer();

    if (input.tags.isNotEmpty) {
      buffer.write(tagCharacter);

      for (var tag in input.tags.entries) {
        buffer.write(tag.key);
        if (tag.value != null) {
          buffer.write("=");
          buffer.write(tag.value);
        }
      }

      buffer.writeAll(
        input.tags.entries.map(
          (e) {
            return "${e.key}${e.value != null ? "=${e.value}" : ""}";
          },
        ),
        ";",
      );
      buffer.write(" ");
    }

    if (input.source != null) {
      buffer.write(sourceCharacter);
      buffer.write(input.source);
      buffer.write(" ");
    }

    buffer.write(input.command);

    if (input.parameters.isNotEmpty) {
      buffer.write(" ");
      buffer.writeAll(
        input.parameters.map((e) => e.contains(" ") ? ":$e" : e),
        " ",
      );
    }

    return buffer.toString();
  }
}
