import 'package:sqflite/sqflite.dart';
import 'local_db_helper.dart';
import '../models/profile_model.dart';

class ProfileLocalService {
  static final ProfileLocalService _instance = ProfileLocalService._internal();
  factory ProfileLocalService() => _instance;
  ProfileLocalService._internal();

  /// Save or update profile (principal or teacher)
  Future<void> upsertProfile(ProfileModel profile) async {
    final db = await LocalDBHelper().database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get profile by ID (user UUID)
  Future<ProfileModel?> getProfileById(String id) async {
    final db = await LocalDBHelper().database;
    final result = await db.query(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return ProfileModel.fromMap(result.first);
    }
    return null;
  }

  /// Get all profiles (usually only 1, for current session)
  Future<List<ProfileModel>> getAllProfiles() async {
    final db = await LocalDBHelper().database;
    final result = await db.query('profiles');
    return result.map((row) => ProfileModel.fromMap(row)).toList();
  }

  /// Delete a profile (logout user)
  Future<void> deleteProfile(String id) async {
    final db = await LocalDBHelper().database;
    await db.delete(
      'profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all cached profiles (debug/reset)
  Future<void> clearAllProfiles() async {
    final db = await LocalDBHelper().database;
    await db.delete('profiles');
  }
}
