abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<bool> signUpWithEmail(String email, String password, String displayName);
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Future<void> resetPassword(String email);
}