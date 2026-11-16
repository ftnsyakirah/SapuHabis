import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/common.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  static const _options = [5, 10, 15, 20, 25, 30, 40, 50];

  // discount % per item (default 10%)
  late final List<int> _discounts = List.filled(sellItems.length, 10);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      subtitle: 'Inventory · Sell',
      body: Column(
        children: [
          Expanded(
            child: ListCard(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: sellItems.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: kBorder),
                itemBuilder: (_, i) => _sellRow(i),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GreenPillButton(
            label: 'Generate report',
            height: 42,
            fontSize: 14,
            onPressed: () {
              // TODO: generate report from sellItems + _discounts
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report generated')),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sellRow(int i) {
    final item = sellItems[i];
    final pct = _discounts[i];
    final discounted = item.price * (1 - pct / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              ItemThumb(path: item.image),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: kText)),
                    const SizedBox(height: 2),
                    Text(item.detail,
                        style: const TextStyle(fontSize: 8, color: kGrey)),
                  ],
                ),
              ),
              _discountPill(i),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Original Price: RM ${item.price.toStringAsFixed(2)}  '
              'After discount: ${discounted.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 8, color: kGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountPill(int i) {
    return Container(
      height: 22,
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
            onTap: () {
              // TODO: apply discount to this item
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 10, right: 8),
              child: Text('Add discount',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          Container(width: 1, height: 22, color: Colors.white54),
          PopupMenuButton<int>(
            tooltip: 'Discount percentage',
            padding: EdgeInsets.zero,
            onSelected: (v) => setState(() => _discounts[i] = v),
            itemBuilder: (_) => _options
                .map((p) => PopupMenuItem(value: p, child: Text('$p%')))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_discounts[i]}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 12, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
