Stream<String> csvStream(List<List<String>> data,
    {List<String>? headers,
    String separator = ',',
    String endOfLine = '\r\n',
    bool withFinalEol = true}) async* {
  if (headers != null) {
    for (var i = 0; i < headers.length; i++) {
      if (i > 0) yield separator;
      var header = headers[i];
      if (header.contains('"') ||
          header.contains(separator) ||
          header.contains(endOfLine)) {
        header = '"${header.replaceAll('"', '""')}"';
      }
      yield header;
    }
    if (data.isNotEmpty || withFinalEol) {
      yield endOfLine;
    }
  }
  for (var i = 0; i < data.length; i++) {
    final row = data[i];
    for (var j = 0; j < row.length; j++) {
      if (j > 0) yield separator;
      var value = row[j];
      if (value.contains('"') ||
          value.contains(separator) ||
          value.contains(endOfLine)) {
        value = '"${value.replaceAll('"', '""')}"';
      }
      yield value;
    }
    if (i < data.length - 1 || withFinalEol) {
      yield endOfLine;
    }
  }
}

Stream<String> chunks(Stream<String> input, int chunkSize) async* {
  final str = await input.join();
  var pos = 0;
  while (pos < str.length) {
    var l = chunkSize;
    if (pos + l > str.length) {
      l = str.length - pos;
    }
    yield str.substring(pos, pos + l);
    pos += l;
  }
}
