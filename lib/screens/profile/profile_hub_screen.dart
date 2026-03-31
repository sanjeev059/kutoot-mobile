import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../services/campaign_entry_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import '../auth/delete_account_screen.dart';
import '../auth/logout_confirm_screen.dart';
import '../support/contact_support_screen.dart';
import '../profile/profile_edit_screen.dart';

class ProfileHubScreen extends StatefulWidget {
  final String cityName;
  final String planLabel;

  const ProfileHubScreen({
    super.key,
    required this.cityName,
    required this.planLabel,
  });

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _campaignEntries = [];

  @override
  void initState() {
    super.initState();
    _loadCampaignEntries();
  }

  Future<void> _loadCampaignEntries() async {
    List<Map<String, dynamic>> items = [];
    try {
      final response = await _api.getProfileCampaignEntries();
      final body = response.data;
      if (body is Map && body['data'] is List) {
        items = (body['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      items = await CampaignEntryService.getEntries();
    }

    if (items.isEmpty) {
      items = await CampaignEntryService.getEntries();
    }
    if (!mounted) return;
    setState(() => _campaignEntries = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        title: const Text(
          'Account',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
        ),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5E5DB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: AppTheme.primary, size: 42),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alex Johnson',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '+91 9876543210',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDA700),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.planLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update name and email',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
            ),
          ),
          _ActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Support & Help',
            subtitle: 'FAQ, ticket history and support requests',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
            ),
          ),
          _ActionTile(
            icon: Icons.location_on_outlined,
            title: 'Current City',
            subtitle: widget.cityName,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          const Text(
            'My Stamp Campaigns',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_campaignEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE1BEC0)),
              ),
              child: const Text(
                'No campaigns yet. Make a stamped purchase and your campaign entries will appear here.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _campaignEntries.length,
                itemBuilder: (_, i) {
                  final e = _campaignEntries[i];
                  return _CampaignEntryCard(entry: e);
                },
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Assistance?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Questions about stamps, payments, or plans?',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
                    ),
                    child: const Text('Get Support'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LogoutConfirmScreen(cityName: widget.cityName),
              ),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
            ),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Delete Account'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _CampaignEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final name = entry['campaign_name']?.toString() ?? 'Campaign';
    final store = entry['store_name']?.toString() ?? 'Store';
    final stamps = _readInt(entry['stamps_earned']) ?? 0;
    final target = (_readInt(entry['stamp_target']) ?? 10).clamp(1, 99);
    final progress = _progressPercent(stamps, target, entry['progress_percent']);
    final priceText = _priceLabel(entry);
    final imageUrl = ImageUtils.resolve(entry['image_url']);
    final tag = (entry['tag']?.toString().toUpperCase().trim().isNotEmpty ?? false)
        ? entry['tag'].toString().toUpperCase()
        : 'ENTERED';
    final activeBars = ((progress / 10).round()).clamp(1, 10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
      width: 220,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E5DB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1BEC0)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFAE1E3F),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (priceText.isNotEmpty)
                  Text(
                    priceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$progress%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$stamps / $target stamps',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(10, (index) {
                    final isActive = index < activeBars;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 9 ? 0 : 2),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFAE1E3F)
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  store,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  static Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFFBECE1),
      child: const Center(
        child: Icon(Icons.emoji_events_rounded, color: Color(0xFFCDA700), size: 42),
      ),
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static int _progressPercent(int stamps, int target, dynamic progressValue) {
    final parsed = _readInt(progressValue);
    if (parsed != null) return parsed.clamp(0, 100);
    return ((stamps / target) * 100).round().clamp(0, 100);
  }

  static String _priceLabel(Map<String, dynamic> entry) {
    final value = entry['campaign_reward_cost'] ?? entry['bill_amount'];
    if (value == null) return '';
    final n = value is num ? value.toDouble() : double.tryParse(value.toString());
    if (n == null || n <= 0) return '';
    final text = n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
    return '₹$text';
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1BEC0)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
