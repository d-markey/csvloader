String dump(dynamic str) {
  if (str == null) return '<<>>';
  if (str is List<int>) str = String.fromCharCodes(str);
  if (str is List) return str.map(dump).toString();
  if (str is! String) str = str.toString();
  return '<<' + str.replaceAll('\r', '\\r').replaceAll('\n', '\\n') + '>>';
}

bool isNullOrEmpty(String? str) => str?.trim().isEmpty ?? true;

bool hasData(List row) => row.any((data) => !isNullOrEmpty(data?.toString()));
