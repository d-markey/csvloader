import 'dart:math';

import 'package:csvloader/csvloader.dart';

void main() async {
  await readNumbers();
  await readFamilies();
  await readCatalog();
}

Stream<String> numbers() async* {
  // CsvLoader accomodates for streams yielding partial entries
  yield 'Number,Odd?,Even?,Square?,Prime?\r\n0,false,tr';
  yield 'ue,true,false\r\n1,true,false,true,false\r\n2,';
  yield 'false,true,false,true\r\n3,true,false,false,true\r';
  yield '\n3.5,false,false,false,false\r\n4,false,true,tru';
  yield 'e,false\r\n9,true,false,true,false';
}

Future readNumbers() async {
  print('Reading numbers...');
  final numbersCsv = CsvLoader.withHeaders(numbers());

  final props = <String>[];

  await for (var row in numbersCsv.rows) {
    final n = num.parse(row['Number'] ?? '');
    final odd = (row['Odd?'] == 'true');
    final even = (row['Even?'] == 'true');
    final square = (row['Square?'] == 'true');
    final prime = (row['Prime?'] == 'true');

    props.clear();

    if (odd && !even) {
      props.add('$n is odd.');
    } else if (!odd && even) {
      props.add('$n is even.');
    } else {
      props.add(
          '$n is strange, it is ${odd ? 'odd' : 'not odd'} and ${even ? 'even' : 'not even'}.');
    }

    if (square) {
      props.add('$n is the square of ${sqrt(n).toInt()}.');
    }

    if (prime) {
      props.add('$n is prime.');
    }

    print('   ${props.join(' ')}');
  }
}

Stream<String> families() async* {
  // CsvLoader supports duplicate header labels
  yield 'Name,First name,Father name,First name,Mother name,First name\r\n';
  // CsvLoader ignores empty lines
  yield '\r\n';
  yield ' \r\n';
  yield ',,,,\r\n';
  yield ' , , , , \r\n';
  yield ',\t,\t,\t,\r\n';
  yield 'Doe,Jeffrey,Doe,John,Smith,Ann\r\n';
  yield 'Doe,Martin,Doe,John,Smith,Ann\r\n';
  yield 'Doe,Mary Ann,Doe,John,Smith,Ann\r\n';
  yield '\r\n';
  yield 'Doe,Jerry,Doe,John,Jones,Jennifer\r\n';
  yield '\r\n';
  yield 'Fergusson,Jack,Fergusson,Robert,Smith,Ann\r\n';
  yield '\r\n';
}

Future readFamilies() async {
  print('Reading families...');
  final familyCsv = CsvLoader.withHeaders(families());

  final tree = <String, Map<String, List<String>>>{};

  await for (var row in familyCsv.rows) {
    final child = '${row.get('First name', 0)} ${row['Name']}';
    final father = '${row.get('First name', 1)} ${row['Father name']}';
    final mother = '${row.get('First name', 2)} ${row['Mother name']}';

    final fatherSpouses = tree.putIfAbsent(father, () => {});
    final spouseChildren = fatherSpouses.putIfAbsent(mother, () => []);
    spouseChildren.add(child);
  }

  for (var fatherEntry in tree.entries) {
    final father = fatherEntry.key;
    for (var spouseEntry in fatherEntry.value.entries) {
      final mother = spouseEntry.key;
      final children = spouseEntry.value;
      print(
          '   $father and $mother have ${children.length == 1 ? '1 child' : '${children.length} children'}');
      for (var child in children) {
        print('      - $child');
      }
    }
  }
}

Stream<String> catalog() async* {
  // CsvLoader will unescape data between quotes
  yield 'Part code\tPart label\tDescription\r\nB1XX\tBolt\t"Your ';
  yield 'average bolt"\r\nS2XX\tScrew\t"Your average screw"\r';
  yield '\nN1XX\tNut\t"Nut; for bolts ""B1X';
  yield 'X"""\r\n9N\tNail\t"A 9"';
  yield '" nail"\r\n';
}

Future readCatalog() async {
  print('Reading catalog...');
  // use "tab" as separator
  final catalogCsv = CsvLoader.withHeaders(catalog(), separator: '\t');

  await for (var row in catalogCsv.rows) {
    final code = row['Part code'];
    final label = row['Part label'];
    final descr = row['Description'];
    print('   $label ($code): $descr');
  }
}
