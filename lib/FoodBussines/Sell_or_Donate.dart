import 'package:flutter/material.dart';

void main() => runApp(const SapuHabisApp());

// ---------- Theme colors ----------
const kGreen = Color(0xFF1F6F4A);
const kGreenLight = Color(0xFFDDEBDD);
const kBackground = Color(0xFFFFF8EA);
const kCardBorder = Color(0xFFE3E0D6);
const kGrey = Color(0xFF6B6B6B);

class SapuHabisApp extends StatelessWidget {
  const SapuHabisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SapuHabis!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
        // Add google_fonts (Manrope) if you want the exact font:
        // textTheme: GoogleFonts.manropeTextTheme(),
      ),
      home: const InventoryScreen(),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _currentIndex = 1; // Inventory tab selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const _Header(),
              const SizedBox(height: 56),
              ActionCard(
                imagePath: 'assets/images/sell.jpg',
                fallbackIcon: Icons.shopping_cart_outlined,
                text: 'Put discount on\ninventory items.',
                buttonLabel: 'Sell',
                onPressed: () {
                  // TODO: navigate to Sell / Discount screen
                },
              ),
              const SizedBox(height: 40),
              ActionCard(
                imagePath: 'assets/images/donate.jpg',
                fallbackIcon: Icons.volunteer_activism_outlined,
                text: 'Donate invetory\nitems to charity\norganization.',
                buttonLabel: 'Donate',
                onPressed: () {
                  // TODO: navigate to Donate screen
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ---------- Header ----------
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notification bell
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kCardBorder),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.notifications_none, size: 20, color: kGreen),
            onPressed: () {},
          ),
        ),
        const Spacer(),
        // Logo + screen title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: kGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SapuHabis!',
                  style: TextStyle(
                    color: kGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Inventory',
                style: TextStyle(fontSize: 10, color: kGrey),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- Reusable Sell / Donate card ----------
class ActionCard extends StatelessWidget {
  final String imagePath;
  final IconData fallbackIcon;
  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  const ActionCard({
    super.key,
    required this.imagePath,
    required this.fallbackIcon,
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCardBorder),
      ),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            // Image (falls back to an icon if asset is missing)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(20),
              ),
              child: SizedBox(
                width: 148,
                height: 100,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kGreenLight,
                    child: Icon(fallbackIcon, size: 40, color: kGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Bottom navigation ----------
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Dashboard'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Inventory'),
    (Icons.assignment_outlined, Icons.assignment, 'Orders'),
    (Icons.favorite_border, Icons.favorite, 'Donations'),
    (Icons.more_horiz, Icons.more_horiz, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBF2),
        border: Border(top: BorderSide(color: kCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final item = _items[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 30,
                      decoration: BoxDecoration(
                        color: selected ? kGreenLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        selected ? item.$2 : item.$1,
                        size: 20,
                        color: selected ? kGreen : const Color(0xFF3A3A3A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kGreen : const Color(0xFF3A3A3A),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}