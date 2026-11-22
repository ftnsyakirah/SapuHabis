import 'package:flutter/material.dart';

// Save as lib/FoodCharity/screen_my_requests.dart

const _green = Color(0xFF1F6B45);
const _greenDark = Color(0xFF17452E);
const _cream = Color(0xFFFDF6E9);
const _card = Color(0xFFFFFDF8);
const _line = Color(0xFFE4DCCB);
const _mint = Color(0xFFE1ECD9);
const _muted = Color(0xFF6B6B60);

class NeedItem {
  final IconData icon;
  final String name, level; // level: High / Medium / Low
  const NeedItem(this.icon, this.name, this.level);
}

class Donation {
  final String name, meta, date;
  final String? image; // asset path, e.g. 'assets/bread.png'
  final IconData icon; // used when image is null
  const Donation(this.name, this.meta, this.date, {this.image, this.icon = Icons.fastfood});
}

class MyRequestsScreen extends StatefulWidget {
  final String subtitle;
  final List<NeedItem> needs;
  final List<Donation> donations;
  final bool showBottomNav;

  const MyRequestsScreen({
    super.key,
    this.subtitle = 'Food Bank · Johor Food Bank',
    this.showBottomNav = true,
    this.needs = const [
      NeedItem(Icons.local_drink_outlined, 'Milk', 'High'),
      NeedItem(Icons.eco_outlined, 'Vegetables', 'High'),
      NeedItem(Icons.bakery_dining_outlined, 'Bread', 'Medium'),
      NeedItem(Icons.inventory_2_outlined, 'Rice', 'Low'),
    ],
    this.donations = const [
      Donation('Bread Bundle', '100 packs · Tesco Skudai', '12 Oct 2025', icon: Icons.bakery_dining),
      Donation('Vegetables Box', '200 kg · AEON Tebrau', '13 Oct 2025', icon: Icons.eco),
      Donation('Milk', '150 bottles · Lotus\'s', '11 Oct 2025', icon: Icons.local_drink),
      Donation('Fruits', '80 kg · Jaya Grocer', '', icon: Icons.apple),
    ],
  });

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _tab = 0;
  final Set<int> _requested = {};
  static const _tabs = ['Available Item', 'Cart', 'History'];

  BoxDecoration _box(double r) => BoxDecoration(
      color: _card, borderRadius: BorderRadius.circular(r), border: Border.all(color: _line));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          children: [
            _header(context),
            const SizedBox(height: 14),
            const Text('My Requests',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _greenDark)),
            const SizedBox(height: 12),
            _tabBar(),
            const SizedBox(height: 14),
            if (_tab == 0) ..._availableTab() else _emptyTab(_tabs[_tab]),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 0,
              type: BottomNavigationBarType.fixed,
              backgroundColor: _card,
              selectedItemColor: _greenDark,
              unselectedItemColor: _muted,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              onTap: (i) {
                if (i == 0) Navigator.of(context).maybePop(); // back to dashboard
              },
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

  Widget _header(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(), // bell slot doubles as back
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: _card, shape: BoxShape.circle, border: Border.all(color: _line)),
              child: const Icon(Icons.arrow_back, size: 18, color: _greenDark),
            ),
          ),
          Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(8)),
              child: const Text('U',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('SapuHabis!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _green)),
              Text(widget.subtitle, style: const TextStyle(fontSize: 8, color: _muted)),
            ]),
          ]),
        ],
      );

  Widget _tabBar() => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? _card : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_tabs[i],
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w500,
                          color: _greenDark)),
                ),
              ),
            ),
        ]),
      );

  List<Widget> _availableTab() => [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Our Current Needs',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _greenDark)),
            const SizedBox(height: 10),
            Row(children: [
              for (int i = 0; i < widget.needs.length; i++) ...[
                Expanded(child: _needTile(widget.needs[i])),
                if (i < widget.needs.length - 1) const SizedBox(width: 6),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          Text('Matched Donations',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _greenDark)),
          Text('View All ›',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _green)),
        ]),
        const SizedBox(height: 8),
        for (int i = 0; i < widget.donations.length; i++) _donationCard(i, widget.donations[i]),
      ];

  Widget _needTile(NeedItem n) {
    final colors = switch (n.level) {
      'High' => (const Color(0xFFF8DCD5), const Color(0xFFB3402D)),
      'Medium' => (const Color(0xFFFBE3A6), const Color(0xFF8A5D00)),
      _ => (_mint, _greenDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(n.icon, size: 26, color: _greenDark),
        const SizedBox(height: 8),
        Text(n.name,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _greenDark)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: colors.$1, borderRadius: BorderRadius.circular(6)),
          child: Text(n.level,
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: colors.$2)),
        ),
      ]),
    );
  }

  Widget _donationCard(int index, Donation d) {
    final done = _requested.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: _box(14),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration:
              BoxDecoration(color: const Color(0xFFF1E7D2), borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: d.image != null
              ? Image.asset(d.image!, fit: BoxFit.cover)
              : Icon(d.icon, color: _greenDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _greenDark)),
            const SizedBox(height: 2),
            Text(d.meta, style: const TextStyle(fontSize: 10, color: _muted)),
            if (d.date.isNotEmpty)
              Text(d.date, style: const TextStyle(fontSize: 9, color: _muted)),
          ]),
        ),
        ElevatedButton(
          onPressed: done ? null : () => setState(() => _requested.add(index)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _mint,
            disabledForegroundColor: _greenDark,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(done ? 'Requested' : 'Request',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _emptyTab(String name) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text('$name is empty for now.',
              style: const TextStyle(fontSize: 12, color: _muted)),
        ),
      );
}