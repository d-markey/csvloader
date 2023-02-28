String dump(dynamic str) {
  if (str == null) return '<<>>';
  if (str is List<int>) str = String.fromCharCodes(str);
  if (str is List) return str.map(dump).toString();
  if (str is! String) str = str.toString();
  return '<<${str.replaceAll('\r', '\\r').replaceAll('\n', '\\n')}>>';
}

final _whiteSpaces = Set.unmodifiable({
  // new line characters
  '\f'.runes.first,
  '\n'.runes.first,
  '\r'.runes.first,
  '\v'.runes.first,
  '\u0085'.runes.first,
  '\u2028'.runes.first,
  '\u2029'.runes.first,
  // blank characters
  ' '.runes.first,
  '\t'.runes.first,
  '\u00A0'.runes.first,
  '\u1680'.runes.first,
  '\u2000'.runes.first,
  '\u2001'.runes.first,
  '\u2002'.runes.first,
  '\u2003'.runes.first,
  '\u2004'.runes.first,
  '\u2005'.runes.first,
  '\u2006'.runes.first,
  '\u2007'.runes.first,
  '\u2008'.runes.first,
  '\u2009'.runes.first,
  '\u200A'.runes.first,
  '\u202F'.runes.first,
  '\u205F'.runes.first,
  '\u3000'.runes.first,
});

bool isWhiteSpace(int rune) => _whiteSpaces.contains(rune);

bool isEmptyOrWhiteSpace(String str) =>
    str.isEmpty || str.runes.every(isWhiteSpace);

bool isNotEmptyOrWhiteSpace(String str) => !isEmptyOrWhiteSpace(str);

bool hasData(List<String> row) => row.any(isNotEmptyOrWhiteSpace);
