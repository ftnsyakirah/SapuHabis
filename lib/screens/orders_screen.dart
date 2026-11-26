import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/fc_common.dart';

enum OrderStatus { pending, scheduled, completed, cancelled }

class OrderEntry {
  final String id;
  final String item;
  final String partner;
  final int qty;
  final double amount;
  final DateTime pickup;
  final String? code;
  OrderStatus status;

  OrderEntry({
    required this.id,
    required this.item,
    required this.partner,
    required this.qty,
    required this.amount,
    required this.pickup,
    required this.status,
    this.code,
  });
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _tabs = ['All', 'Pending', 'Scheduled', 'Completed', 'Cancelled'];
  int _tab = 0;

  late final List<OrderEntry> _orders = [
    OrderEntry(
        id: 'SH-1042',
        item: 'Sliced Bread',
        partner: 'Tesco Skudai',
        qty: 50,
        amount: 125,
        pickup: DateTime.now().add(const Duration(days: 1)),
        status: OrderStatus.scheduled,
        code: 'K7Q2'),
    OrderEntry(
        id: 'SH-1041',
        item: 'Fresh Milk',
        partner: 'AEON Tebrau',
        qty: 30,
        amount: 0,
        pickup: DateTime.now().add(const Duration(days: 2)),
        status: OrderStatus.pending),
    OrderEntry(
        id: 'SH-1037',
        item: 'Potato',
        partner: "Lotus's",
        qty: 75,
        amount: 210,
        pickup: DateTime.now().subtract(const Duration(days: 3)),
        status: OrderStatus.completed,
        code: 'M3X9'),
    OrderEntry(
        id: 'SH-1030',
        item: 'Egg',
        partner: 'Jaya Grocer',
        qty: 40,
        amount: 96,
        pickup: DateTime.now().subtract(const Duration(days: 6)),
        status: OrderStatus.cancelled),
  ];

  List<OrderEntry> get _visible {
    if (_tab == 0) return _orders;
    final s = OrderStatus.values[_tab - 1];
    return _orders.where((o) => o.status == s).toList();
  }

  (String, Color, Color) _style(OrderStatus s) => switch (s) {
        OrderStatus.pending =>
          ('Pending', const Color(0xFFFBE3A6), const Color(0xFF8A5D00)),
        OrderStatus.scheduled =>
          ('Scheduled', const Color(0xFFE1ECD9), AppColors.dark),
        OrderStatus.completed =>
          ('Completed', AppColors.softGreen, AppColors.green),
        OrderStatus.cancelled =>
          ('Cancelled', const Color(0xFFF8DCD5), const Color(0xFFB3402D)),
      };

  Future<void> _cancel(OrderEntry o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cancel order?'),
        content: Text('Cancel ${o.id} (${o.item})? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok == true) setState(() => o.status = OrderStatus.cancelled);
  }

  void _details(OrderEntry o) {
    final (label, bg, fg) = _style(o.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: fcCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(
                child: Text(o.id,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dark))),
            FcChip(label, bg: bg, fg: fg),
          ]),
          const SizedBox(height: 14),
          _kv('Item', '${o.item} x ${o.qty}'),
          _kv('Supermarket', o.partner),
          _kv('Pickup date', fcDate(o.pickup)),
          _kv('Amount', o.amount == 0 ? 'Free (donation)' : 'RM ${o.amount.toStringAsFixed(2)}'),
          if (o.code != null) _kv('Pickup code', o.code!),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(
              width: 100,
              child: Text(k,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      backgroundColor: fcCream,
      body: SafeArea(
        child: Column(children: [
          const FcPageHeader(
              title: 'Orders', subtitle: 'Track your pickups and purchases.'),
          FcFilterBar(
              options: _tabs,
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 10),
          Expanded(
            child: list.isEmpty
                ? const FcEmptyState(
                    icon: Icons.assignment_outlined,
                    message: 'No orders here yet.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(list[i]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _card(OrderEntry o) {
    final (label, bg, fg) = _style(o.status);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _details(o),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: fcBox(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.item,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${o.qty} units · ${o.partner}',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textGrey)),
                  ]),
            ),
            FcChip(label, bg: bg, fg: fg),
          ]),
          const Divider(height: 18, color: fcLine),
          Row(children: [
            const Icon(Icons.event_outlined,
                size: 14, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text(fcDate(o.pickup),
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textGrey)),
            const Spacer(),
            Text(o.amount == 0 ? 'Free' : 'RM ${o.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark)),
          ]),
          if (o.status == OrderStatus.pending)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancel(o),
                child: const Text('Cancel order',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB3402D))),
              ),
            ),
        ]),
      ),
    );
  }
}
