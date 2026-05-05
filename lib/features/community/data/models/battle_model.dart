import '../../domain/entities/battle.dart';

class BattleModel {
  static Battle fromJson(Map<String, dynamic> json) => Battle(
    id: json['id'] as String,
    challengerId: json['challenger_id'] as String,
    rivalId: json['rival_id'] as String,
    bookId: json['book_id'] as String,
    status: _parseStatus(json['status'] as String),
    challengerPage: json['challenger_page'] as int? ?? 0,
    rivalPage: json['rival_page'] as int? ?? 0,
    winnerId: json['winner_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static BattleStatus _parseStatus(String s) {
    switch (s) {
      case 'active': return BattleStatus.active;
      case 'completed': return BattleStatus.completed;
      case 'cancelled': return BattleStatus.cancelled;
      default: return BattleStatus.pending;
    }
  }
}