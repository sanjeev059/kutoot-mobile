import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import 'submit_ticket_screen.dart';

class SupportTicketHistoryScreen extends StatefulWidget {
  const SupportTicketHistoryScreen({super.key});

  @override
  State<SupportTicketHistoryScreen> createState() => _SupportTicketHistoryScreenState();
}

class _SupportTicketHistoryScreenState extends State<SupportTicketHistoryScreen> {
  final _api = KutootApi();
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final res = await _api.getSupportTickets();
      if (mounted && res.data is Map) {
        final d = (res.data as Map)['data'];
        setState(() {
          _tickets = (d is List ? d : []).map((t) => Map<String, dynamic>.from(t is Map ? t : {})).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'open':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFFEA6B1E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Support Tickets',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          _TicketCard(
            id: '#TKT-10293',
            status: 'Under Review',
            statusColor: const Color(0xFFEA6B1E),
            date: '24 Oct 2026, 02:30 PM',
            message:
                'Reward points were not credited after payment. Receipt attached.',
          ),
          _TicketCard(
            id: '#TKT-09844',
            status: 'Resolved',
            statusColor: const Color(0xFF2E7D32),
            date: '18 Oct 2026, 11:15 AM',
            message: 'Promo code issue during checkout.',
          ),
          _TicketCard(
            id: '#TKT-09721',
            status: 'Pending',
            statusColor: const Color(0xFFBA1A1A),
            date: '15 Oct 2026, 09:45 AM',
            message: 'Requested delivery address update for active plan.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1BEC0)),
            ),
            child: Column(
              children: [
                const Text('Need new help?',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 8),
                const Text(
                  'Our team is online 24/7 for your support requests.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SubmitTicketScreen()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final String id;
  final String status;
  final Color statusColor;
  final String date;
  final String message;

  const _TicketCard({
    required this.id,
    required this.status,
    required this.statusColor,
    required this.date,
    required this.message,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1BEC0)),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: Text(widget.id,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(widget.date, style: const TextStyle(fontSize: 12)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      color: widget.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18),
              ],
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(widget.message,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ),
        ],
      ),
    );
  }
}
