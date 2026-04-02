import 'package:flutter/material.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import 'submit_ticket_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = KutootApi();
  List<Map<String, dynamic>> _activeTickets = [];
  List<Map<String, dynamic>> _closedTickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getSupportTickets(params: {'status': 'open'}).then<dynamic>((r) => r).catchError((_) => null),
        _api.getSupportTickets(params: {'status': 'resolved'}).then<dynamic>((r) => r).catchError((_) => null),
      ]);
      if (mounted) {
        _activeTickets = _parseTickets(results[0]);
        _closedTickets = _parseTickets(results[1]);
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _parseTickets(dynamic res) {
    if (res == null) return [];
    final data = res.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((t) => t is Map ? Map<String, dynamic>.from(t) : <String, dynamic>{}).toList();
    }
    return [];
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
        title: const Text('My Tickets', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [Tab(text: 'Active'), Tab(text: 'Closed')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TicketList(tickets: _activeTickets),
                  _TicketList(tickets: _closedTickets),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketScreen())),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(t['id'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (t['status'] == 'Open' ? AppTheme.primary : Colors.grey).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t['status'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t['status'] == 'Open' ? AppTheme.primary : Colors.grey)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(t['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(t['date'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }
}
