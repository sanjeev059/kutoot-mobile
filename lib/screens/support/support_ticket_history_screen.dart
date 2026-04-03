import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'submit_ticket_screen.dart';

class SupportTicketHistoryScreen extends StatelessWidget {
  const SupportTicketHistoryScreen({super.key});

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
                    child: const Text('Create New Ticket'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
