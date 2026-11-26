import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/firestore_service.dart';
import 'login_screen.dart';
import '../../home/presentation/home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../profile/presentation/profile_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Authentication error')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return ProfileGate(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class ProfileGate extends StatefulWidget {
  final User user;

  const ProfileGate({super.key, required this.user});

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<bool> _profileFuture;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;

  bool _completedNow = false;

  @override
  void initState() {
    super.initState();

    _profileFuture = checkProfile();

    _profileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
  }

  Future<bool> checkProfile() async {
    final service = FirestoreService();

    await service.ensureUserProfile(widget.user);

    final data = await service.getUserProfile(widget.user.uid);

    if (data == null) {
      throw StateError('Profile not found');
    }

    final name = data['name'];
    final photo = data['photo'];

    return name is String &&
        name.trim().length >= 2 &&
        photo is Blob &&
        photo.bytes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileFuture,

      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _profileFuture = checkProfile();
                  });
                },
                child: const Text('Retry'),
              ),
            ),
          );
        }

        final isComplete = snapshot.data == true;

        if (!isComplete && !_completedNow) {
          return ProfileScreen(
            uid: widget.user.uid,
            isOnboarding: true,

            onProfileCompleted: () {
              if (!mounted) return;

              setState(() {
                _completedNow = true;
              });
            },
          );
        }

        return buildLiveHome();
      },
    );
  }

  Widget buildLiveHome() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profileStream,

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Could not load profile')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();

        final name = data?['name'];
        final photo = data?['photo'];

        return HomeScreen(
          profileName: name is String && name.trim().isNotEmpty
              ? name.trim()
              : 'User',

          profilePhoto: photo is Blob ? photo.bytes : null,
        );
      },
    );
  }
}
