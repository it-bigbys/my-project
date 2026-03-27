import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user.dart' as model;
import '../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService;

  model.User? _currentUser;
  List<model.User> _teamMembers = [];
  bool _isLoading = true;
  String? _error;

  model.User? get currentUser => _currentUser;
  List<model.User> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  bool get isSuperAdmin => _currentUser?.role == 'Super Admin';
  bool get isAdminRole => _currentUser?.role == 'Admin' || isSuperAdmin;
  
  bool get isGOM => _currentUser?.role == 'GOM';
  bool get isBranch => _currentUser?.role == 'Branch';
  bool get isIT => _currentUser?.role == 'IT';
  bool get isSecretary => _currentUser?.role == 'Secretary';

  bool get canAssign => isAdminRole || isIT;
  bool get canEditEverything => isAdminRole;

  bool get isAdmin => isAdminRole || isGOM || isBranch || isIT || isSecretary;

  AuthProvider({
    required LocalStorageService localStorageService,
  })  : _localStorageService = localStorageService {
    _init();
  }

  void _init() {
    if (Firebase.apps.isEmpty) {
      _currentUser = null;
      _teamMembers = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _auth.authStateChanges().listen((fb.User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        _teamMembers = [];
        _isLoading = false;
        notifyListeners();
      } else {
        await _fetchUserProfile(fbUser);
        _listenToTeamMembers();
      }
    });
  }

  Future<void> _fetchUserProfile(fb.User fbUser) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = model.User(
          id: fbUser.uid,
          name: data['name'] ?? fbUser.displayName ?? 'Unknown',
          email: fbUser.email ?? '',
          role: data['role'] ?? 'User',
          photoUrl: data['photoUrl'],
        );
      } else {
        _currentUser = model.User(
          id: fbUser.uid,
          name: fbUser.displayName ?? 'New User',
          email: fbUser.email ?? '',
          role: 'User',
        );
        await _db.collection('users').doc(fbUser.uid).set({
          'name': _currentUser!.name,
          'email': _currentUser!.email,
          'role': _currentUser!.role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _listenToTeamMembers() {
    _db.collection('users').snapshots().listen((snapshot) {
      _teamMembers = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return model.User(
              id: doc.id,
              name: data['name'] ?? 'Unknown',
              email: data['email'] ?? '',
              role: data['role'] ?? 'User',
              photoUrl: data['photoUrl'],
            );
          })
          .toList();
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String targetEmail = email;
      if (email == 'admin') targetEmail = 'admin@admin.com';
      await _auth.signInWithEmailAndPassword(email: targetEmail, password: password);
      return true;
    } catch (e) {
      _error = _getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> addUser({required String email, required String password, required String name, required String role}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TemporaryUserCreation_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      
      fb.FirebaseAuth tempAuth = fb.FirebaseAuth.instanceFor(app: tempApp);
      fb.UserCredential credential = await tempAuth.createUserWithEmailAndPassword(email: email, password: password);
      
      final String newUid = credential.user!.uid;
      
      await _db.collection('users').doc(newUid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      await tempApp.delete();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile(String name, String email, String role) async {
    if (_currentUser == null) return;

    try {
      await _db.collection('users').doc(_currentUser!.id).update({
        'name': name,
        'email': email,
        'role': role,
      });
      _currentUser = _currentUser!.copyWith(name: name, email: email, role: role);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: _currentUser!.email,
        password: currentPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
      await _auth.currentUser!.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _getReadableError(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(String userId, String name, String email, String role) async {
    try {
      await _db.collection('users').doc(userId).update({
        'name': name,
        'email': email,
        'role': role,
      });
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser!.copyWith(name: name, email: email, role: role);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).delete();
      if (_currentUser?.id == userId) {
        await _auth.signOut();
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfilePicture(Uint8List bytes, String filename) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await _localStorageService.saveFileLocally(File.fromRawPath(bytes), 'profile_pictures');
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      await _db.collection('users').doc(_currentUser!.id).update({
        'photoUrl': base64String,
      });
      _currentUser = _currentUser!.copyWith(photoUrl: base64String);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating profile picture: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _auth.signOut();
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  String _getReadableError(dynamic e) {
    if (e is fb.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'No user found with this email.';
        case 'wrong-password': return 'Wrong password provided.';
        case 'email-already-in-use': return 'An account already exists for this email.';
        case 'invalid-email': return 'The email address is not valid.';
        default: return e.message ?? 'An unknown error occurred.';
      }
    }
    return e.toString();
  }
}
