import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'screen_myrequest.dart';
// Put this file in e.g. lib/screens/foodcharity_dashboard.dart
// Use it from your existing app:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodCharityDashboard()));
// or set it as a route / home page.

const _fcGreen =AppColors.green;
const _fcGreenDark = AppColors.dark;
const _fcCream = Color(0xFFFDF6E9);
const _fcCard = Color(0xFFFFFDF8);
const _fcLine = Color(0xFFE4DCCB);
const _fcMint = Color(0xFFE1ECD9);
const _fcMuted = AppColors.textGrey;

class FcItem {
  final String name;
  final String meta;
  final String risk;
  final String days;
  final String image;

  const FcItem(
    this.name,
    this.meta,
    this.risk,
    this.days,
    this.image,
  );
}

class FoodCharityDashboard extends StatelessWidget {
  final String subtitle;
  final String totalItems;
  final String totalPayment;
  final List<FcItem> items;
  final bool showBottomNav; // set false if your app already has a nav bar

  const FoodCharityDashboard({
    super.key,
    this.subtitle = 'Business · Tesco Skudai',
    this.totalItems = '120',
    this.totalPayment = 'RM 980',
    this.showBottomNav = true,
    this.items = const [
  FcItem(
    'Sliced Bread',
    '50 packs · 12 Oct 2025',
    'High Risk',
    '2 days',
    'assets/images/Bread.jpg',
  ),
  FcItem(
    'Fresh Milk',
    '30 bottles · 11 Oct 2025',
    'High Risk',
    '1 day',
    'assets/images/farm_fresh_2l.jpg',
  ),
  FcItem(
    'Potato',
    '75 packs · 14 Oct 2025',
    'Medium',
    '3 days',
    'assets/images/POTATO.jpg',
  ),
  FcItem(
    'Egg',
    '40 packs · 13 Oct 2025',
    'High Risk',
    '2 days',
    'assets/images/eggs_gredC.jpg',
  ),
  ], });

  BoxDecoration _box(double r) => BoxDecoration(
      color: _fcCard,
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: _fcLine));

  Widget _title(String t, {String? trailing}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: _fcGreenDark)),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: _fcGreen)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fcCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          children: [
            // Header
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: _fcCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: _fcLine)),
                child: const Icon(Icons.notifications_none,
                    size: 18, color: _fcGreenDark),
              ),
              Row(children: [
                Container(
  width: 34,
  height: 34,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: _fcLine),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.asset(
      'assets/images/logo.jpg',
      fit: BoxFit.cover,
    ),
  ),
),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('SapuHabis!',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _fcGreen)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 8, color: _fcMuted)),
                ]),
              ]),
            ]),
            const SizedBox(height: 18),

            // Title
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Dashboard',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _fcGreenDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: _box(10),
                child: const Text('Oct 2025 📅',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _fcGreenDark)),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Manage your surplus inventory and make a bigger impact.',
                style: TextStyle(fontSize: 11, color: _fcMuted)),
            const SizedBox(height: 14),

            // Stats
            Row(children: [
              Expanded(child: _stat(totalItems, 'Total Items')),
              const SizedBox(width: 10),
              Expanded(child: _stat(totalPayment, 'Total Payment')),
            ]),
            const SizedBox(height: 18),

            // Inventory
            _title('Near-Expiry Inventory', trailing: 'View All ›'),
            Container(
              decoration: _box(14),
              child: Column(children: [
                for (int i = 0; i < items.length; i++) ...[
                  _row(items[i]),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: _fcLine),
                ],
              ]),
            ),
            const SizedBox(height: 18),

            // AI recommendation
            _title('AI Recommendations'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: _fcMint, borderRadius: BorderRadius.circular(12)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Discount Bread by 50%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _fcGreenDark)),
                      SizedBox(height: 2),
                      Text('High demand, expires in 2 days.',
                          style: TextStyle(fontSize: 10, color: _fcMuted)),
                    ]),
                    Icon(Icons.north_east, size: 16, color: _fcGreen),
                  ]),
            ),
            const SizedBox(height: 18),

            // Quick actions
            Row(children: [
              Expanded(
                child: _action(
                  Icons.add,
                  'Add Request',
                    primary: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                    ),
                ),
              ),
              
              const SizedBox(width: 8),
              Expanded(child: _action(Icons.storefront_outlined, 'View Supermarket')),
              const SizedBox(width: 8),
              Expanded(child: _action(Icons.local_shipping_outlined, 'Schedule Pickup')),
              const SizedBox(width: 8),
              Expanded(child: _action(Icons.bar_chart, 'View Analytics')),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavigationBar(
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              backgroundColor: _fcCard,
              selectedItemColor: _fcGreenDark,
              unselectedItemColor: _fcMuted,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Inventory'),
                BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favourite'),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
              ],
            )
          : null,
    );
  }

  Widget _stat(String value, String label) => Container(
        padding: const EdgeInsets.all(12),
        decoration: _box(14),
        child: Row(children: [
          ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Image.asset(
    label == 'Total Items'
        ? 'assets/images/total_item.png'
        : 'assets/images/total_payment.png',
    width: 35,
    height: 35,
    fit: BoxFit.cover,
  ),
),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: _fcMuted)),
          ]),
        ]),
      );

  Widget _row(FcItem item) {
    final high = item.risk == 'High Risk';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
          item.image,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          ),
        ),

        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            Text(item.meta,
                style: const TextStyle(fontSize: 9, color: _fcMuted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: high ? const Color(0xFFF8DCD5) : const Color(0xFFFBE3A6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(item.risk,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: high ? const Color(0xFFB3402D) : const Color(0xFF8A5D00))),
          ),
          const SizedBox(height: 2),
          Text(item.days,
              style: const TextStyle(fontSize: 9, color: _fcMuted)),
        ]),
        const Icon(Icons.chevron_right, size: 16, color: _fcMuted),
      ]),
    );
  }

  Widget _action(IconData icon, String label,
        {bool primary = false, VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: primary ? _fcGreen : _fcCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary ? _fcGreen : _fcLine),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: primary ? Colors.white : _fcGreenDark),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: primary ? Colors.white : _fcGreenDark)),
        ]),
      ),
    );
}