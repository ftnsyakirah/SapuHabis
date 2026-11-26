import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/catalog_api.dart';
import '../services/order_api.dart';
import '../theme/app_colors.dart';

class CheckoutScreen extends StatefulWidget {
  final CatalogItem item;
  final String baseUrl;

  const CheckoutScreen({
    super.key,
    required this.item,
    this.baseUrl = 'http://10.0.2.2:8000',
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

enum _Stage { form, creating, waiting, done }

class _CheckoutScreenState extends State<CheckoutScreen> with WidgetsBindingObserver {
  late final OrderService _orders;
  Timer? _poll;

  _Stage _stage = _Stage.form;
  int _quantity = 1;
  PaymentMethod _method = PaymentMethod.any;
  Order? _order;
  String? _error;

  CatalogItem get _item => widget.item;
  bool get _free => _item.isDonation || _item.price == 0;
  int get _maxQuantity => _item.quantityLeft.clamp(1, 10).toInt();
  double get _total => _item.price * _quantity;

  @override
  void initState() {
    super.initState();
    _orders = OrderService(baseUrl: widget.baseUrl);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _orders.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _stage == _Stage.waiting) _refresh();
  }


  Future<void> _pay() async {
    setState(() {
      _stage = _Stage.creating;
      _error = null;
    });
    try {
      final order = await _orders.createOrder(
        listingId: _item.id,
        quantity: _quantity,
        method: _method,
      );
      if (!mounted) return;
      if (!order.isPending) {
        setState(() {
          _order = order;
          _stage = _Stage.done;
        });
        return;
      }
      setState(() {
        _order = order;
        _stage = _Stage.waiting;
      });
      await _openPaymentPage();
      _poll = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    } on OrderApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.form;
      });
    }
  }

  Future<void> _openPaymentPage() async {
    final url = _order?.checkoutUrl;
    if (url == null) return;
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _error = 'Could not open the payment page.');
    }
  }

  Future<void> _refresh() async {
    final current = _order;
    if (current == null || !mounted) return;
    try {
      final latest = await _orders.getOrder(current.id);
      if (!mounted) return;
      setState(() => _order = latest);
      if (!latest.isPending) {
        _poll?.cancel();
        setState(() => _stage = _Stage.done);
      }
    } on OrderApiException {
    }
  }

  Future<void> _cancel() async {
    final current = _order;
    if (current == null) return;
    _poll?.cancel();
    try {
      await _orders.cancelOrder(current.id);
    } on OrderApiException {
    }
    if (!mounted) return;
    setState(() {
      _order = null;
      _stage = _Stage.form;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _order),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.dark),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSummary(),
              const SizedBox(height: 20),
              if (_stage == _Stage.form || _stage == _Stage.creating) ..._buildForm(),
              if (_stage == _Stage.waiting) ..._buildWaiting(),
              if (_stage == _Stage.done) ..._buildResult(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lunch_dining_rounded, color: AppColors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_item.business.name} · ${_item.expiryLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Text(
            _item.priceLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildForm() {
    final busy = _stage == _Stage.creating;
    return [
      const Text(
        'Quantity',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: busy || _quantity <= 1 ? null : () => setState(() => _quantity--),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_quantity',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: busy || _quantity >= _maxQuantity ? null : () => setState(() => _quantity++),
          ),
          const SizedBox(width: 12),
          Text(
            '${_item.quantityLeft} left',
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
      const SizedBox(height: 22),
      if (_free)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'This is a free donation. No payment is needed. Reserve it and collect it before it expires.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.dark),
          ),
        )
      else ...[
        const Text(
          'Pay with',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.dark),
        ),
        const SizedBox(height: 10),
        for (final m in PaymentMethod.values) ...[
          _MethodTile(
            method: m,
            selected: _method == m,
            onTap: busy ? null : () => setState(() => _method = m),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            Text(
              'RM ${_total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(
          _error!,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFFB3261E)),
        ),
      ],
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: busy ? null : _pay,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Text(
                  _free ? 'Reserve for free' : 'Pay RM ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ),
      const SizedBox(height: 10),
      const Center(
        child: Text(
          'Payments are handled securely by Stripe. SapuHabis never sees your card or bank details.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10.5, height: 1.4, color: AppColors.textGrey),
        ),
      ),
    ];
  }

  List<Widget> _buildWaiting() {
    final order = _order!;
    final minutesLeft = order.holdExpiresAt.difference(DateTime.now()).inMinutes;
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.green),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for your payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dark),
            ),
            const SizedBox(height: 6),
            Text(
              'Finish paying in your browser, then come back here. '
              'Your item is held for ${minutesLeft < 1 ? 'less than a minute' : '$minutesLeft more minutes'}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textGrey),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB3261E))),
            ],
          ],
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton(
          onPressed: _openPaymentPage,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            side: const BorderSide(color: AppColors.green),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('Open payment page again',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton(
          onPressed: _cancel,
          child: const Text('Cancel order',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
        ),
      ),
    ];
  }

  List<Widget> _buildResult() {
    final order = _order!;
    if (order.isPaid) {
      final start = order.listing.pickupStart;
      final end = order.listing.pickupEnd;
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded, size: 44, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                order.isFree ? 'Reserved!' : 'Payment successful',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  order.pickupCode ?? '------',
                  style: const TextStyle(
                    fontSize: 30,
                    letterSpacing: 6,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Show this code at ${order.listing.businessName} to collect '
                '${order.quantity} × ${order.listing.title}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white70),
              ),
              if (start != null && end != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Pickup ${_time(start)} to ${_time(end)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _doneButton('Back to listings'),
      ];
    }

    final message = switch (order.status) {
      'failed' => 'The payment did not go through. You have not been charged.',
      'expired' => 'The payment window ran out and the item was released.',
      'cancelled' => 'This order was cancelled.',
      'refunded' => 'We could not complete this order, so your payment is being refunded. '
          'Bank refunds can take up to 14 days.',
      'refund_required' => 'We could not complete this order. Your payment will be refunded.',
      _ => 'Something went wrong with this order.',
    };
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline_rounded, size: 38, color: AppColors.textGrey),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.dark),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _doneButton('Back to listings'),
    ];
  }

  Widget _doneButton(String label) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, _order),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lime,
            foregroundColor: AppColors.dark,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );

  String _time(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.cream : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppColors.border : AppColors.dark,
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodTile({required this.method, required this.selected, required this.onTap});

  IconData get _icon {
    switch (method) {
      case PaymentMethod.fpx:
        return Icons.account_balance_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.grabpay:
        return Icons.account_balance_wallet_outlined;
      case PaymentMethod.any:
        return Icons.apps_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 24, color: AppColors.dark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.dark,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.green),
          ],
        ),
      ),
    );
  }
}
