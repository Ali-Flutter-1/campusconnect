// Supabase exports its own `AuthException`; hide it so our domain exception
// (core/error/exceptions.dart) is the one in scope. `AuthApiException` (the
// concrete error Supabase throws) is unaffected by the hide.
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/entities/user_role.dart';
import '../models/app_user_model.dart';

/// Talks to Supabase Auth + the `profiles` table. Throws [ServerException] /
/// [AuthException] on failure; the repository converts these into `Failure`s.
abstract interface class AuthRemoteDataSource {
  Stream<AppUserModel?> authStateChanges();
  Future<AppUserModel?> getCurrentUser();
  Future<AppUserModel> signIn({required String email, required String password});
  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? adminCode,
  });
  Future<void> signOut();
  Future<AppUserModel> updateProfile({
    String? fullName,
    String? course,
    String? department,
    String? year,
    Uint8List? avatarBytes,
    String? avatarExt,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client, this._storage);

  final SupabaseClient _client;
  final StorageService _storage;

  @override
  Stream<AppUserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final user = event.session?.user;
      if (user == null) return null;
      return _loadProfile(user.id, user.email);
    });
  }

  @override
  Future<AppUserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _loadProfile(user.id, user.email);
  }

  @override
  Future<AppUserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth
          .signInWithPassword(email: email, password: password);
      final user = res.user;
      if (user == null) throw const AuthException('Invalid credentials.');
      return _loadProfile(user.id, user.email);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<AppUserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    String? adminCode,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Sign up failed. Please try again.');
      }

      // Ensure a profile row exists (fallback if the DB trigger is absent).
      await _client.from('profiles').upsert(
            AppUserModel(
              id: user.id,
              email: email,
              role: UserRole.student,
              fullName: fullName,
            ).toInsert(),
            ignoreDuplicates: true,
          );

      // If an admin code was supplied, ask the server to promote the user. The
      // RPC validates the secret; a wrong code simply leaves them a student.
      final code = adminCode?.trim();
      if (code != null && code.isNotEmpty) {
        await _client.rpc('redeem_admin_code', params: {'code': code});
      }

      // Reload so the returned user reflects the role the server actually set.
      return _loadProfile(user.id, user.email);
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (_) {
      throw const ServerException();
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<AppUserModel> updateProfile({
    String? fullName,
    String? course,
    String? department,
    String? year,
    Uint8List? avatarBytes,
    String? avatarExt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException();
    try {
      String? avatarUrl;
      if (avatarBytes != null) {
        avatarUrl = await _storage.uploadAvatar(
          userId: user.id,
          bytes: avatarBytes,
          ext: avatarExt ?? 'jpg',
        );
      }
      final updates = <String, dynamic>{
        'full_name': ?fullName,
        'course': ?course,
        'department': ?department,
        'year': ?year,
        'avatar_url': ?avatarUrl,
      };
      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', user.id);
      }
      return _loadProfile(user.id, user.email);
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }

  /// Loads the `profiles` row for [userId], creating a default student profile
  /// if one does not yet exist.
  Future<AppUserModel> _loadProfile(String userId, String? authEmail) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        final model = AppUserModel(
          id: userId,
          email: authEmail ?? '',
          role: UserRole.student,
        );
        await _client.from('profiles').upsert(model.toInsert());
        return model;
      }
      return AppUserModel.fromProfile(row, authEmail: authEmail);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const ServerException();
    }
  }
}
