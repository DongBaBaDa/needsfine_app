
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final _supabase = Supabase.instance.client;

  // Fetch Store Metrics (Aggregated by store_name)
  static Future<List<Map<String, dynamic>>> getStoreMetrics() async {
    try {
      final response = await _supabase.rpc('get_store_metrics');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch store metrics: $e');
    }
  }

  // Fetch Daily Growth Stats
  static Future<List<Map<String, dynamic>>> getDailyGrowthStats() async {
    try {
      final response = await _supabase.rpc('get_daily_growth_stats');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch daily growth stats: $e');
    }
  }
}
