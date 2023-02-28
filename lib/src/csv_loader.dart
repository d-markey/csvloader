import 'dart:convert';

import 'csv_data.dart';
import '_csv_processor.dart';

/// [CsvLoader] wraps around a [Stream] and enables reading data in CSV format. Consumers of CSV data
/// can use the [rows] stream to receive each line as a [CsvData] object.
///
/// Example:
/// ```dart
/// var csv = CsvLoader.withHeaders(myStream);`
/// await for (var row in csv.rows) {
///   // do something with the row
/// }
/// ```
class CsvLoader {
  /// Builds a new [CsvLoader] bound to [stream]. [separator] (default is `','`) and [endOfLine] (default
  /// is `'\r\n'`) can be overriden. Using this constructor, data can only be read by index.
  CsvLoader(Stream<String> stream,
      {this.separator = _defSeparator, this.endOfLine = _defEndOfLine})
      : hasHeaders = false {
    _processor = CsvProcessor(stream, separator, endOfLine, hasHeaders);
  }

  /// Builds a new [CsvLoader] bound to [stream]. The first non-empty line from the CSV data source will
  /// be used to populate the [CsvData.headers]; headers are not provided in the [rows] stream. [separator]
  /// (default is `','`) and [endOfLine] (default is `'\r\n'`) can be overriden. Using this constructor,
  /// data may be read by header name and/or index.
  CsvLoader.withHeaders(Stream<String> stream,
      {Encoding encoding = utf8,
      this.separator = _defSeparator,
      this.endOfLine = _defEndOfLine})
      : hasHeaders = true {
    _processor = CsvProcessor(stream, separator, endOfLine, hasHeaders);
  }

  /// `true` if this instance was constructed with [CsvLoader.withHeaders].
  final bool hasHeaders;

  static const String _defSeparator = ',';

  /// Separator character; default is `','`.
  final String separator;

  static const String _defEndOfLine = '\r\n';

  /// End-of-line character; default is `'\r\n'`.
  final String endOfLine;

  late final CsvProcessor _processor;

  /// List of headers found in the first non-empty line of the CSV data source. This list is populated
  /// if the reader was constructed with [CsvLoader.withHeaders]; otherwise it is empty.
  Iterable<String> get headers => _processor.headers;

  /// Stream of [CsvData]; empty rows from the CSV data source are ignored.
  Stream<CsvData> get rows => _processor.stream;
}
