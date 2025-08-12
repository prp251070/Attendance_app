// supabase_services/division_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/division_model.dart';
import '../services/division_local_service.dart';

class DivisionService {
  final _supabase = Supabase.instance.client;

  // Fetch divisions from Supabase and update local DB
  Future<List<DivisionModel>> fetchAndSyncDivisions() async {
    final response = await _supabase
        .from('divisions')
        .select()
        .order('created_at');

    final divisions = (response as List)
        .map((e) => DivisionModel.fromMap(e))
        .toList();

    // Sync with local DB
    await DivisionLocalService().clearAllDivisions();
    await DivisionLocalService().insertAllDivisions(divisions);

    return divisions;
  }

  // Add division to Supabase and Local
  Future<void> addDivision(DivisionModel division) async {
    await _supabase.from('divisions').insert(division.toMap());

    // Save to local DB
    await DivisionLocalService().upsertDivision(division);
  }

  // Update division in Supabase and Local
  Future<void> updateDivision(DivisionModel division) async {
    await _supabase
        .from('divisions')
        .update({'name': division.name})
        .eq('id', division.id);

    // Update in local DB
    await DivisionLocalService().upsertDivision(division);
  }

  // Delete division from Supabase and Local
  Future<void> deleteDivision(String divisionId) async {
    await _supabase
        .from('divisions')
        .delete()
        .eq('id', divisionId);

    // Delete from local DB
    await DivisionLocalService().deleteDivision(divisionId);
  }

  // Sync divisions from Supabase manually (e.g., when app comes online)
  Future<void> manualSync() async {
    await fetchAndSyncDivisions();
  }
}
