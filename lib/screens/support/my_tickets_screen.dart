import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'submit_ticket_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _activeTickets = [
    {
      'id': 'TKT-001',
      'subject': 'Payment not reflected',
      'date': 'Oct 26, 2024',
      'status': 'Open'
    },
  ];

  final _closedTickets = [
    {
      'id': 'TKT-000',
      'subject': 'Reward redemption issue',
      'date': 'Oct 20, 2024',
      'status': 'Resolved'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Tickets',
            style: TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Closed')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TicketList(tickets: _activeTickets),
          _TicketList(tickets: _closedTickets),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SubmitTicketScreen())),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<Map<String, dynamic>> tickets;

  const _TicketList({required this.tickets});

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const Center(child: Text('No tickets'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (context, i) {
        final t = tickets[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(t['id'] ?? '',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (t['status'] == 'Open'
                              ? AppTheme.primary
                              : Colors.grey)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t['status'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t['status'] == 'Open'
                                ? AppTheme.primary
                                : Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(t['subject'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(t['date'] ?? '',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
