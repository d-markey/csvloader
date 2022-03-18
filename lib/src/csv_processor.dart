import 'dart:async';

import 'package:csvloader/src/csv_headers.dart';

import 'csv_data.dart';
import 'helpers.dart';

class CsvProcessor {
  CsvProcessor(Stream<String> stream, String separator, String endOfLine,
      bool hasHeaders)
      : _input = stream,
        _separatorRunes = separator.runes.toList(),
        _endOfLine = endOfLine,
        _endOfLineRunes = endOfLine.runes.toList(),
        _hasHeaders = hasHeaders {
    _input.listen(_process).onDone(() => _send(close: true));
  }

  final Stream<String> _input;
  final String _endOfLine;
  final List<int> _endOfLineRunes;
  final List<int> _separatorRunes;
  final bool _hasHeaders;

  final StringReader _reader = StringReader();
  final StreamController<CsvData> _controller = StreamController();

  Stream<CsvData> get stream => _controller.stream;

  CsvHeaders? _headers;

  Iterable<String>? get headers => _headers?.headers;

  final _data = <String>[];

  static final _quote = '"';
  static final _quoteRunes = _quote.runes.toList();

  void _send({bool close = false}) {
    if (close) {
      if (_state != CsvState.newLine) {
        _process(_endOfLine);
      }
      //   print('close: state = $_state, sr = ${dump(_sr._runes)}, sb = ${dump(_sb)}, _data = ${dump(_data)}');
      // } else {
      //   print('send: state = $_state, sr = ${dump(_sr._runes)}, sb = ${dump(_sb)}, _data = ${dump(_data)}');
    }
    if (hasData(_data)) {
      if (_hasHeaders && _headers == null) {
        _headers = CsvHeaders(_data.toList());
      } else {
        _controller.sink.add(createCsvData(_data.toList(), _headers));
      }
    }
    _data.clear();
    if (close) {
      _controller.close();
    }
  }

  CsvState _state = CsvState.newLine;
  final _sb = StringBuffer();

  void _process(String data) {
    _reader.append(data);
    var process = true;
    while (process && _reader.length > 0) {
      // print('state = $_state, sr = ${dump(_sr._runes)}, sb = ${dump(_sb)}, _data = ${dump(_data)}');
      switch (_state) {
        case CsvState.newLine:
          _state = CsvState.newValue;
          break;
        case CsvState.newValue:
          process = _processNewValue();
          break;
        case CsvState.rawValue:
          process = _processValue();
          break;
        case CsvState.quotedValue:
          process = _processEscapedValue();
          break;
        case CsvState.separator:
          process = _processSeparator();
          break;
        case CsvState.endOfLine:
          process = _processEndOfLine();
          break;
        default:
          throw Exception('Invalid state');
      }
      // if (!process) {
      //   print('suspend processing: state = $_state, sr = ${dump(_sr._runes)}, sb = ${dump(_sb)}, _data = ${dump(_data)}');
      // }
    }
  }

  bool _processNewValue() {
    final match = _reader.isMatchAt(0, _quoteRunes);
    switch (match) {
      case Match.partial:
        // need more characters, suspend processing
        return false;
      case Match.exact:
        // remove opening quote
        _reader.remove(0, _quoteRunes.length);
        _state = CsvState.quotedValue;
        return true;
      case Match.none:
        _state = CsvState.rawValue;
        return true;
    }
  }

  bool _processValue() {
    var l = 0;
    bool suspend = false;
    while (l < _reader.length) {
      var match = _reader.isMatchAt(l, _separatorRunes);
      if (match == Match.partial) {
        // need more characters, suspend processing
        suspend = true;
        break;
      } else if (match == Match.exact) {
        _state = CsvState.separator;
        break;
      }

      match = _reader.isMatchAt(l, _endOfLineRunes);
      if (match == Match.partial) {
        // need more characters, suspend processing
        suspend = true;
        break;
      } else if (match == Match.exact) {
        _state = CsvState.endOfLine;
        break;
      }

      // continue
      l++;
    }

    // save this part
    if (l > 0) {
      _sb.write(_reader.getString(0, l));
      _reader.remove(0, l);
    }
    return !suspend;
  }

  bool _processEscapedValue() {
    var l = 0;
    var suspend = false;
    while (l < _reader.length) {
      var match = _reader.isMatchAt(l, _quoteRunes);
      if (match == Match.partial) {
        // need more characters, suspend processing
        suspend = true;
        break;
      }
      if (match == Match.exact) {
        match = _reader.isMatchAt(l + _quoteRunes.length, _quoteRunes);
        if (match == Match.exact) {
          // unescape and continue
          _sb.write(_reader.getString(0, l + _quoteRunes.length));
          _reader.remove(0, l + 2 * _quoteRunes.length);
          l = 0;
          continue;
        } else if (match == Match.partial) {
          // need more characters, suspend processing
          suspend = true;
          break;
        }

        match = _reader.isMatchAt(l + _quoteRunes.length, _separatorRunes);
        if (match == Match.exact) {
          _state = CsvState.separator;
          break;
        } else if (match == Match.partial) {
          // need more characters, suspend processing
          suspend = true;
          break;
        }

        match = _reader.isMatchAt(l + _quoteRunes.length, _endOfLineRunes);
        if (match == Match.exact) {
          _state = CsvState.endOfLine;
          break;
        } else if (match == Match.partial) {
          // need more characters, suspend processing
          suspend = true;
          break;
        }

        // malformed: ignore and continue
        l++;
      } else {
        // continue
        l++;
      }
    }

    if (l > 0) {
      // save this part
      _sb.write(_reader.getString(0, l));
      _reader.remove(0, l);
    }
    if (_state != CsvState.quotedValue) {
      // remove closing quote
      _reader.remove(0, _quoteRunes.length);
    }
    return !suspend;
  }

  bool _processSeparator() {
    _data.add(_sb.toString());
    _sb.clear();
    _reader.remove(0, _separatorRunes.length);
    _state = CsvState.newValue;
    return true;
  }

  bool _processEndOfLine() {
    _data.add(_sb.toString());
    _sb.clear();
    _reader.remove(0, _endOfLineRunes.length);
    _send();
    _state = CsvState.newLine;
    return true;
  }
}

enum CsvState {
  newLine,
  newValue,
  rawValue,
  quotedValue,
  separator,
  endOfLine,
}

enum Match {
  none,
  partial,
  exact,
}

class StringReader {
  final _runes = <int>[];

  int get length => _runes.length;

  String charAt(int idx) => String.fromCharCode(_runes[idx]);

  int operator [](int idx) => _runes[idx];

  Match isMatchAt(int idx, List<int> runes) {
    final l = length;
    final rl = runes.length;
    for (var ridx = 0; ridx < rl; ridx++) {
      if (idx >= l) {
        return Match.partial;
      } else if (_runes[idx] != runes[ridx]) {
        return Match.none;
      }
      idx++;
    }
    return Match.exact;
  }

  void remove(int start, int end) => _runes.removeRange(start, end);

  String getString(int start, int end) =>
      String.fromCharCodes(_runes, start, end);

  void append(String text) => _runes.addAll(text.runes);
}
