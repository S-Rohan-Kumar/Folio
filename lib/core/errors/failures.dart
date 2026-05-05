sealed class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure extends Failure { const NetworkFailure() : super('No internet connection'); }
class ServerFailure extends Failure { const ServerFailure(String msg) : super(msg); }
class CacheFailure extends Failure { const CacheFailure() : super('Local data unavailable'); }
class BookNotFoundFailure extends Failure { const BookNotFoundFailure() : super('Book not found for this ISBN'); }
class GeminiFailure extends Failure { const GeminiFailure(String msg) : super(msg); }
class AuthFailure extends Failure { const AuthFailure(String msg) : super(msg); }