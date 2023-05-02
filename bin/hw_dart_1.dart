import 'dart:convert' as convert;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

void main(List<String> arguments) async {
  final db = sqlite3.open('Names.db');

  final checkTable = db.select(
      'SELECT name FROM sqlite_master WHERE type="table" AND name="Names";');
  if (checkTable.isEmpty) {
    db.execute('''
    CREATE TABLE Names (
      count INTEGER NOT NULL,
      gender TEXT NOT NULL,
      name TEXT NOT NULL PRIMARY KEY UNIQUE,
      probability REAL
    );
  ''');
  }

  final name = 'lena';
  final url = Uri.https('api.genderize.io', '', {'name': name});
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final jsonResponse = convert.jsonDecode(response.body);
    final count = jsonResponse['count'];
    final gender = jsonResponse['gender'];
    final probability = jsonResponse['probability']?.toDouble();
    final stmt = db.prepare(
        'INSERT OR REPLACE INTO Names (count, gender, name, probability) VALUES (?, ?, ?, ?)');
    stmt.execute([count, gender, name, probability]);
    stmt.dispose();
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }

  final resultSet = db.select('SELECT * FROM Names');
  for (final row in resultSet) {
    print(
        'count: ${row['count']}, gender: ${row['gender']}, name: ${row['name']}, probability: ${row['probability']}');
  }
  print('-------------------------------------------------------------');

  final file = File('Names.txt');
  final output = file.openWrite();
  for (final row in resultSet) {
    final line =
        '${row['count']}\t${row['gender']}\t${row['name']}\t${row['probability']}';
    output.write('$line\r\n');
  }

  final ResultSet resultSelect =
      //db.select("SELECT * FROM Names WHERE gender = 'male'");
      db.select('SELECT * FROM Names WHERE probability < 0.99');
  //db.select('SELECT * FROM Names');
  print('SELECT * FROM Names WHERE probability < 0.99');

  for (final Row row in resultSelect) {
    print(
        'count: ${row['count']}, gender: ${row['gender']}, name: ${row['name']}, probability: ${row['probability']}');
  }

  await output.close();

  db.dispose();
}
