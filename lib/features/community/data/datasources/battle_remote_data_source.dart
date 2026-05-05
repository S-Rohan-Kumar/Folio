import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/providers/supabase_provider.dart';
import '../models/battle_model.dart';
import '../../domain/entities/battle.dart';

abstract class BattleRemoteDataSource {
  Future<List<Battle>> getUserBattles(String userId);
}

class BattleRemoteDataSourceImpl implements BattleRemoteDataSource {
  final SupabaseClient _client;
  const BattleRemoteDataSourceImpl(this._client);

  @override
  Future<List<Battle>> getUserBattles(String userId) async {
    final data = await _client
        .from('battles')
        .select()
        .or('challenger_id.eq.$userId,rival_id.eq.$userId')
        .order('created_at', ascending: false);
    return (data as List).map((e) => BattleModel.fromJson(e)).toList();
  }
}

final battleRemoteDataSourceProvider = Provider<BattleRemoteDataSource>((ref) {
  return BattleRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});