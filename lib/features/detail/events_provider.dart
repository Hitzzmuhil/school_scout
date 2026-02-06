import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/school_event.dart';
import '../../services/supabase_service.dart';
import '../search/search_provider.dart';

final eventsProvider = FutureProvider.autoDispose.family<List<SchoolEvent>, String>((ref, schoolId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getSchoolEvents(schoolId);
});
