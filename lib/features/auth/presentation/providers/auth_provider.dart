import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';

class AuthNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
    });
  }

  /// Returns true if email verification is required, false if auto-logged in.
  Future<bool> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    bool needsVerification = false;
    state = await AsyncValue.guard(() async {
      needsVerification = await ref.read(authRepositoryProvider)
          .signUpWithEmail(email, password, name);
    });
    return needsVerification;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
    });
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).resetPassword(email);
    });
  }
}

final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, void>(() => AuthNotifier());