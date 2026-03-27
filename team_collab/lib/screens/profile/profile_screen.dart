import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _roleController = TextEditingController(text: user?.role ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    
    if (pickedFile != null && mounted) {
      final bytes = await pickedFile.readAsBytes();
      try {
        await context.read<AuthProvider>().updateProfilePicture(bytes, pickedFile.name);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: $e')),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF800000)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthProvider>().updateProfile(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _roleController.text.trim(),
      );
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Color(0xFF800000)),
      );
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    final ImageProvider<Object>? profileImage;
    final String? profilePhotoUrl = user?.photoUrl;
    if (user?.photoLocalPath != null && !kIsWeb && File(user!.photoLocalPath!).existsSync()) {
      profileImage = FileImage(File(user.photoLocalPath!));
    } else if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      profileImage = NetworkImage(profilePhotoUrl);
    } else {
      profileImage = null;
    }

    return ResponsiveScaffold(
      title: 'User Profile',
      currentRoute: '/profile',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceOptions,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).primaryColor,
                          backgroundImage: profileImage,
                          child: (user?.photoLocalPath == null && user?.photoUrl == null)
                              ? Text(
                                  user?.avatarInitials ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      if (auth.isLoading)
                        const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Colors.white))),
                      InkWell(
                        onTap: _showImageSourceOptions,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.role ?? 'Role',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileField('Name', _nameController, Icons.person_outline, _isEditing),
                  const SizedBox(height: 16),
                  _buildProfileField('Email', _emailController, Icons.email_outlined, _isEditing),
                  const SizedBox(height: 16),
                  _buildProfileField('Role', _roleController, Icons.work_outline, false), // Role shouldn't be editable by user
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: const Icon(Icons.lock_outline, size: 18),
                      label: const Text('Change Password'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isEditing)
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        )
                      else ...[
                        TextButton(
                          onPressed: () => setState(() => _isEditing = false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _saveProfile,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller, IconData icon, bool enabled) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: enabled ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) => value == null || value.isEmpty ? 'This field cannot be empty' : null,
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enter your current password and choose a new one.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 24),
                  _buildPasswordField('Current Password', _currentPasswordController, _obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
                  const SizedBox(height: 16),
                  _buildPasswordField('New Password', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
                  const SizedBox(height: 16),
                  _buildPasswordField('Confirm New Password', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Change Password'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback toggleVisibility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF64748B)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: const Color(0xFF64748B)),
              onPressed: toggleVisibility,
            ),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Theme.of(context).primaryColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'This field cannot be empty';
            if (label.contains('New Password') && value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ],
    );
  }
}
