import 'package:flutter/material.dart';
import '../FoodCharity/screen_dashboard.dart';
import '../theme/app_colors.dart';
import '../widgets/fc_common.dart';
import 'favourite_screen.dart';
import 'inventory_screen.dart';
import 'more_screen.dart';
import 'orders_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          FoodCharityDashboard(showBottomNav: false),
          OrdersScreen(),
          InventoryScreen(),
          FavouriteScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        backgroundColor: fcCard,
        selectedItemColor: AppColors.dark,
        unselectedItemColor: AppColors.textGrey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favourite'),
          BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
