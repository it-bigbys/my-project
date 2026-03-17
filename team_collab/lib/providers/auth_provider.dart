import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as model;

class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  model.User? _currentUser;
  bool _isLoading = true;
  String? _error;

  model.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((fb.User? fbUser) async {
      if (fbUser == null) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      } else {
        await _fetchUserProfile(fbUser);
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
          role: data['role'] ?? 'Team Member',
        );
      } else {
        // Create profile if it doesn't exist
        _currentUser = model.User(
          id: fbUser.uid,
          name: fbUser.displayName ?? 'New User',
          email: fbUser.email ?? '',
          role: 'Team Member',
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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      _error = _getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final fbUser = credential.user!;
      
      _currentUser = model.User(
        id: fbUser.uid,
        name: name,
        email: email,
        role: 'Team Member',
      );

      await _db.collection('users').doc(fbUser.uid).set({
        'name': name,
        'email': email,
        'role': 'Team Member',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getReadableError(e);
      _isLoading = false;
      notifyListeners();
      return false;
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

  Future<void> logout() async {
    await _auth.signOut();
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

  // To maintain compatibility with existing team members UI (simulated for now)
  List<model.User> get teamMembers => [
    model.User(id: '1', name: 'Alice Johnson', email: 'alice@team.com', role: 'Project Manager'),
    model.User(id: '2', name: 'Bob Smith', email: 'bob@team.com', role: 'Developer'),
  ];
}
