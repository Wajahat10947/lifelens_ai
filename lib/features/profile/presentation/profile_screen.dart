import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/data/firestore_service.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final bool isOnboarding;
  final VoidCallback? onProfileCompleted;

  const ProfileScreen({
    super.key,
    required this.uid,
    this.isOnboarding = false,
    this.onProfileCompleted,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = FirestoreService();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _profileImage;

  String _email = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;

  double get profileProgress {
    double progress = 0.0;

    final name = _nameController.text.trim();

    if (name.length >= 2 && name.length <= 40) {
      progress += 0.5;
    }

    if (_profileImage != null && _profileImage!.isNotEmpty) {
      progress += 0.5;
    }

    return progress;
  }

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Widget buildProfileProgress() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Your Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            '${(profileProgress * 100).toInt()}% completed',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: profileProgress,
            minHeight: 7,
            color: AppColors.purple,
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(height: 10),

          const Text('Add your name and profile picture.'),
        ],
      ),
    );
  }

  // READ DATA
  Future<void> loadProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await _service.getUserProfile(widget.uid);

      if (!mounted) return;

      if (data == null) {
        throw StateError('Profile not found');
      }

      setState(() {
        _nameController.text = data['name'] ?? '';
        _email = data['email'] ?? '';

        final photo = data['photo'];

        if (photo is Blob) {
          _profileImage = photo.bytes;
        } else {
          _profileImage = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // UPDATE DATA
  Future<void> saveProfile() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.isOnboarding && profileProgress < 1.0) {
      showMessage('Please complete your profile');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.updateUserProfile(
        widget.uid,
        _nameController.text.trim(),
        photo: _profileImage,
      );

      if (!mounted) return;

      showMessage('Profile updated successfully');
      widget.onProfileCompleted?.call();
    } catch (_) {
      if (mounted) {
        showMessage('Could not update profile');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      if (bytes.length > 200 * 1024) {
        showMessage('Please select a smaller image');
        return;
      }

      setState(() {
        _profileImage = bytes;
      });
    } catch (_) {
      if (mounted) {
        showMessage('Could not select image');
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,

      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: colors.surface,
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              )
            : _hasError
            ? Center(
                child: ElevatedButton(
                  onPressed: loadProfile,
                  child: const Text('Profile unavailable. Retry'),
                ),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: buildProfileForm(),
                  ),
                ),
              ),
      ),
    );
  }

  Widget buildProfileForm() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),

      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress bar - Stack se bahar
            if (widget.isOnboarding) ...[
              buildProfileProgress(),
              const SizedBox(height: 25),
            ],

            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.purple,

                    foregroundImage: _profileImage != null
                        ? MemoryImage(_profileImage!)
                        : null,

                    child: const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.white,
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton.filled(
                      onPressed: _isSaving ? null : pickProfileImage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Personal Information',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            TextFormField(
              onChanged: (value) {
                setState(() {});
              },
              controller: _nameController,
              enabled: !_isSaving,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';

                if (name.length < 2) {
                  return 'Enter at least 2 characters';
                }

                if (name.length > 40) {
                  return 'Maximum 40 characters';
                }

                return null;
              },
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.cyan),
              title: const Text('Email'),
              subtitle: Text(_email),
              trailing: const Icon(Icons.lock_outline),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isOnboarding
                            ? 'Complete Profile'
                            : 'Save Changes',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
