import 'dart:async';

import 'package:csvloader/src/_csv_headers.dart';

import 'csv_data.dart';
import '_helpers.dart';
import '_string_reader.dart';

/// Class used to process CSV data provided a stream of strings. Strings may arrive in variable
/// chunks and the CSV processor will properly parse each row.
class CsvProcessor {
  CsvProcessor(Stream<String> stream, String separator, String endOfLine,
      bool hasHeaders)
      : _separatorRunes = separator.runes.toList(),
        _endOfLine = endOfLine,
        _endOfLineRunes = endOfLine.runes.toList(),
        _hasHeaders = hasHeaders {
    stream.listen(_process, onError: _forwardError, onDone: _close);
  }

  final String _endOfLine;
  final List<int> _endOfLineRunes;
  final List<int> _separatorRunes;
  final bool _hasHeaders;

  final StringReader _reader = StringReader();
  final StreamController<CsvData> _controller = StreamController();

  /// Stream emitting one [CsvData] per non-empty CSV row.
  Stream<CsvData> get stream => _controller.stream;

  /// List of headers loaded from the CSV file (if the processor was constructed with `hasHeaders` = `true`).
  Iterable<String> get headers => _headers?.headers ?? const <String>[];
  CsvHeaders? _headers;

  final _data = <String>[];

  static final _quote = '"';
  static final _quoteRunes = _quote.runes.toList();

  void _forwardError(dynamic error, StackTrace st) =>
      _controller.sink.addError(error, st);

  void _close() => _send(close: true);

  void _send({bool close = false}) {
    if (close) {
      if (_state != _CsvState.newLine) {
        _process(_endOfLine);
      }
    }
    if (hasData(_data)) {
      if (_hasHeaders && _headers == null) {
        _headers = CsvHeaders(_data);
      } else {
        _controller.sink.add(CsvDataImpl.create(_data, _headers));
      }
    }
    _data.clear();
    if (close) {
      _controller.close();
    }
  }

  _CsvState _state = _CsvState.newLine;
  final _sb = StringBuffer();

  void _process(String data) {
    _reader.append(data);
    var process = true;
    while (process && _reader.length > 0) {
      switch (_state) {
        case _CsvState.newLine:
          _state = _CsvState.newValue;
          break;
        case _CsvState.newValue:
          process = _processNewValue();
          break;
        case _CsvState.rawValue:
          process = _processValue();
          break;
        case _CsvState.quotedValue:
          process = _processEscapedValue();
          break;
        case _CsvState.separator:
          process = _processSeparator();
          break;
        case _CsvState.endOfLine:
          process = _processEndOfLine();
          break;
        default:
          throw Exception('Invalid state');
      }
    }
  }

  bool _processNewValue() {
    final match = _reader.isMatchAt(0, _quoteRunes);
    switch (match) {
      case Match.partial:
        // need more characters, suspend processing
        return false;
      case Match.full:
        // remove opening quote
        _reader.discard(_quoteRunes.length);
        _state = _CsvState.quotedValue;
        return true;
      case Match.none:
        _state = _CsvState.rawValue;
        return true;
    }
  }

  bool _processValue() {
    var l = 0, suspend = false;
    while (l < _reader.length) {
      var match = _reader.isMatchAt(l, _separatorRunes);
      if (match == Match.partial) {
        // need more characters, suspend processing
        suspend = true;
        break;
      } else if (match == Match.full) {
        _state = _CsvState.separator;
        break;
      }

      match = _reader.isMatchAt(l, _endOfLineRunes);
      if (match == Match.partial) {
        // need more characters, suspend processing
        suspend = true;
        break;
      } else if (match == Match.full) {
        _state = _CsvState.endOfLine;
        break;
      }

      // continue
      l++;
    }

    // save this part
    if (l > 0) {
      _sb.write(_reader.takeString(l));
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
      if (match == Match.full) {
        match = _reader.isMatchAt(l + _quoteRunes.length, _quoteRunes);
        if (match == Match.full) {
          // unescape and continue
          _sb.write(_reader.takeString(l + _quoteRunes.length));
          _reader.discard(_quoteRunes.length);
          l = 0;
          continue;
        } else if (match == Match.partial) {
          // need more characters, suspend processing
          suspend = true;
          break;
        }

        match = _reader.isMatchAt(l + _quoteRunes.length, _separatorRunes);
        if (match == Match.full) {
          _state = _CsvState.separator;
          break;
        } else if (match == Match.partial) {
          // need more characters, suspend processing
          suspend = true;
          break;
        }

        match = _reader.isMatchAt(l + _quoteRunes.length, _endOfLineRunes);
        if (match == Match.full) {
          _state = _CsvState.endOfLine;
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
      _sb.write(_reader.takeString(l));
    }
    if (_state != _CsvState.quotedValue) {
      // remove closing quote
      _reader.discard(_quoteRunes.length);
    }
    return !suspend;
  }

  bool _processSeparator() {
    _data.add(_sb.toString());
    _sb.clear();
    _reader.discard(_separatorRunes.length);
    _state = _CsvState.newValue;
    return true;
  }

  bool _processEndOfLine() {
    _data.add(_sb.toString());
    _sb.clear();
    _reader.discard(_endOfLineRunes.length);
    _send();
    _state = _CsvState.newLine;
    return true;
  }
}

enum _CsvState {
  newLine,
  newValue,
  rawValue,
  quotedValue,
  separator,
  endOfLine,
}
