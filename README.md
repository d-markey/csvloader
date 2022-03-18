# csvloader

Lightweight, cross-platform Dart package to read CSV data from a `Stream`. Supports and extends RFC 4180.

# Usage

```dart
import 'package:csvloader/csvloader.dart';

Stream<String> catalog() async* {
  // CsvLoader will unescape data between quotes
  yield 'Part code\tPart label\tDescription\r\n';
  yield 'B1XX\tBolt\t"Your average bolt"\r\n';
  yield 'S2XX\tScrew\t"Your average screw"\r\n';
  yield 'N1XX\tNut\t"Nut; for bolts ""B1XX"""\r\n';
  yield '9N\tNail\t"A 9"" nail"\r\n';
}

void main() async {
  // use "tab" as separator
  final catalogCsv = CsvLoader.withHeaders(catalog(), separator: '\t');

  await for (var row in catalogCsv.rows) {
    final code = row['Part code'];
    final label = row['Part label'];
    final descr = row['Description'];
    print(' - $label ($code): $descr');
  }
}
}
```
