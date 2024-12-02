import 'package:odometer_app/content/speed_entry.dart';

import 'content/vehicle.dart';
import 'content/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
  
class APIDatabaseHelper
{
  static Future<Database> database() async {
    return openDatabase(
      join(await getDatabasesPath(), 'smart_car_database1.db'),
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE user(id VARCHAR NOT NULL)');
        await db.execute('CREATE TABLE vehicle(userID VARCHAR NOT NULL, id VARCHAR NOT NULL, make VARCHAR, model VARCHAR, year YEAR, FOREIGN KEY(userID) REFERENCES user(id), PRIMARY KEY(userID, id))');
        await db.execute('CREATE TABLE speedEntry(vehicleID VARCHAR NOT NULL, dateTime VARCHAR NOT NULL, speed DOUBLE NOT NULL, FOREIGN KEY(vehicleID) REFERENCES vehicle(id), PRIMARY KEY(vehicleID, dateTime))');
      },
      version: 1,
    );
  }
  
  static Future<void> insertUser(User user) async {
    final db = await database();
    await db.insert('user', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  static Future<List<User>> getUsers() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query('user');
    return List.generate(maps.length, (i) {
      return User(id: maps[i]['id']);
    });
  }

  static Future<void> updateUser(User user) async {
    final db = await database();
    await db.update('user', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  static Future<void> deleteUser(String id) async {
    final db = await database(); 
    await db.delete('user', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await database();
    await db.insert('vehicle', vehicle.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Vehicle>> getVehicles() async {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query('vehicle');
    return List.generate(maps.length, (i) {
      return Vehicle(userID: maps[i]['userID'], id: maps[i]['id'], make: maps[i]['make'], model: maps[i]['model'], year: maps[i]['year']);
    });
  }

  static Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database();
    await db.update('vehicle', vehicle.toMap(), where: 'id = ?', whereArgs: [vehicle.id]);
  }

  static Future<void> deleteVehicle(String id) async {
    final db = await database(); 
    await db.delete('vehicle', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<SpeedEntry>> getSpeedEntries() async
  {
    final db = await database();
    final List<Map<String, dynamic>> maps = await db.query('speedEntry');
    return List.generate(maps.length, (i) {
      return SpeedEntry(vehicleID: maps[i]['vehicleID'], dateTime: DateTime.parse(maps[i]['dateTime']), speed: maps[i]['speed']);
    });
  }

  static Future<void> insertSpeedEntry(SpeedEntry entry) async {
    final db = await database();
    await db.insert('speedEntry', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}