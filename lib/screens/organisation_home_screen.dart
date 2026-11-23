import 'dart:async';

import 'package:flutter/material.dart';

import '../services/catalog_api.dart';
import '../theme/app_colors.dart';
import '../widgets/sapu_logo.dart';

class OrganisationHomeScreen extends StatefulWidget {
  final String organisationName;

  final String baseUrl;

  final double? userLat;
  final double? userLng;

  const OrganisationHomeScreen({
    super.key,
    this.organisationName = 'SapuHabis',
    this.baseUrl = 'http://10.0.2.2:8000',
    this.userLat,
    this.userLng,
  });

  @override
  State<OrganisationHomeScreen> createState() => _OrganisationHomeScreenState();
}

class _OrganisationHomeScreenState extends State<OrganisationHomeScreen> {
  static const _urgent = Color(0xFFB3261E);

  late final CatalogService _api;
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;

  CatalogFilters _filters = CatalogFilters();
  CatalogSort _sort = CatalogSort.nearestExpiry;
  CatalogFacets? _facets;

  List<CatalogItem> _items = [];
  int _page = 0;
  int _total = 0;
  bool _hasNext = false;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _requestId = 0;
  int _tab = 0;

  bool get _hasLocation => widget.userLat != null && widget.userLng != null;

  @override
  void initState() {
    super.initState();
    _api = CatalogService(baseUrl: widget.baseUrl);
    _scroll.addListener(_onScroll);
    _loadFirstPage();
    _loadFacets();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scroll.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadFacets() async {
    try {
      final facets = await _api.facets();
      if (mounted) setState(() => _facets = facets);
    } catch (_) {}
  }

  Future<void> _loadFirstPage() async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    try {
      final result = await _api.search(
        query: _searchCtrl.text,
        filters: _filters,
        sort: _sort,
        page: 1,
        lat: widget.userLat,
        lng: widget.userLng,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = result.items;
        _page = result.page;
        _total = result.total;
        _hasNext = result.hasNext;
        _loading = false;
      });
    } on CatalogApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasNext) return;
    final id = _requestId;
    setState(() => _loadingMore = true);
    try {
      final result = await _api.search(
        query: _searchCtrl.text,
        filters: _filters,
        sort: _sort,
        page: _page + 1,
        lat: widget.userLat,
        lng: widget.userLng,
      );
      if (!mounted || id != _requestId) return;
      setState(() {
        _items = [..._items, ...result.items];
        _page = result.page;
        _hasNext = result.hasNext;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scroll.hasClients &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  void _onSearchChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadFirstPage);
  }

  void _applyFilters(void Function(CatalogFilters f) change) {
    setState(() => change(_filters));
    _loadFirstPage();
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<CatalogFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initial: _filters.copy(),
        facets: _facets,
        hasLocation: _hasLocation,
      ),
    );
    if (result != null) {
      setState(() => _filters = result);
      _loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _loadFirstPage,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              ..._buildBody(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SapuLogo(height: 34),
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  _CircleIconButton(
                    icon: Icons.person_outline_rounded,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'WELCOME BACK',
            style: TextStyle(
              fontSize: 10.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.organisationName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find surplus food nearby for the people you serve.',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 18),
          _buildSearchRow(),
          const SizedBox(height: 12),
          _buildQuickChips(),
          const SizedBox(height: 16),
          _buildResultsBar(),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    final active = _filters.activeCount;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onSubmitted: (_) {
                _debounce?.cancel();
                _loadFirstPage();
              },
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, color: AppColors.dark),
              decoration: InputDecoration(
                hintText: 'Search bread, rice, halal...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.textGrey,
                ),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          _debounce?.cancel();
                          setState(() {});
                          _loadFirstPage();
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openFilters,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active > 0 ? AppColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: active > 0 ? AppColors.green : AppColors.border,
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 22,
                  color: active > 0 ? Colors.white : AppColors.dark,
                ),
              ),
              if (active > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PillChip(
            label: 'Free donations',
            icon: Icons.volunteer_activism_outlined,
            selected: _filters.listingType == 'donation',
            onTap: () => _applyFilters((f) {
              f.listingType = f.listingType == 'donation' ? null : 'donation';
            }),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Expiring in 3h',
            icon: Icons.timer_outlined,
            selected: _filters.expiringWithinHours == 3,
            onTap: () => _applyFilters((f) {
              f.expiringWithinHours = f.expiringWithinHours == 3 ? null : 3;
            }),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: 'Halal',
            selected: _filters.tags.contains('halal'),
            onTap: () => _applyFilters((f) {
              if (!f.tags.remove('halal')) f.tags.add('halal');
            }),
          ),
          const SizedBox(width: 8),
          _PillChip(
            label: '50% off or more',
            selected: _filters.minDiscount == 50,
            onTap: () => _applyFilters((f) {
              f.minDiscount = f.minDiscount == 50 ? null : 50;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _loading ? 'Searching...' : '$_total listing${_total == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
        PopupMenuButton<CatalogSort>(
          tooltip: 'Sort',
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) {
            setState(() => _sort = value);
            _loadFirstPage();
          },
          itemBuilder: (_) => [
            for (final option in CatalogSort.values)
              PopupMenuItem<CatalogSort>(
                value: option,
                enabled: !option.needsLocation || _hasLocation,
                child: Row(
                  children: [
                    Icon(
                      option == _sort ? Icons.check_rounded : null,
                      size: 18,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      option.needsLocation && !_hasLocation
                          ? '${option.label} (needs location)'
                          : option.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.dark),
                const SizedBox(width: 6),
                Text(
                  _sort.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator(color: AppColors.green)),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: Icons.cloud_off_rounded,
            title: _error!,
            subtitle: 'Check that the server is running and try again.',
            actionLabel: 'Try again',
            onAction: _loadFirstPage,
          ),
        ),
      ];
    }
    if (_items.isEmpty) {
      final filtered = _filters.activeCount > 0 || _searchCtrl.text.isNotEmpty;
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _MessageState(
            icon: Icons.search_off_rounded,
            title: 'No listings found',
            subtitle: filtered
                ? 'Try removing a filter or searching for something else.'
                : 'New surplus food will appear here as shops post it.',
            actionLabel: filtered ? 'Clear search and filters' : null,
            onAction: filtered
                ? () {
                    _searchCtrl.clear();
                    _filters.clear();
                    _loadFirstPage();
                  }
                : null,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList.separated(
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i >= _items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.green,
                    ),
                  ),
                ),
              );
            }
            return _ListingCard(
              item: _items[i],
              urgentColor: _urgent,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Open ${_items[i].title}')),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) {
            if (i == 0) {
              setState(() => _tab = 0);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon')),
              );
            }
          },
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.green,
          unselectedItemColor: AppColors.textGrey,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'bakery':
      return Icons.bakery_dining_rounded;
    case 'produce':
      return Icons.eco_rounded;
    case 'dairy':
      return Icons.egg_alt_outlined;
    case 'beverages':
      return Icons.local_drink_rounded;
    case 'desserts':
      return Icons.cake_rounded;
    case 'meals':
      return Icons.lunch_dining_rounded;
    case 'frozen':
      return Icons.ac_unit_rounded;
    case 'pantry':
      return Icons.inventory_2_outlined;
    default:
      return Icons.fastfood_rounded;
  }
}

