import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/profile_local_service.dart';

class ProfileService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // 🔁 Fetch profile from Supabase and cache locally
  Future<ProfileModel?> getProfile(String id) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .single();

      final profile = ProfileModel.fromMap(response);
      await ProfileLocalService().upsertProfile(profile); // Sync to local DB
      return profile;
    } catch (e) {
      print('Error fetching profile from Supabase: $e');

      // Try from local if Supabase fails
      return await ProfileLocalService().getProfileById(id);
    }
  }

  // ➕ Add new profile to Supabase and local DB
  Future<void> addProfile(ProfileModel profile) async {
    try {
      await _supabase.from('profiles').insert(profile.toMap());
      await ProfileLocalService().upsertProfile(profile);
    } catch (e) {
      print('Error adding profile: $e');
      rethrow;
    }
  }

  // 🔄 Update profile in Supabase and local DB
  Future<void> updateProfile(ProfileModel profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id);

      await ProfileLocalService().upsertProfile(profile);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // ❌ Delete profile from Supabase and local DB
  Future<void> deleteProfile(String id) async {
    try {
      await _supabase.from('profiles').delete().eq('id', id);
      await ProfileLocalService().deleteProfile(id);
    } catch (e) {
      print('Error deleting profile: $e');
      rethrow;
    }
  }

  // 🔁 Sync all profiles from Supabase to local (Admin/utility)
  Future<void> syncAllProfiles() async {
    try {
      final response = await _supabase.from('profiles').select();

      final profiles = (response as List)
          .map((e) => ProfileModel.fromMap(e))
          .toList();

      await ProfileLocalService().clearAllProfiles();

      for (final profile in profiles) {
        await ProfileLocalService().upsertProfile(profile);
      }
    } catch (e) {
      print('Error syncing all profiles: $e');
    }
  }
}
