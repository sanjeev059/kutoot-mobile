import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../api/kutoot_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_utils.dart';
import 'store_profile_screen.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final _api = KutootApi();
  List<dynamic> _categories = [];
  List<dynamic> _stores = [];
  bool _loading = true;
  String? _error;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getStoreCategories();
      final data = res.data;
      List<dynamic> cats = [];
      if (data is Map && data['data'] != null) {
        cats = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        cats = data;
      }
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
        if (cats.isNotEmpty && _selectedCategoryId == null) {
          final firstId = cats[0] is Map ? (cats[0] as Map)['id'] : null;
          if (firstId != null) _loadStores(firstId is int ? firstId : int.tryParse(firstId.toString()) ?? 0);
        } else if (cats.isEmpty) {
          _loadMerchantLocations();
        }
      }
    } catch (e) {
      _loadMerchantLocations();
    }
  }

  Future<void> _loadMerchantLocations() async {
    try {
      final res = await _api.getMerchantLocations();
      final data = res.data;
      List<dynamic> stores = [];
      if (data is Map && data['data'] != null) {
        stores = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        stores = data;
      }
      if (mounted) setState(() {
        _stores = stores;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadStores(int categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _loading = true;
    });
    try {
      final res = await _api.getStoresByCategory(categoryId);
      final data = res.data;
      List<dynamic> stores = [];
      if (data is Map && data['data'] != null) {
        stores = data['data'] is List ? data['data'] as List : [];
      } else if (data is List) {
        stores = data;
      }
      if (mounted) setState(() {
        _stores = stores;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Stores', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _loading && _stores.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null && _stores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadCategories, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_categories.isNotEmpty)
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _categories.length,
                          itemBuilder: (context, i) {
                            final c = _categories[i] is Map ? _categories[i] as Map : {};
                            final id = c['id'];
                            final name = c['name'] ?? 'Category';
                            final isSelected = _selectedCategoryId == id;
                            final catImageUrl = ImageUtils.fromCategory(c);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                avatar: catImageUrl != null && catImageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: catImageUrl,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Icon(Icons.category_rounded, size: 24, color: AppTheme.primary),
                                          errorWidget: (_, __, ___) => Icon(Icons.category_rounded, size: 24, color: AppTheme.primary),
                                        ),
                                      )
                                    : Icon(Icons.category_rounded, size: 24, color: AppTheme.primary),
                                label: Text(name),
                                selected: isSelected,
                                onSelected: (_) {
                                  if (id != null) _loadStores(id is int ? id : int.tryParse(id.toString()) ?? 0);
                                },
                                selectedColor: AppTheme.primary.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    Expanded(
                      child: _stores.isEmpty
                          ? const Center(child: Text('No stores in this category'))
                          : RefreshIndicator(
                              onRefresh: () => _selectedCategoryId != null ? _loadStores(_selectedCategoryId!) : _loadCategories(),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _stores.length,
                                itemBuilder: (context, i) {
                                  final s = _stores[i] is Map ? _stores[i] as Map : {};
                                  final name = s['branch_name'] ?? s['name'] ?? s['store_name'] ?? 'Store';
                                  final address = s['address'] ?? s['location'] ?? '';
                                  final storeImageUrl = ImageUtils.fromStore(s);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
                                    ),
                                    child: ListTile(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreProfileScreen(store: Map.from(s)))),
                                      contentPadding: const EdgeInsets.all(16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: storeImageUrl != null && storeImageUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: storeImageUrl,
                                                width: 48,
                                                height: 48,
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(color: AppTheme.primary.withOpacity(0.15), child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 28)),
                                                errorWidget: (_, __, ___) => Container(color: AppTheme.primary.withOpacity(0.15), child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 28)),
                                              )
                                            : Container(
                                                width: 48,
                                                height: 48,
                                                color: AppTheme.primary.withOpacity(0.15),
                                                child: const Icon(Icons.store_rounded, color: AppTheme.primary, size: 28),
                                              ),
                                      ),
                                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: address.toString().isNotEmpty ? Text(address.toString(), maxLines: 2, overflow: TextOverflow.ellipsis) : null,
                                      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}
