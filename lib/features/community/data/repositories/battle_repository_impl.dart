import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/battle_remote_data_source.dart';
import '../../domain/entities/battle.dart';

class BattleRepository {
  final BattleRemoteDataSource _remote;
  const BattleRepository(this._remote);

  Future<List<Battle>> getUserBattles(String userId) => _remote.getUserBattles(userId);
}

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return BattleRepository(ref.watch(battleRemoteDataSourceProvider));
});