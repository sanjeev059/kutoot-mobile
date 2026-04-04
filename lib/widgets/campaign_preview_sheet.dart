import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../api/kutoot_api.dart';
import '../theme/app_theme.dart';
import '../utils/image_utils.dart';
import '../screens/campaigns/campaign_detail_screen.dart';
import 'premium_widgets.dart';

Future<void> showCampaignPreview(
  BuildContext context,
  Map<String, dynamic> campaign,
) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => _CampaignPreviewSheet(campaign: campaign),
  );
}

class _CampaignPreviewSheet extends StatefulWidget {
  final Map<String, dynamic> campaign;
  const _CampaignPreviewSheet({required this.campaign});

  @override
  State<_CampaignPreviewSheet> createState() => _CampaignPreviewSheetState();
}

class _CampaignPreviewSheetState extends State<_CampaignPreviewSheet>
    with SingleTickerProviderStateMixin {
  final _api = KutootApi();
  Map<String, dynamic>? _detail;
  bool _loading = true;
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoError = false;
  bool _muted = false;
  String? _activeVideoUrl;
  late final AnimationController _sheetAnim;

  int get _campaignId =>
      widget.campaign['id'] is int
          ? widget.campaign['id'] as int
          : int.tryParse(widget.campaign['id']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tryStartVideoFromMap(widget.campaign);
    });
    _loadDetail();
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _sheetAnim.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    if (_campaignId == 0) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await _api.getCampaign(_campaignId);
      final data = KutootApi.unwrapSuccessData(res.data);
      if (mounted) {
        setState(() {
          _detail = data;
          _loading = false;
        });
        if (data != null) _tryStartVideoFromMap(data);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _firstVideoUrlFromMedia(dynamic media) {
    if (media is! List) return null;
    for (final m in media) {
      if (m is Map) {
        final mime = m['mime_type']?.toString() ?? '';
        if (mime.startsWith('video/')) {
          final u = m['url']?.toString();
          if (u != null && u.isNotEmpty) return u;
        }
      }
    }
    return null;
  }

  void _tryStartVideoFromMap(Map<String, dynamic> map) {
    final url = _firstVideoUrlFromMedia(map['media']);
    if (url == null || url.isEmpty) return;
    if (_activeVideoUrl == url && _videoReady) return;
    _activeVideoUrl = url;
    _videoCtrl?.dispose();
    _videoCtrl = null;
    _videoReady = false;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoCtrl = ctrl;
    ctrl.initialize().then((_) {
      if (!mounted) return;
      ctrl.setLooping(true);
      // Opening the sheet is a user gesture — autoplay with sound (matches web / Netflix-style preview).
      ctrl.setVolume(_muted ? 0 : 1);
      setState(() => _videoReady = true);
      ctrl.play();
    }).catchError((_) {
      if (mounted) setState(() => _videoError = true);
    });
  }

  void _toggleMute() {
    if (_videoCtrl == null) return;
    setState(() => _muted = !_muted);
    _videoCtrl!.setVolume(_muted ? 0 : 1);
    HapticFeedback.lightImpact();
  }

  void _openFullDetail() {
    Navigator.pop(context);
    if (_campaignId > 0) {
      Navigator.push(
        context,
        premiumRoute(CampaignDetailScreen(campaignId: _campaignId)),
      );
    }
  }

  String? get _imageUrl {
    if (_detail != null) {
      final media = _detail!['media'];
      if (media is List && media.isNotEmpty) {
        for (final m in media) {
          if (m is Map) {
            final mime = m['mime_type']?.toString() ?? '';
            if (mime.startsWith('image/')) {
              return m['url']?.toString();
            }
          }
        }
        return media[0]['preview']?.toString() ??
            media[0]['thumb']?.toString();
      }
      return ImageUtils.fromMap(_detail!);
    }
    final img = widget.campaign['image']?.toString() ?? '';
    return img.isNotEmpty ? img : null;
  }

  String get _title =>
      _detail?['reward_name']?.toString() ??
      _detail?['name']?.toString() ??
      widget.campaign['title']?.toString() ??
      'Campaign';

  String get _description =>
      _detail?['description']?.toString() ??
      widget.campaign['description']?.toString() ??
      '';

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF121212) : Colors.white;

    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (context, child) {
        final curve = Curves.easeOutCubic.transform(_sheetAnim.value);
        return Transform.translate(
          offset: Offset(0, (1 - curve) * 200),
          child: Opacity(opacity: curve, child: child),
        );
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: sheetColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMediaSection(screenH),
                    _buildContent(isDark),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaSection(double screenH) {
    final mediaHeight = screenH * 0.32;

    return SizedBox(
      height: mediaHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_videoReady && _videoCtrl != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _videoCtrl!.value.size.width,
                height: _videoCtrl!.value.size.height,
                child: VideoPlayer(_videoCtrl!),
              ),
            )
          else if (_videoCtrl != null && !_videoReady)
            Stack(
              fit: StackFit.expand,
              children: [
                if (_imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: _imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _gradientFallback(),
                  )
                else
                  _gradientFallback(),
                const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ],
            )
          else if (_imageUrl != null)
            CachedNetworkImage(
              imageUrl: _imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.primary.withValues(alpha: 0.15),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => _gradientFallback(),
            )
          else
            _gradientFallback(),

          // Bottom gradient
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 12,
            right: 12,
            child: _circleButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // Mute/unmute for video
          if (_videoReady)
            Positioned(
              bottom: 12,
              right: 12,
              child: _circleButton(
                icon: _muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: _toggleMute,
              ),
            ),

          // Title overlay at bottom
          Positioned(
            left: 16,
            right: 60,
            bottom: 14,
            child: Text(
              _title.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8),
                ],
              ),
            ),
          ),

          // Loading indicator
          if (_loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final textColor = isDark ? Colors.white : AppTheme.textPrimary;
    final subtextColor = isDark ? Colors.white60 : AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status tags
          Wrap(
            spacing: 8,
            children: [
              if (widget.campaign['is_active'] == true ||
                  _detail?['is_active'] == true)
                _tag('LIVE NOW', const Color(0xFF43A047)),
              if (_detail?['is_premium'] == true)
                _tag('PREMIUM', const Color(0xFFFF6D00)),
              _tag('CAMPAIGN', AppTheme.primary),
            ],
          ),
          const SizedBox(height: 16),

          if (_description.isNotEmpty) ...[
            Text(
              _description,
              style: TextStyle(
                fontSize: 14,
                color: subtextColor,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Stats row
          if (_detail != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF8F4F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _stat(
                    Icons.stars_rounded,
                    '${_detail!['stamp_target'] ?? '-'}',
                    'Stamps',
                    textColor,
                  ),
                  _divider(),
                  _stat(
                    Icons.people_rounded,
                    '${_detail!['subscribers_count'] ?? '-'}',
                    'Joined',
                    textColor,
                  ),
                  _divider(),
                  _stat(
                    Icons.emoji_events_rounded,
                    '₹${_formatCost(_detail!['reward_cost_target'])}',
                    'Prize',
                    textColor,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Key facts
          if (_detail?['key_facts'] != null &&
              _detail!['key_facts'].toString().isNotEmpty) ...[
            Text(
              'Key Facts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _detail!['key_facts'].toString(),
              style: TextStyle(
                fontSize: 13,
                color: subtextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: BounceTap(
                  onTap: _openFullDetail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Full details & join',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              BounceTap(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to watchlist'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : const Color(0xFFF0EBE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.bookmark_add_rounded,
                      color: isDark ? Colors.white70 : AppTheme.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradientFallback() {
    final colors = widget.campaign['gradient'] is List
        ? (widget.campaign['gradient'] as List).cast<Color>()
        : [AppTheme.primary, AppTheme.primaryDark];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Image.asset(
          AppTheme.logoAsset,
          height: 60,
          fit: BoxFit.contain,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.outlineVariant.withValues(alpha: 0.3),
    );
  }

  String _formatCost(dynamic cost) {
    if (cost == null) return '-';
    final n = cost is num ? cost : num.tryParse(cost.toString());
    if (n == null) return '-';
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}
