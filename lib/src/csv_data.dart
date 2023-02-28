import 'dart:math' as math show max;
import 'package:meta/meta.dart';

import '_csv_headers.dart';
import 'csv_loader.dart';
import 'exceptions.dart';
import '_helpers.dart';

/// [CsvData] holds the values from a CSV line. If the [CsvLoader] was created with [CsvLoader.withHeaders],
/// it also holds a reference to the list of headers found in the CSV's first non-empty row. Values can
/// be accessed by index (absolute value), or (when created with [CsvLoader.withHeaders]) by header with
/// relative index when necessary (i.e. when several headers have the same label).
///
/// Example:
/// ```dart
/// var csv = CsvLoader.withHeaders(myStream);`
/// await for (CsvData row in csv.rows) {
///   // assuming the stream has headers: Label,Duplicate,Data,Duplicate
///
///   // by absolute index (0-based) --> first column
///   final firstValue = row[0];
///
///   // by header name --> since 'Label' is the first header, same as row[0]
///   final labelValue = row['Label'];
///
///   // by header name --> since 'Data' is the third header, same as row[2]
///   final dataValue = row['Data'];
///
///   // by header and relative index (0-based) --> same as row[0] again
///   final firstLabelValue = row.get('Label', 0);
///
///   // by header and relative index (0-based) --> would throw as there is only one header named 'Label'
///   // final secondLabelValue = row.get('Label', 1);
///
///   // by header and relative index (0-based) --> same as row[3]
///   final secondDuplicateValue = row.get('Duplicate', 1);
///
///   // by header name --> would throw as there is more than one header named 'Duplicate'
///   // final duplicateValue = row['Duplicate'];
///
///   // by header and relative index (0-based) --> would throw as there are only 2 headers named 'Duplicate'
///   // final thirdDuplicateValue = row.get('Duplicate', 2);
/// }
/// ```
class CsvData {
  CsvData._(List<String> values, [this._headers])
      : _values = List.unmodifiable(values);

  final CsvHeaders? _headers;
  final List<String> _values;

  /// List of headers found in the first non-empty line of the CSV data source. This list is populated
  /// if the reader was constructed with [CsvLoader.withHeaders]; otherwise it is empty.
  Iterable<String>? get headers => _headers?.headers;

  /// Count of columns according to the CSV headers; 0 if the reader was NOT constructed with
  /// [CsvLoader.withHeaders].
  int get columnCount => _headers?.count ?? 0;

  /// List of values. Note that `values.length` may be different from [columnCount], e.g. if the reader
  /// was not constructed with [CsvLoader.withHeaders], or the CSV row has more or less values than
  /// headers.
  Iterable<String> get values => _values;

  int _getValueIndex([String header = '', int index = -1]) {
    if (isEmptyOrWhiteSpace(header)) {
      final max = math.max(_headers?.count ?? 0, _values.length);
      if (index < 0 || index >= max) {
        throw InvalidHeaderException(
            'Header "$index" out of range (0..${max - 1})');
      }
      return index;
    } else if (_headers != null) {
      return _headers!.getHeaderIndex(header, index);
    } else {
      throw InvalidHeaderException('Header "$header" not found');
    }
  }

  /// Gets value for [header] from the current record. If [header] is an [int], it is interpreted as the
  /// column index. If [header] is a [String], it is used to lookup the header and find the column index.
  String? operator [](dynamic header) {
    if (header is int) {
      return get('', header);
    } else if (header is String) {
      return get(header, -1);
    } else {
      throw InvalidHeaderException(
          'Invalid header type ${header.runtimeType}: extected int or String');
    }
  }

  /// Gets value for [header] / [index] from the current record. The column index in the CSV record is
  /// retrieved according to [header] and [index]. If [header] is not set, [index] is used as the column
  /// index (starting from 0). If [header] is set, the column index will be retrieved from headers,
  /// provided the reader was constructed with [CsvLoader.withHeaders]. If several headers have the
  /// same label, [index] can be used to distinguish amongst them (starting from 0). If no match is
  /// found, or if [index] is out of bounds, throws an [InvalidHeaderException]. Returns `null` if the
  /// CSV line has fewer values than headers.
  String? get([String header = '', int index = -1]) {
    final idx = _getValueIndex(header, index);
    if (0 <= idx && idx < _values.length) {
      return _values[idx];
    } else {
      return null;
    }
  }
}

// for internal use, do not export
@internal
extension CsvDataImpl on CsvData {
  static CsvData create(List<String> values, [CsvHeaders? headers]) =>
      CsvData._(values, headers);
}
