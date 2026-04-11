import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/kutoot_api.dart';
import '../../providers/auth_provider.dart';
import '../../utils/image_utils.dart';

/// Edit / create profile — layout and palette aligned with Figma `Edit-profile/code.html` (light).
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const Color _pageBg = Color(0xFFFFF8F5);
  static const Color _headerTint = Color(0xFFF7F2F9);
  static const Color _onSurface = Color(0xFF221A14);
  static const Color _onSurfaceVariant = Color(0xFF594042);
  static const Color _inputFill = Color(0xFFF5E5DB);
  static const Color _primaryMaroon = Color(0xFF8A002B);
  static const Color _primaryGradientEnd = Color(0xFFAE1E3F);
  static const Color _cameraOrange = Color(0xFFFF7A2E);

  final _api = KutootApi();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameFocus = FocusNode();
  bool _saving = false;
  bool _uploadingAvatar = false;
  final _picker = ImagePicker();

  TextStyle get _labelStyle => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: _onSurfaceVariant,
      );

  InputDecoration _pillDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: _onSurfaceVariant.withValues(alpha: 0.45),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(
          color: _primaryMaroon.withValues(alpha: 0.22),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _fetchRemote();
  }

  @override
  void dispose() {
    _nameFocus.dispose();
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
        final p = user['mobile']?.toString() ?? user['phone']?.toString() ?? '';
        var digits = p.replaceAll(RegExp(r'\D'), '');
        if (digits.startsWith('91') && digits.length >= 12) {
          digits = digits.substring(2);
        }
        if (digits.length > 10) {
          digits = digits.substring(digits.length - 10);
        }
        _phoneController.text = digits;
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
      _phoneController.text = savedPhone
          .replaceAll(RegExp(r'\D'), '')
          .replaceAll(RegExp(r'^91'), '');
    }
    if (mounted) setState(() {});
  }

  Future<void> _fetchRemote() async {
    try {
      final res = await _api.getProfile().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('timeout'),
          );
      final data = KutootApi.unwrapSuccessData(res.data);
      if (data != null && mounted) {
        setState(() {
          if ((data['name'] ?? '').toString().isNotEmpty) {
            _nameController.text = data['name'].toString();
          }
          if ((data['email'] ?? '').toString().isNotEmpty) {
            _emailController.text = data['email'].toString();
          }
          final mob = data['mobile'] ?? data['phone'];
          if ((mob ?? '').toString().isNotEmpty) {
            final d = mob.toString().replaceAll(RegExp(r'\D'), '');
            _phoneController.text =
                d.startsWith('91') && d.length == 12 ? d.substring(2) : d;
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

    // Mobile is verified at login — do not send updates (avoids 401/validation issues).
    final payload = <String, dynamic>{'name': name};
    if (email.isNotEmpty) payload['email'] = email;

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
      if (email.isNotEmpty) await prefs.setString('profile_email', email);

      final bodyUser = KutootApi.unwrapSuccessData(res.data);
      if (mounted && bodyUser != null) {
        final patch = bodyUser['user'] is Map
            ? Map<String, dynamic>.from(bodyUser['user'] as Map)
            : Map<String, dynamic>.from(bodyUser);
        context.read<AuthProvider>().mergeUserFields(patch);
      } else if (mounted) {
        context.read<AuthProvider>().mergeUserFields({
          'name': name,
          if (email.isNotEmpty) 'email': email,
        });
      }

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      var message = 'Could not update profile. Please try again.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          await context.read<AuthProvider>().logout();
          if (!mounted) return;
          message = 'Session expired. Please log in again.';
        } else {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            message = data['message'].toString();
          } else if (e.message != null && e.message!.isNotEmpty) {
            message = e.message!;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _uploadAvatarFile(String path) async {
    setState(() => _uploadingAvatar = true);
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(path, filename: 'avatar.jpg'),
      });
      final res = await _api.updateAvatar(formData);
      final data = KutootApi.unwrapSuccessData(res.data);
      if (mounted && data != null && data['profile_picture_url'] != null) {
        context.read<AuthProvider>().mergeUserFields({
          'profile_picture_url': data['profile_picture_url'],
        });
      } else if (mounted) {
        await context.read<AuthProvider>().checkAuth();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      var message = 'Could not upload photo.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (x == null || !mounted) return;
      await _uploadAvatarFile(x.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image')),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primaryMaroon),
              title: Text('Take Photo',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: _primaryMaroon),
              title: Text('Choose from Gallery',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = ImageUtils.resolve(user?['profile_picture_url']);
    final textTheme =
        GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: _onSurface, displayColor: _onSurface);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        scaffoldBackgroundColor: _pageBg,
      ),
      child: Scaffold(
        backgroundColor: _pageBg,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: _headerTint.withValues(alpha: 0.92),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _primaryMaroon),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Edit Profile',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: _primaryMaroon,
                ),
              ),
              centerTitle: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () =>
                                FocusScope.of(context).requestFocus(_nameFocus),
                            child: Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 132,
                                      height: 132,
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _primaryMaroon.withValues(
                                              alpha: 0.12),
                                          width: 4,
                                        ),
                                        color: Colors.white,
                                      ),
                                      child: ClipOval(
                                        child: avatarUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: avatarUrl,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) =>
                                                    _avatarPlaceholder(),
                                                errorWidget: (_, __, ___) =>
                                                    _avatarPlaceholder(),
                                              )
                                            : _avatarPlaceholder(),
                                      ),
                                    ),
                                    if (_uploadingAvatar)
                                      Positioned.fill(
                                        child: ClipOval(
                                          child: ColoredBox(
                                            color: Colors.black38,
                                            child: Center(
                                              child: SizedBox(
                                                width: 28,
                                                height: 28,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.95),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Material(
                                        color: _cameraOrange,
                                        shape: const CircleBorder(),
                                        elevation: 4,
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _showAvatarOptions,
                                          child: Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.photo_camera_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'UPDATE PHOTO',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    color: _primaryMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('FULL NAME', style: _labelStyle),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _onSurface,
                        ),
                        decoration: _pillDecoration(hint: 'Your name'),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('EMAIL ADDRESS', style: _labelStyle),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _onSurface,
                        ),
                        decoration: _pillDecoration(hint: 'you@example.com'),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          if (!s.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text('PHONE NUMBER', style: _labelStyle),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 56,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: _inputFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '+91',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              readOnly: true,
                              enableInteractiveSelection: true,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: _onSurface.withValues(alpha: 0.72),
                              ),
                              decoration:
                                  _pillDecoration(hint: '10-digit mobile')
                                      .copyWith(
                                suffixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  color: _onSurface.withValues(alpha: 0.35),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 6),
                        child: Text(
                          'Verified mobile cannot be changed.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _onSurfaceVariant.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_primaryMaroon, _primaryGradientEnd],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryMaroon.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: _saving ? null : _save,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: Center(
                                child: _saving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Save Changes',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return ColoredBox(
      color: _inputFill,
      child: Icon(
        Icons.person_rounded,
        size: 64,
        color: _primaryMaroon.withValues(alpha: 0.45),
      ),
    );
  }
}