class _ListingCard extends StatelessWidget {
  final CatalogItem item;
  final Color urgentColor;
  final VoidCallback onTap;

  const _ListingCard({
    required this.item,
    required this.urgentColor,
    required this.onTap,
  });

  Widget _thumbnailFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9DCC0), Color(0xFFB9D7B0)],
          ),
        ),
        child: Icon(_categoryIcon(item.category), size: 30, color: Colors.white70),
      );

  @override
  Widget build(BuildContext context) {
    final soon = item.expiryAt.difference(DateTime.now()).inHours < 3;
    final distance = item.distanceKm;
    final subtitle = distance == null
        ? item.business.name
        : '${item.business.name} · ${distance.toStringAsFixed(1)} km';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.imageUrl == null
                    ? _thumbnailFallback()
                    : Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbnailFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Badge(
                        icon: Icons.timer_outlined,
                        label: item.expiryLabel,
                        color: soon ? urgentColor : AppColors.green,
                        background: soon
                            ? urgentColor.withOpacity(0.10)
                            : AppColors.softGreen,
                      ),
                      _Badge(
                        label: item.isSoldOut ? 'Sold out' : '${item.quantityLeft} left',
                        color: AppColors.textGrey,
                        background: AppColors.cream,
                      ),
                      if (item.isDonation)
                        const _Badge(
                          icon: Icons.volunteer_activism_outlined,
                          label: 'Donation',
                          color: AppColors.dark,
                          background: AppColors.lime,
                        ),
                    ],
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.tags.map(_cap).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.priceLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                if (item.originalPrice > item.price) ...[
                  const SizedBox(height: 2),
                  Text(
                    'RM ${item.originalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                if (item.discountPercent > 0) ...[
                  const SizedBox(height: 6),
                  _Badge(
                    label: '${item.discountPercent}% off',
                    color: AppColors.green,
                    background: AppColors.softGreen,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color background;

  const _Badge({
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.dark),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.green : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 30, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textGrey),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Option<T> {
  final String label;
  final T value;
  const _Option(this.label, this.value);
}

class _FilterSheet extends StatefulWidget {
  final CatalogFilters initial;
  final CatalogFacets? facets;
  final bool hasLocation;

  const _FilterSheet({
    required this.initial,
    required this.facets,
    required this.hasLocation,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Set<String> _categories;
  late Set<String> _tags;
  late String? _listingType;
  late int? _minDiscount;
  late int? _expiringWithinHours;
  late double? _maxDistanceKm;
  late RangeValues _price;

  late final double _priceCeil;
  static const double _priceFloor = 0;

  static const _fallbackCategories = [
    'bakery', 'vegetables', 'dairy', 'beverages', 'desserts', 'meals', 'frozen', 'pantry',
  ];
  static const _fallbackTags = ['halal', 'kosher', 'vegan', 'vegetarian'];

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _categories = {...f.categories};
    _tags = {...f.tags};
    _listingType = f.listingType;
    _minDiscount = f.minDiscount;
    _expiringWithinHours = f.expiringWithinHours;
    _maxDistanceKm = f.maxDistanceKm;

    final serverMax = widget.facets?.maxPrice ?? 30;
    _priceCeil = serverMax < 1 ? 1 : serverMax.ceilToDouble();
    _price = RangeValues(
      (f.minPrice ?? _priceFloor).clamp(_priceFloor, _priceCeil).toDouble(),
      (f.maxPrice ?? _priceCeil).clamp(_priceFloor, _priceCeil).toDouble(),
    );
  }

  void _clearAll() {
    setState(() {
      _categories.clear();
      _tags.clear();
      _listingType = null;
      _minDiscount = null;
      _expiringWithinHours = null;
      _maxDistanceKm = null;
      _price = RangeValues(_priceFloor, _priceCeil);
    });
  }

  void _apply() {
    final result = CatalogFilters(
      categories: _categories,
      tags: _tags,
      listingType: _listingType,
      minPrice: _price.start > _priceFloor ? _price.start : null,
      maxPrice: _price.end < _priceCeil ? _price.end : null,
      minDiscount: _minDiscount,
      expiringWithinHours: _expiringWithinHours,
      maxDistanceKm: widget.hasLocation ? _maxDistanceKm : null,
      includeSoldOut: widget.initial.includeSoldOut,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final categoryNames = widget.facets?.categories.map((c) => c.name).toList() ??
        _fallbackCategories;
    final tagNames =
        widget.facets?.tags.map((t) => t.name).toList() ?? _fallbackTags;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark,
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearAll,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Listing type'),
                      _singleChoice<String?>(
                        options: const [
                          _Option('All', null),
                          _Option('For sale', 'sale'),
                          _Option('Free donation', 'donation'),
                        ],
                        selected: _listingType,
                        onChanged: (v) => setState(() => _listingType = v),
                      ),
                      _section('Category'),
                      _multiChoice(
                        names: categoryNames,
                        selected: _categories,
                        counts: {
                          for (final c in widget.facets?.categories ?? <CatalogFacet>[])
                            c.name: c.count,
                        },
                      ),
                      _section('Dietary'),
                      _multiChoice(
                        names: tagNames,
                        selected: _tags,
                        counts: {
                          for (final t in widget.facets?.tags ?? <CatalogFacet>[])
                            t.name: t.count,
                        },
                      ),
                      _section('Price'),
                      Text(
                        'RM ${_price.start.toStringAsFixed(0)} to '
                        'RM ${_price.end.toStringAsFixed(0)}'
                        '${_price.end >= _priceCeil ? '+' : ''}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.green,
                          thumbColor: AppColors.green,
                          inactiveTrackColor: AppColors.border,
                          overlayColor: AppColors.green.withOpacity(0.12),
                        ),
                        child: RangeSlider(
                          values: _price,
                          min: _priceFloor,
                          max: _priceCeil,
                          divisions: _priceCeil.round().clamp(1, 200),
                          onChanged: (v) => setState(() => _price = v),
                        ),
                      ),
                      _section('Discount'),
                      _singleChoice<int?>(
                        options: const [
                          _Option('Any', null),
                          _Option('30%+', 30),
                          _Option('50%+', 50),
                          _Option('70%+', 70),
                        ],
                        selected: _minDiscount,
                        onChanged: (v) => setState(() => _minDiscount = v),
                      ),
                      _section('Expires within'),
                      _singleChoice<int?>(
                        options: const [
                          _Option('Any', null),
                          _Option('2 hours', 2),
                          _Option('6 hours', 6),
                          _Option('24 hours', 24),
                        ],
                        selected: _expiringWithinHours,
                        onChanged: (v) => setState(() => _expiringWithinHours = v),
                      ),
                      if (widget.hasLocation) ...[
                        _section('Distance'),
                        _singleChoice<double?>(
                          options: const [
                            _Option('Any', null),
                            _Option('2 km', 2.0),
                            _Option('5 km', 5.0),
                            _Option('10 km', 10.0),
                          ],
                          selected: _maxDistanceKm,
                          onChanged: (v) => setState(() => _maxDistanceKm = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Show results',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.dark,
          ),
        ),
      );

  Widget _singleChoice<T>({
    required List<_Option<T>> options,
    required T selected,
    required ValueChanged<T> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          _PillChip(
            label: o.label,
            selected: o.value == selected,
            onTap: () => onChanged(o.value),
          ),
      ],
    );
  }

  Widget _multiChoice({
    required List<String> names,
    required Set<String> selected,
    required Map<String, int> counts,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in names)
          _PillChip(
            label: counts.containsKey(name) ? '${_cap(name)} (${counts[name]})' : _cap(name),
            selected: selected.contains(name),
            onTap: () => setState(() {
              if (!selected.remove(name)) selected.add(name);
            }),
          ),
      ],
    );
  }
}
