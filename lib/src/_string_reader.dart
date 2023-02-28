/// Class used to read runes from string chunks.
class StringReader {
  final _runes = <int>[];
  int _discarded = 0;

  /// Returns the total length of the current string chunks.
  int get length => _runes.length - _discarded;

  /// Returns the rune at the specified [index].
  int operator [](int index) => _runes[_discarded + index];

  /// Returns the character at the specified [index].
  String charAt(int index) => String.fromCharCode(this[index]);

  /// Tests whether the current buffer matches the [runes] at [index]. Returns [Match.full]
  /// if there is a match, [Match.partial] if there is a match but the current chunk is too
  /// short, and [Match.none] if there is no match.
  Match isMatchAt(int index, List<int> runes) {
    final l = length, rl = runes.length;
    for (var ridx = 0; ridx < rl; ridx++) {
      if (index >= l) {
        return Match.partial;
      } else if (this[index] != runes[ridx]) {
        return Match.none;
      }
      index++;
    }
    return Match.full;
  }

  /// Discards the first [len] runes from the current chunk.
  void discard(int len) => _discarded += len;

  /// Consumes [len] runes from the current chunk and returns the corresponding [String].
  String takeString(int len) {
    final start = _discarded;
    _discarded += len;
    return String.fromCharCodes(_runes.skip(start).take(len));
  }

  /// Appends runes from [text] to the current chunk.
  void append(String text) {
    if (_discarded > 0) {
      _runes.removeRange(0, _discarded);
      _discarded = 0;
    }
    _runes.addAll(text.runes);
  }
}

enum Match {
  none,
  partial,
  full,
}
