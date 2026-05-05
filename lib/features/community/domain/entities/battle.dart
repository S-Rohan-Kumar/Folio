enum BattleStatus { pending, active, completed, cancelled }

class Battle {
  final String id;
  final String challengerId;
  final String rivalId;
  final String bookId;
  final BattleStatus status;
  final int challengerPage;
  final int rivalPage;
  final String? winnerId;
  final DateTime createdAt;

  const Battle({
    required this.id,
    required this.challengerId,
    required this.rivalId,
    required this.bookId,
    required this.status,
    this.challengerPage = 0,
    this.rivalPage = 0,
    this.winnerId,
    required this.createdAt,
  });
}