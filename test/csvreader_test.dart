import 'package:csvloader/csvloader.dart';
import 'package:csvloader/src/_helpers.dart';
import 'package:test/test.dart';

import 'streamers.dart';

final settingsHeaders = ['Section', 'Setting', 'Value', 'Comment'];

final settings = [
  ['Server', 'HTTP Port', '', 'Unencrypted channel'],
  ['Server', 'HTTPS Port', '443', 'Encrypted channel'],
  ['Server', 'User', 'admin', 'Process user'],
  ['Database', 'ConnectionString', 'db=DB_NAME;user=reader;pwd=***', ''],
  ['Environment', 'Type', 'QA', 'Environment type'],
  ['Environment', 'Password', '', ''],
  ['Environment', 'OS', '', 'Operating system'],
];

Stream<String> _characters(Stream<String> input) => chunks(input, 1);

Stream<String> _chunks(Stream<String> input) => chunks(input, 7);

Stream<String> _full(Stream<String> input) => chunks(input, 1 << 31);

void main() {
  group('CSV without headers', () {
    runTests(settings);
  });

  group('CSV without headers (characters)', () {
    runTests(settings, transformation: _characters);
  });

  group('CSV without headers (chunked)', () {
    runTests(settings, transformation: _chunks);
  });

  group('CSV without headers (full)', () {
    runTests(settings, transformation: _full);
  });

  group('CSV with headers', () {
    runTests(settings, headers: settingsHeaders);
  });

  group('CSV with headers (characters)', () {
    runTests(settings, headers: settingsHeaders, transformation: _characters);
  });

  group('CSV with headers (chunked)', () {
    runTests(settings, headers: settingsHeaders, transformation: _chunks);
  });

  group('CSV with headers (full)', () {
    runTests(settings, headers: settingsHeaders, transformation: _full);
  });
}

void runTests(List<List<String>> data,
    {List<String>? headers,
    Stream<String> Function(Stream<String> input)? transformation}) {
  test('default', () async {
    await runTest(data, headers: headers, transformation: transformation);
  });

  test('without final EOL', () async {
    await runTest(data,
        headers: headers, withFinalEol: false, transformation: transformation);
  });

  test('semi-colon separator', () async {
    await runTest(data,
        headers: headers, separator: ';', transformation: transformation);
  });

  test('multi-char separator', () async {
    await runTest(data,
        headers: headers, separator: '***', transformation: transformation);
  });

  test('LF endOfLine', () async {
    await runTest(data,
        headers: headers, endOfLine: '\n', transformation: transformation);
    await runTest(data,
        headers: headers,
        endOfLine: '\n',
        withFinalEol: false,
        transformation: transformation);
  });

  test('multi-char endOfLine', () async {
    await runTest(data,
        headers: headers,
        endOfLine: '\r\n===[new line]===\r\n',
        transformation: transformation);
    await runTest(data,
        headers: headers,
        endOfLine: '\r\n===[new line]===\r\n',
        withFinalEol: false,
        transformation: transformation);
  });

  test('custom separator & endOfLine', () async {
    await runTest(data,
        headers: headers,
        separator: ' ',
        endOfLine: '\t\t',
        transformation: transformation);
    await runTest(data,
        headers: headers,
        separator: ' ',
        endOfLine: '\t\t',
        withFinalEol: false,
        transformation: transformation);
  });

  test('last cell empty', () async {
    final lastRow = data.last.toList();
    lastRow[lastRow.length - 1] = '';
    final withEmptyLastCell = data.followedBy([lastRow]).toList();
    await runTest(withEmptyLastCell,
        headers: headers, transformation: transformation);
    await runTest(withEmptyLastCell,
        headers: headers, withFinalEol: false, transformation: transformation);
  });

  test('last row empty', () async {
    final row = data.last.toList();
    for (var i = 0; i < row.length; i++) {
      row[i] = '';
    }
    final dataWithEmptyRows = [row, ...data.take(2), row, ...data.skip(2), row];
    await runTest(dataWithEmptyRows,
        headers: headers, transformation: transformation);
    await runTest(dataWithEmptyRows,
        headers: headers, withFinalEol: false, transformation: transformation);
  });

  test('rows with less values', () async {
    final row = data.last.toList();
    row.removeAt(0);
    final dataWithShorterRows = [
      row,
      ...data.take(2),
      row,
      ...data.skip(2),
      row
    ];
    await runTest(dataWithShorterRows,
        headers: headers, transformation: transformation);
    await runTest(dataWithShorterRows,
        headers: headers, withFinalEol: false, transformation: transformation);
  });

  test('rows with more values', () async {
    final row = data.last.toList();
    row.add('extra value');
    final dataWithLongerRows = [
      row,
      ...data.take(2),
      row,
      ...data.skip(2),
      row
    ];
    await runTest(dataWithLongerRows,
        headers: headers, transformation: transformation);
    await runTest(dataWithLongerRows,
        headers: headers, withFinalEol: false, transformation: transformation);
  });

  test('rows with same header', () async {
    final dupHeaders = ['#Line', 'Value', 'Value', 'Value'];
    final dupData = [
      ['#1', '1', '2', '3'],
      ['#2', '3', '4', '5'],
    ];
    await runTest(dupData, headers: dupHeaders, transformation: transformation);
    await runTest(dupData,
        headers: dupHeaders,
        withFinalEol: false,
        transformation: transformation);
  });
}

Future runTest(List<List<String>> data,
    {List<String>? headers,
    String separator = ',',
    String endOfLine = '\r\n',
    bool withFinalEol = true,
    Stream<String> Function(Stream<String> input)? transformation}) async {
  var stream = csvStream(data,
      headers: headers ?? [],
      separator: separator,
      endOfLine: endOfLine,
      withFinalEol: withFinalEol);
  if (transformation != null) {
    stream = transformation(stream);
  }

  final csv = (headers == null)
      ? CsvLoader(stream, separator: separator, endOfLine: endOfLine)
      : CsvLoader.withHeaders(stream,
          separator: separator, endOfLine: endOfLine);
  List<String>? head;
  final headIdx = <String, List<int>>{};
  final rows = <List<String>>[];
  await for (var row in csv.rows) {
    if (headers != null && head == null) {
      expect(csv.headers, equals(headers));
      expect(row.headers, equals(headers));
      head = csv.headers.toList();
      for (var i = 0; i < head.length; i++) {
        final idx = headIdx.putIfAbsent(head[i], () => []);
        idx.add(i);
      }
    }
    final copy = row.values.toList();
    rows.add(copy);
    for (var i = 0; i < copy.length; i++) {
      expect(row[i], equals(copy[i]));
    }
    if (headers != null) {
      final invalidMatch = throwsA(isA<InvalidHeaderException>());
      for (var h in headers) {
        var idx = headIdx[h]!;
        for (var j = 0; j < idx.length; j++) {
          final i = idx[j];
          final match = (0 <= i && i < copy.length) ? equals(copy[i]) : isNull;
          if (idx.length == 1) {
            expect(row[h], match);
            expect(row.get(h), match);
            expect(row.get(h, j), match);
          } else {
            expect(() => row[h], invalidMatch);
            expect(() => row.get(h), invalidMatch);
            expect(row.get(h, j), match);
          }
        }
      }
    }
  }

  final rowsWithData = data.where((r) => hasData(r)).toList();

  expect(rows.length, equals(rowsWithData.length));
  for (var i = 0; i < rowsWithData.length; i++) {
    expect(rows[i], equals(rowsWithData[i]));
  }
}
