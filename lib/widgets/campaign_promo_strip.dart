import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Horizontal promo strip below search — auto-advancing cards with video or image (Zomato-style).
class CampaignPromoStrip extends StatefulWidget {
  final List<Map<String, dynamic>> campaigns;
  final List<String> bannerUrls;
  final VoidCallback onTap;
  static const Duration rotation = Duration(seconds: 8);

  const CampaignPromoStrip({
    super.key,
    required this.campaigns,
    required this.bannerUrls,
    required this.onTap,
  });

  @override
  State<CampaignPromoStrip> createState() => _CampaignPromoStripState();
}

class _PromoSlide {
  final String? videoUrl;
  final String? imageUrl;
  final Color colorA;
  final Color colorB;
  final String title;
  final String tagline;
  final bool isActive;

  const _PromoSlide({
    this.videoUrl,
    this.imageUrl,
    required this.colorA,
    required this.colorB,
    required this.title,
    required this.tagline,
    required this.isActive,
  });
}

class _CampaignPromoStripState extends State<CampaignPromoStrip> {
  late final PageController _pageController;
  Timer? _autoTimer;
  int _pageIndex = 0;
  VideoPlayerController? _video;
  bool _videoReady = false;
  late List<_PromoSlide> _slides;

  static const _palettes = <List<Color>>[
    [Color(0xFFC62828), Color(0xFF8E0000)],
    [Color(0xFFE65100), Color(0xFFFF7A2E)],
    [Color(0xFF1565C0), Color(0xFF0D47A1)],
    [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  ];

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
    _pageController = PageController(viewportFraction: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mountVideoForPage(_pageIndex);
      _startAutoAdvance();
    });
  }

  @override
  void didUpdateWidget(covariant CampaignPromoStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaigns != widget.campaigns ||
        oldWidget.bannerUrls != widget.bannerUrls) {
      _disposeVideo();
      _autoTimer?.cancel();
      _slides = _buildSlides();
      _pageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
      _mountVideoForPage(0);
      _startAutoAdvance();
      setState(() {});
    }
  }

  void _startAutoAdvance() {
    _autoTimer?.cancel();
    if (_slides.length <= 1) return;
    _autoTimer = Timer.periodic(CampaignPromoStrip.rotation, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_pageIndex + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  String? _firstVideoFromMedia(dynamic media) {
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

  List<_PromoSlide> _buildSlides() {
    final out = <_PromoSlide>[];
    var pi = 0;
    for (final c in widget.campaigns) {
      final pal = _palettes[pi % _palettes.length];
      final vid = _firstVideoFromMedia(c['media']);
      final img = c['image']?.toString().trim() ?? '';
      final title = c['title']?.toString().trim().isNotEmpty == true
          ? c['title'].toString().trim()
          : 'Reward campaign';
      final tag = c['description']?.toString().trim() ?? 'Shop. Dream. Win.';
      final active = c['is_active'] == true;
      if (vid != null && vid.isNotEmpty) {
        out.add(_PromoSlide(
          videoUrl: vid,
          imageUrl: img.isNotEmpty ? img : null,
          colorA: pal[0],
          colorB: pal[1],
          title: title,
          tagline: tag,
          isActive: active,
        ));
        pi++;
      } else if (img.isNotEmpty) {
        out.add(_PromoSlide(
          imageUrl: img,
          colorA: pal[0],
          colorB: pal[1],
          title: title,
          tagline: tag,
          isActive: active,
        ));
        pi++;
      }
    }
    if (out.isEmpty) {
      for (final u in widget.bannerUrls) {
        final s = u.trim();
        if (s.isEmpty) continue;
        final pal = _palettes[pi % _palettes.length];
        out.add(_PromoSlide(
          imageUrl: s,
          colorA: pal[0],
          colorB: pal[1],
          title: 'Kutoot rewards',
          tagline: 'Tap to explore live campaigns',
          isActive: true,
        ));
        break;
      }
    }
    if (out.isEmpty) {
      out.add(const _PromoSlide(
        colorA: AppTheme.primary,
        colorB: AppTheme.primaryDark,
        title: 'Reward campaigns',
        tagline: 'Join live campaigns & earn stamps',
        isActive: true,
      ));
    }
    return out;
  }

  Future<void> _mountVideoForPage(int page) async {
    _disposeVideo();
    if (!mounted || page < 0 || page >= _slides.length) return;
    final slide = _slides[page];
    final url = slide.videoUrl;
    if (url == null || url.isEmpty) {
      setState(() => _videoReady = false);
      return;
    }
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      setState(() {
        _video = c;
        _videoReady = true;
      });
    } catch (_) {
      if (mounted) setState(() => _videoReady = false);
    }
  }

  void _disposeVideo() {
    _video?.dispose();
    _video = null;
    _videoReady = false;
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _disposeVideo();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _pageIndex = i);
    _mountVideoForPage(i);
  }

  @override
  Widget build(BuildContext context) {
    const h = 198.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: h,
          width: double.infinity,
          child: _slides.length == 1
              ? _PromoCard(
                  slide: _slides[0],
                  showVideo: _videoReady && _video != null,
                  video: _video,
                  onTap: widget.onTap,
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: _onPageChanged,
                  padEnds: false,
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    final useVideo = i == _pageIndex &&
                        _videoReady &&
                        _video != null &&
                        _video!.value.isInitialized;
                    return _PromoCard(
                      slide: s,
                      showVideo: useVideo,
                      video: useVideo ? _video : null,
                      onTap: widget.onTap,
                    );
                  },
                ),
        ),
        if (_slides.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final on = i == _pageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: on ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: on
                      ? AppTheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final _PromoSlide slide;
  final bool showVideo;
  final VideoPlayerController? video;
  final VoidCallback onTap;

  const _PromoCard({
    required this.slide,
    required this.showVideo,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (showVideo && video != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: video!.value.size.width,
                    height: video!.value.size.height,
                    child: VideoPlayer(video!),
                  ),
                )
              else if (slide.imageUrl != null && slide.imageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: slide.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [slide.colorA, slide.colorB],
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [slide.colorA, slide.colorB],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [slide.colorA, slide.colorB],
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.35, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: slide.isActive
                        ? const Color(0xFF43A047)
                        : const Color(0xFF757575),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    slide.isActive ? 'LIVE' : 'SOON',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slide.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
