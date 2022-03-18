import 'exceptions.dart';

class CsvHeaders {
  CsvHeaders(this._headers);

  final List<String> _headers;

  Iterable<String> get headers => _headers;

  int get count => _headers.length;

  final _columnCache = <String, List<int>>{};

  static bool _isEmpty(dynamic str) => (str?.toString() ?? '').trim().isEmpty;

  void _buildColumnCache() {
    for (var i = 0; i < _headers.length; i++) {
      final list = _columnCache.putIfAbsent(_headers[i], () => <int>[]);
      list.add(i);
    }
  }

  int getHeaderIndex(String header, int index) {
    if (_isEmpty(header)) {
      if (index < 0 || index >= _headers.length) {
        throw InvalidHeaderException(
            'Header "$index" out of range (0..${_headers.length - 1})');
      }
      return index;
    }
    if (_columnCache.isEmpty) {
      _buildColumnCache();
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
    } else if (indexes.isNotEmpty && (index < 0 || index >= indexes.length)) {
      throw InvalidHeaderException(
          'Multiple headers "$header": index $index is out of range (0..${indexes.length - 1})');
    }
    return indexes[index];
  }
}
