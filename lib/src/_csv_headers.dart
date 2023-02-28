import 'exceptions.dart';
import '_helpers.dart';

/// Class used to store CSV headers.
class CsvHeaders {
  CsvHeaders(List<String> headers) : _headers = List.unmodifiable(headers) {
    for (var i = 0; i < _headers.length; i++) {
      _columnCache.putIfAbsent(_headers[i], () => <int>[]).add(i);
    }
  }

  /// Returns the list of headers.
  Iterable<String> get headers => _headers;

  /// Returns the number of headers.
  int get count => _headers.length;

  final List<String> _headers;

  final _columnCache = <String, List<int>>{};

  /// Returns the column index for the specified [header] and [index]. If [header] is an [int], it is
  /// interpreted as the column index. If [header] is a [String], it is used to lookup the header and
  /// find the column index.
  int getHeaderIndex(String header, int index) {
    if (isEmptyOrWhiteSpace(header)) {
      if (index < 0 || index >= _headers.length) {
        throw InvalidHeaderException(
            'Header "$index" out of range (0..${_headers.length - 1})');
      }
      return index;
    }
    final indexes = _columnCache[header];
    if (indexes == null) {
      throw InvalidHeaderException('Header "$header" not found');
    }
    if (index < 0) {
      if (indexes.length > 1) {
        throw InvalidHeaderException(
            'Multiple headers "$header": missing index');
      }
      index = 0;
    }
    if (index < 0 || index >= indexes.length) {
      throw InvalidHeaderException(
          'Out of range index $index for header "$header": valid range is (0..${indexes.length - 1})');
    }
    return indexes[index];
  }
}
