import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';
import '../domain/user_model.dart';

/// Authentication status enum
enum AuthStatus { initial, loading, authenticated, unauthenticated }

/// Authentication state
class AuthState {
  final AuthStatus status;
  final LampUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    LampUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

/// Authentication notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _initAuth();
  }

  /// Initialize and check current auth state
  Future<void> _initAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      await _loadUserProfile(currentUser.id);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
    
    // Listen to auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadUserProfile(session.user.id);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  /// Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await SupabaseService.getUserProfile(userId);
      
      if (profile != null) {
        final user = LampUser.fromJson({
          ...profile,
          'id': userId,
          'email': SupabaseService.currentUser?.email,
        });
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        // Profile doesn't exist yet - create default
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: LampUser(
            id: userId,
            email: SupabaseService.currentUser?.email ?? '',
            role: 'protege',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to load profile: $e',
      );
    }
  }

  /// Sign in with email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    
    try {
      final response = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return true;
      }
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Login failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign up with email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    
    try {
      final response = await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user profile
        await SupabaseService.upsertUserProfile(
          userId: response.user!.id,
          data: {
            'Name': name,
            'email': email,
            'role': role,
          },
        );
        
        await _loadUserProfile(response.user!.id);
        return true;
      }
      
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Signup failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      await SupabaseService.signOut();
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (state.user == null) return false;
    
    try {
      await SupabaseService.upsertUserProfile(
        userId: state.user!.id,
        data: data,
      );
      await _loadUserProfile(state.user!.id);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Convenience provider for current user
final currentUserProvider = Provider<LampUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for auth status
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});
