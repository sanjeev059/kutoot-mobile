import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _api = KutootApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _fetchRemote();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadLocal() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        _nameController.text = user['name']?.toString() ?? '';
        _emailController.text = user['email']?.toString() ?? '';
        _phoneController.text = user['phone']?.toString() ?? '';
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('profile_name');
    final savedEmail = prefs.getString('profile_email');
    if (savedName != null && _nameController.text.isEmpty) {
      _nameController.text = savedName;
    }
    if (savedEmail != null && _emailController.text.isEmpty) {
      _emailController.text = savedEmail;
    }
    final savedPhone = prefs.getString('profile_phone');
    if (savedPhone != null && _phoneController.text.isEmpty) {
      _phoneController.text = savedPhone;
    }
  }

  Future<void> _fetchRemote() async {
    try {
      final res = await _api.getProfile().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('timeout'),
          );
      final raw = res.data;
      Map<String, dynamic>? data;
      if (raw is Map) {
        data = raw['data'] is Map
            ? Map<String, dynamic>.from(raw['data'] as Map)
            : Map<String, dynamic>.from(raw);
      }
      if (data != null && mounted) {
        setState(() {
          if ((data!['name'] ?? '').toString().isNotEmpty) {
            _nameController.text = data['name'].toString();
          }
          if ((data['email'] ?? '').toString().isNotEmpty) {
            _emailController.text = data['email'].toString();
          }
          if ((data['phone'] ?? '').toString().isNotEmpty) {
            _phoneController.text = data['phone'].toString();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final payload = <String, dynamic>{'name': name};
    if (email.isNotEmpty) payload['email'] = email;
    if (phone.isNotEmpty) payload['phone'] = phone;

    try {
      final res = await _api
          .updateProfile(payload)
          .timeout(const Duration(seconds: 15));
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          type: DioExceptionType.badResponse,
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_name', name);
      if (email.isNotEmpty) {
        await prefs.setString('profile_email', email);
      }
      if (phone.isNotEmpty) {
        await prefs.setString('profile_phone', phone);
      }

      if (mounted) {
        await context.read<AuthProvider>().checkAuth();
      }

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      var message = 'Could not update profile. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (e.message != null && e.message!.isNotEmpty) {
          message = e.message!;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      child: const Icon(Icons.person,
                          size: 48, color: AppTheme.primary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showAvatarOptions,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Full Name',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Email',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Phone Number',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 2,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
